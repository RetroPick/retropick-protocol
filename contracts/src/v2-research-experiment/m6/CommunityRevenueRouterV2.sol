// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {CommunityPolicyRegistryV2, ICommunityCheckpointV2} from "../CommunityPolicyRegistryV2.sol";
import {ICommunityFeeSourceV2} from "../interfaces/ICommunityFeesV2.sol";
import {IRetroPickFeeEscrowV2} from "../interfaces/IRetroPickLaunchpadV2.sol";
import {
    GraduationPacket,
    GraduationLedger,
    GraduationReceipt,
    GraduationState,
    GraduationVenue
} from "../interfaces/IGraduationExecutorV2.sol";
import {ExactAssetV2} from "../libraries/ExactAssetV2.sol";

interface IRevenueFactoryV2 {
    function communitySource(address token) external view returns (address);
    function communityBuilder() external view returns (address);
    function graduationCoordinator() external view returns (address);
    function locker() external view returns (address);
    function memeHook() external view returns (address);
}

interface IRevenueCurveTermsV2 {
    function feeBps() external view returns (uint256);
    function creatorTaxBps() external view returns (uint256);
    function protocolFeeShareBps() external view returns (uint256);
    function protocolFeeRecipient() external view returns (address);
    function feeEscrow() external view returns (IRetroPickFeeEscrowV2);
}

interface IRevenueCoordinatorV2 {
    function factory() external view returns (address);
    function packet(address token) external view returns (GraduationPacket memory);
    function ledger(address token) external view returns (GraduationLedger memory);
    function receipt(address token) external view returns (GraduationReceipt memory);
}

interface IRevenueLockerV2 {
    function positionManager() external view returns (address);
    function factory() external view returns (address);
    function graduationExecutor() external view returns (address);
    function lockedPositions(address token) external view returns (uint256);
    function isLocked(address token) external view returns (bool);
}

interface IRevenueHookV2 {
    function revenueHookVersion() external pure returns (uint256);
    function factory() external view returns (address);
    function poolManager() external view returns (address);
    function graduationExecutor() external view returns (address);
    function feeEscrow() external view returns (address);
}

interface IRevenueExecutorV2 {
    function coordinator() external view returns (address);
    function poolManager() external view returns (address);
    function positionManager() external view returns (address);
}

/// @notice EXPERIMENTAL: one launch, two in-kind assets, no owner or rescue authority.
/// @dev Curve funding is already community-only. Venue funding splits protocol entitlement exactly once.
contract CommunityRevenueRouterV2 is ReentrancyGuard, ICommunityCheckpointV2 {
    using SafeERC20 for IERC20;
    using PoolIdLibrary for PoolKey;

    ICommunityFeeSourceV2 public immutable source;
    address public immutable factory;
    address public immutable launchToken;
    address public immutable feeAsset;
    address public immutable registrar;
    address public immutable authority;
    address public immutable venueHook;
    bytes32 public immutable venueHookCodeHash;
    address public immutable poolManager;
    bytes32 public immutable poolManagerCodeHash;
    address public immutable coordinator;
    address public immutable venueExecutor;
    address public immutable locker;
    address public immutable positionManager;
    bytes32 public immutable venuePoolId;
    bytes32 public immutable packetHash;
    bytes32 public immutable venueTermsHash;
    uint256 public immutable venueHookFeeBps;
    uint256 public immutable creatorTaxBps;
    uint256 public immutable protocolFeeShareBps;
    address public immutable protocolFeeRecipient;
    IRetroPickFeeEscrowV2 public immutable feeEscrow;
    uint256 public immutable requiredTradeFeeBps;

    CommunityPolicyRegistryV2 public registry;
    bool public ready;
    bool private checkpointing;
    uint256 public sequence;
    mapping(address asset => uint256) public venueSequence;
    mapping(address asset => uint256) public funded;
    mapping(address asset => uint256) public paid;
    mapping(address asset => uint256) public liability;
    mapping(address asset => uint256) public venueGross;
    mapping(address asset => uint256) public venueProtocolRemitted;
    mapping(address asset => uint256) public venueCommunityFunded;
    mapping(address asset => mapping(address beneficiary => uint256)) private credits;
    mapping(address asset => mapping(uint256 epoch => uint256)) public epochFundedAsset;

    error Unauthorized();
    error InvalidBinding();
    error InvalidSettlement();
    error BackingDeficit();
    error TransferFailed();
    event Funded(uint256 indexed epoch, uint256 indexed sequence, uint256 amount);
    event VenueFunded(
        bytes32 indexed poolId,
        address indexed asset,
        uint256 indexed epoch,
        uint256 sequence,
        uint256 baseFee,
        uint256 tax,
        uint256 protocolAmount
    );
    event AllocatedAsset(address indexed asset, uint256 indexed epoch, address indexed beneficiary, uint256 amount);
    event ClaimedAsset(address indexed asset, address indexed beneficiary, address indexed recipient, uint256 amount);

    constructor(
        address factory_,
        ICommunityFeeSourceV2 source_,
        address token_,
        address authority_,
        address registrar_,
        address hook_
    ) {
        IRevenueFactoryV2 f = IRevenueFactoryV2(factory_);
        if (
            block.chainid != 10143 || factory_.code.length == 0 || address(source_).code.length == 0
                || token_.code.length == 0 || authority_.code.length == 0 || registrar_.code.length == 0
                || hook_.code.length == 0 || source_.factory() != factory_ || source_.token() != token_
                || f.communitySource(token_) != address(source_) || f.communityBuilder() != registrar_
                || f.memeHook() != hook_
        ) revert InvalidBinding();
        address quote = source_.pairToken();
        if (quote == token_ || (quote != address(0) && quote != 0x534b2f3A21130d7a60830c2Df862319e593943A3)) {
            revert InvalidBinding();
        }
        IRevenueHookV2 h = IRevenueHookV2(hook_);
        address coord = f.graduationCoordinator();
        address lock = f.locker();
        if (
            coord.code.length == 0 || lock.code.length == 0 || IRevenueCoordinatorV2(coord).factory() != factory_
                || h.revenueHookVersion() != 2 || h.factory() != factory_
        ) revert InvalidBinding();
        GraduationPacket memory p = IRevenueCoordinatorV2(coord).packet(token_);
        address manager = h.poolManager();
        address pm = IRevenueLockerV2(lock).positionManager();
        if (
            p.token != token_ || p.curve != address(source_) || p.quoteAsset != quote
                || p.quoteDecimals != (quote == address(0) ? 18 : 6) || p.venue != GraduationVenue.UNISWAP_V4
                || p.executor.code.length == 0 || p.executor.codehash != p.executorCodeHash || p.poolFee != 0
                || p.tickSpacing <= 0 || p.protectedLPReceiver != lock || p.protectedExcessReceiver != lock
                || manager.code.length == 0 || pm.code.length == 0
                || IRevenueExecutorV2(p.executor).coordinator() != coord
                || IRevenueExecutorV2(p.executor).poolManager() != manager
                || IRevenueExecutorV2(p.executor).positionManager() != pm || h.graduationExecutor() != p.executor
                || IRevenueLockerV2(lock).graduationExecutor() != p.executor
                || IRevenueLockerV2(lock).factory() != factory_
        ) {
            revert InvalidBinding();
        }
        IRevenueCurveTermsV2 terms = IRevenueCurveTermsV2(address(source_));
        uint256 tax = terms.creatorTaxBps();
        uint256 curveRate = terms.feeBps() + tax;
        uint256 venueRate = uint256(p.feePolicy.hookFeeBps) + tax;
        IRetroPickFeeEscrowV2 escrow = terms.feeEscrow();
        if (
            curveRate > 2000 || venueRate > 2000 || p.feePolicy.protocolFeeShareBps > 10000
                || p.feePolicy.protocolFeeRecipient == address(0) || address(escrow).code.length == 0
                || h.feeEscrow() != address(escrow) || terms.protocolFeeShareBps() != p.feePolicy.protocolFeeShareBps
                || terms.protocolFeeRecipient() != p.feePolicy.protocolFeeRecipient
        ) revert InvalidBinding();
        if (quote != address(0) && IERC20Metadata(quote).decimals() != 6) revert InvalidBinding();
        factory = factory_;
        source = source_;
        launchToken = token_;
        feeAsset = quote;
        registrar = registrar_;
        authority = authority_;
        venueHook = hook_;
        venueHookCodeHash = hook_.codehash;
        poolManager = manager;
        poolManagerCodeHash = manager.codehash;
        coordinator = coord;
        venueExecutor = p.executor;
        locker = lock;
        positionManager = pm;
        packetHash = keccak256(abi.encode(p));
        venueHookFeeBps = p.feePolicy.hookFeeBps;
        creatorTaxBps = tax;
        protocolFeeShareBps = p.feePolicy.protocolFeeShareBps;
        protocolFeeRecipient = p.feePolicy.protocolFeeRecipient;
        feeEscrow = escrow;
        requiredTradeFeeBps = Math.max(curveRate, venueRate);
        (address a, address b) = token_ < quote ? (token_, quote) : (quote, token_);
        PoolKey memory key = PoolKey(Currency.wrap(a), Currency.wrap(b), p.poolFee, p.tickSpacing, IHooks(hook_));
        venuePoolId = PoolId.unwrap(key.toId());
        venueTermsHash = keccak256(
            abi.encode(
                block.chainid,
                factory_,
                address(source_),
                token_,
                quote,
                hook_,
                hook_.codehash,
                manager,
                coord,
                p.executor,
                p.executorCodeHash,
                keccak256(abi.encode(p)),
                tax,
                address(escrow)
            )
        );
    }

    receive() external payable {} // Donations are surplus, never attributed trade revenue.

    function revenueRouterVersion() external pure returns (uint256) {
        return 2;
    }

    function bindRegistry(CommunityPolicyRegistryV2 r) external {
        if (
            msg.sender != registrar || ready || address(r).code.length == 0 || r.launchToken() != launchToken
                || address(r.source()) != address(this) || address(r.authority()) != authority
                || r.tradeFeeBps() != requiredTradeFeeBps || r.maxTradeFeeBps() < requiredTradeFeeBps
        ) {
            revert InvalidBinding();
        }
        registry = r;
        ready = true;
    }

    function activeEpoch() public view returns (uint256) {
        if (!ready) revert InvalidBinding();
        return registry.epoch();
    }

    function pending() external view returns (uint256) {
        if (checkpointing || _reentrancyGuardEntered()) return 1;
        return source.communityPending();
    }

    function checkpoint(uint256 oldEpoch) external {
        if (msg.sender != address(registry) || oldEpoch != activeEpoch()) revert Unauthorized();
        _checkpoint();
    }

    function settle() external {
        if (!ready) revert InvalidBinding();
        _checkpoint();
    }

    function _checkpoint() private {
        if (checkpointing || _reentrancyGuardEntered()) revert InvalidSettlement();
        checkpointing = true;
        source.checkpointCommunityFees(); // Curve must reenter fund() to settle genuine old-epoch value.
        if (source.communityPending() != 0) revert InvalidSettlement();
        checkpointing = false;
    }

    function fund(address token_, address asset_, uint256 epoch_, uint256 seq, uint256 amount)
        external
        payable
        nonReentrant
    {
        if (msg.sender != address(source)) revert Unauthorized();
        if (
            !ready || source.communityRouter() != address(this) || token_ != launchToken || asset_ != feeAsset
                || epoch_ != activeEpoch() || seq != sequence + 1 || amount == 0
        ) revert InvalidSettlement();
        _receiveExact(asset_, amount);
        sequence = seq;
        _allocate(asset_, epoch_, amount);
        emit Funded(epoch_, seq, amount);
    }

    function fundVenue(bytes32 poolId_, address asset, uint256 epoch_, uint256 seq, uint256 baseFee, uint256 tax)
        external
        payable
        nonReentrant
    {
        if (msg.sender != venueHook) revert Unauthorized();
        if (
            !ready || source.communityRouter() != address(this) || poolId_ != venuePoolId || !_supported(asset)
                || epoch_ != activeEpoch() || seq != venueSequence[asset] + 1 || baseFee + tax == 0
                || venueHook.codehash != venueHookCodeHash || poolManager.codehash != poolManagerCodeHash
        ) {
            revert InvalidSettlement();
        }
        _venueReady();
        uint256 gross = baseFee + tax;
        _receiveExact(asset, gross);
        uint256 protocolAmount = Math.mulDiv(baseFee, protocolFeeShareBps, 10000);
        _remitProtocol(asset, protocolAmount);
        uint256 community = gross - protocolAmount;
        venueSequence[asset] = seq;
        venueGross[asset] += gross;
        venueProtocolRemitted[asset] += protocolAmount;
        venueCommunityFunded[asset] += community;
        _allocate(asset, epoch_, community);
        emit VenueFunded(poolId_, asset, epoch_, seq, baseFee, tax, protocolAmount);
    }

    function _venueReady() private view {
        IRevenueCoordinatorV2 c = IRevenueCoordinatorV2(coordinator);
        GraduationLedger memory l = c.ledger(launchToken);
        GraduationReceipt memory r = c.receipt(launchToken);
        uint256 id = IRevenueLockerV2(locker).lockedPositions(launchToken);
        if (
            l.phase != GraduationState.GRADUATED || l.destinationIdentity != venuePoolId
                || l.receiptHash != keccak256(abi.encode(r))
                || keccak256(abi.encode(c.packet(launchToken))) != packetHash || r.packetHash != packetHash
                || r.destinationIdentity != venuePoolId || r.positionId != id || r.protectedLPReceiver != locker
                || l.protectedLPReceiver != locker || l.protectedLPAmount != r.protectedLPAmount
                || r.protectedLPAmount == 0 || !IRevenueLockerV2(locker).isLocked(launchToken)
                || IERC721(positionManager).ownerOf(id) != locker
                || IPositionManager(positionManager).getPositionLiquidity(id) != r.protectedLPAmount
        ) {
            revert InvalidSettlement();
        }
    }

    function _receiveExact(address asset, uint256 amount) private {
        if (asset == address(0)) {
            if (msg.value != amount) revert InvalidSettlement();
            if (address(this).balance - msg.value < liability[asset]) revert BackingDeficit();
        } else {
            if (msg.value != 0) revert InvalidSettlement();
            _backing(asset);
            ExactAssetV2.pull(asset, msg.sender, address(this), amount);
        }
    }

    function _remitProtocol(address asset, uint256 amount) private {
        if (amount == 0) return;
        uint256 ownBefore = ExactAssetV2.balance(asset, address(this));
        uint256 escrowBefore = ExactAssetV2.balance(asset, address(feeEscrow));
        uint256 creditBefore = asset == address(0)
            ? feeEscrow.balanceOf(protocolFeeRecipient)
            : feeEscrow.balanceOfToken(protocolFeeRecipient, asset);
        if (asset == address(0)) {
            feeEscrow.credit{value: amount}(protocolFeeRecipient);
        } else {
            IERC20(asset).forceApprove(address(feeEscrow), amount);
            feeEscrow.creditToken(protocolFeeRecipient, asset, amount);
            IERC20(asset).forceApprove(address(feeEscrow), 0);
            if (IERC20(asset).allowance(address(this), address(feeEscrow)) != 0) revert InvalidSettlement();
        }
        uint256 creditAfter = asset == address(0)
            ? feeEscrow.balanceOf(protocolFeeRecipient)
            : feeEscrow.balanceOfToken(protocolFeeRecipient, asset);
        if (
            ExactAssetV2.balance(asset, address(this)) != ownBefore - amount
                || ExactAssetV2.balance(asset, address(feeEscrow)) != escrowBefore + amount
                || creditAfter != creditBefore + amount
        ) {
            revert InvalidSettlement();
        }
    }

    function _allocate(address asset, uint256 epoch_, uint256 amount) private {
        if (epoch_ != activeEpoch()) revert InvalidSettlement();
        funded[asset] += amount;
        liability[asset] += amount;
        epochFundedAsset[asset][epoch_] += amount;
        CommunityPolicyRegistryV2.Allocation[] memory a = registry.policyAtVersion(epoch_);
        uint256 assigned;
        for (uint256 i; i < a.length; ++i) {
            uint256 share = Math.mulDiv(amount, a[i].bps, 10000);
            assigned += share;
            credits[asset][a[i].beneficiary] += share;
            emit AllocatedAsset(asset, epoch_, a[i].beneficiary, share);
        }
        uint256 dust = amount - assigned;
        if (dust != 0) {
            address treasury = registry.module(2);
            credits[asset][treasury] += dust;
            emit AllocatedAsset(asset, epoch_, treasury, dust);
        }
        _backing(asset);
    }

    function credit(address beneficiary) external view returns (uint256) {
        return credits[feeAsset][beneficiary];
    }

    function creditOf(address asset, address beneficiary) external view returns (uint256) {
        return credits[asset][beneficiary];
    }

    function totalFunded() external view returns (uint256) {
        return funded[feeAsset];
    }

    function totalPaid() external view returns (uint256) {
        return paid[feeAsset];
    }

    function totalLiability() external view returns (uint256) {
        return liability[feeAsset];
    }

    function epochFunded(uint256 epoch_) external view returns (uint256) {
        return epochFundedAsset[feeAsset][epoch_];
    }

    function claim(uint256 amount) external {
        _claim(feeAsset, msg.sender, amount);
    }

    function claimTo(address recipient, uint256 amount) external {
        _claim(feeAsset, recipient, amount);
    }

    function claimAsset(address asset, uint256 amount) external {
        _claim(asset, msg.sender, amount);
    }

    function claimAssetTo(address asset, address recipient, uint256 amount) external {
        _claim(asset, recipient, amount);
    }

    function _claim(address asset, address recipient, uint256 amount) private nonReentrant {
        if (
            !_supported(asset) || recipient == address(0) || recipient == address(this) || amount == 0
                || amount > credits[asset][msg.sender]
        ) revert InvalidSettlement();
        _backing(asset);
        uint256 beforeBalance = ExactAssetV2.balance(asset, address(this));
        credits[asset][msg.sender] -= amount;
        liability[asset] -= amount;
        paid[asset] += amount;
        if (asset == address(0)) {
            (bool ok,) = payable(recipient).call{value: amount}("");
            if (!ok) revert TransferFailed();
        } else {
            ExactAssetV2.send(asset, recipient, amount);
        }
        if (ExactAssetV2.balance(asset, address(this)) != beforeBalance - amount) revert InvalidSettlement();
        _backing(asset);
        emit ClaimedAsset(asset, msg.sender, recipient, amount);
    }

    function _supported(address asset) private view returns (bool) {
        return asset == feeAsset || asset == launchToken;
    }

    function _backing(address asset) private view {
        if (ExactAssetV2.balance(asset, address(this)) < liability[asset]) revert BackingDeficit();
    }
}

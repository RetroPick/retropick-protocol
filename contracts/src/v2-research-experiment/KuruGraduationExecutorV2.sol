// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {KuruEnvironmentV2} from "./KuruEnvironmentV2.sol";
import {KuruLiquidityLockV2} from "./KuruLiquidityLockV2.sol";
import {KuruParameterPolicyV2 as Policy} from "./libraries/KuruParameterPolicyV2.sol";
import {ExecutorDonationsV2, ExecutorDonationLockV2} from "./libraries/ExecutorDonationsV2.sol";
import {ExactAssetV2} from "./libraries/ExactAssetV2.sol";
import {IKuruRouterV2, IKuruOrderBookV2, IKuruVaultV2, IKuruMarketStateV2} from "./interfaces/IKuruV2.sol";
import {
    GraduationVenue,
    GraduationPacket,
    GraduationReceipt,
    IGraduationExecutorV2
} from "./interfaces/IGraduationExecutorV2.sol";

/// @notice Atomic Kuru venue worker. Coordinator alone holds lifecycle and secured balances.
contract KuruGraduationExecutorV2 is IGraduationExecutorV2, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public immutable coordinator;
    address public immutable donationLock;
    KuruEnvironmentV2 public immutable environment;
    bytes32 public immutable policyHash;
    error Unauthorized();
    error InvalidPacket();
    error InvalidMarket();
    error InvalidDeposit();
    error ResidualOrAllowance();

    constructor(address coordinator_, KuruEnvironmentV2 environment_) {
        if (coordinator_.code.length == 0 || address(environment_).code.length == 0) revert InvalidPacket();
        donationLock = address(new ExecutorDonationLockV2(address(this)));
        coordinator = coordinator_;
        environment = environment_;
        policyHash = keccak256(
            abi.encode(
                Policy.POLICY_HASH,
                environment_.ENVIRONMENT_HASH(),
                address(environment_),
                address(environment_).codehash
            )
        );
    }
    modifier onlyCoordinator() {
        if (msg.sender != coordinator) revert Unauthorized();
        _;
    }

    function validateLaunch(GraduationPacket calldata p, uint256 supply) external view {
        _validatePacket(p);
        Policy.validate(supply, p.quoteDecimals, p.phantomQuote, p.graduationThreshold, p.graduationQuoteCeiling);
        environment.validate();
        (address market, address vault) = _destination(p);
        if (
            market.code.length != 0 || vault.code.length != 0 || p.protectedLPReceiver != _lockAddress(p, market, vault)
        ) {
            revert InvalidMarket();
        }
    }

    function previewReceiver(GraduationPacket calldata p) external view returns (address) {
        environment.validate();
        (address market, address vault) = _destination(p);
        return _lockAddress(p, market, vault);
    }

    function execute(GraduationPacket calldata p, uint256 quoteAmount, uint256 tokenAmount)
        external
        payable
        onlyCoordinator
        nonReentrant
        returns (GraduationReceipt memory r)
    {
        _validatePacket(p);
        environment.validate();
        Policy.validate(
            IERC20(p.token).totalSupply(),
            p.quoteDecimals,
            p.phantomQuote,
            p.graduationThreshold,
            p.graduationQuoteCeiling
        );
        if (
            quoteAmount < p.graduationThreshold || quoteAmount > p.graduationQuoteCeiling || tokenAmount != 500 ether
                || msg.value != (p.quoteAsset == address(0) ? quoteAmount : 0)
        ) revert InvalidPacket();
        ExecutorDonationsV2.quarantine(p.token, p.quoteAsset, msg.value, donationLock);
        // No balance from an earlier launch can be included in this receipt.
        if (
            IERC20(p.token).balanceOf(address(this)) != 0
                || ExactAssetV2.balance(p.quoteAsset, address(this)) != msg.value
        ) revert ResidualOrAllowance();
        ExactAssetV2.pull(p.token, coordinator, address(this), tokenAmount);
        if (p.quoteAsset != address(0)) ExactAssetV2.pull(p.quoteAsset, coordinator, address(this), quoteAmount);
        uint256 baseSeed = Policy.seed(tokenAmount, quoteAmount, p.phantomQuote);
        (address market, address vault) = _deployMarket(p);
        address receiver = address(new KuruLiquidityLockV2{salt: _salt(p)}(p.token, p.quoteAsset, market, vault));
        if (receiver != p.protectedLPReceiver || receiver != p.protectedExcessReceiver) revert InvalidPacket();
        _verifyMarket(p, market, vault);
        uint256 shares = _deposit(p, market, vault, receiver, quoteAmount, baseSeed, tokenAmount);
        ExactAssetV2.send(p.token, receiver, tokenAmount - baseSeed);
        if (
            IERC20(p.token).balanceOf(address(this)) != 0 || ExactAssetV2.balance(p.quoteAsset, address(this)) != 0
                || IERC20(p.token).allowance(address(this), vault) != 0
                || (p.quoteAsset != address(0) && IERC20(p.quoteAsset).allowance(address(this), vault) != 0)
        ) {
            revert ResidualOrAllowance();
        }
        r.packetHash = keccak256(abi.encode(p));
        r.destinationIdentity = bytes32(uint256(uint160(market)));
        r.market = market;
        r.vault = vault;
        r.lpAsset = vault;
        r.seededQuote = quoteAmount;
        r.seededLaunchTokens = baseSeed;
        r.protectedLPReceiver = receiver;
        r.protectedLPAmount = shares;
        r.protectedExcessReceiver = receiver;
        r.protectedExcessAmount = tokenAmount - baseSeed;
    }

    function verifyReceipt(GraduationPacket calldata p, GraduationReceipt calldata r) external view {
        _validatePacket(p);
        environment.validate();
        (address market, address vault) = _destination(p);
        if (
            r.market != market || r.vault != vault || r.lpAsset != vault
                || r.destinationIdentity != bytes32(uint256(uint160(market))) || r.quoteResidual != 0
                || r.protectedLPReceiver != _lockAddress(p, market, vault)
        ) revert InvalidDeposit();
        KuruLiquidityLockV2 lock = KuruLiquidityLockV2(r.protectedLPReceiver);
        if (
            lock.launchToken() != p.token || lock.quoteToken() != p.quoteAsset || lock.market() != market
                || lock.vault() != vault || IERC20(vault).balanceOf(address(lock)) != r.protectedLPAmount
                || IERC20(p.token).balanceOf(address(lock)) != r.protectedExcessAmount
        ) revert InvalidDeposit();
        _verifyMarket(p, market, vault);
    }

    function _validatePacket(GraduationPacket calldata p) private view {
        if (
            p.venue != GraduationVenue.KURU || p.executor != address(this) || p.venuePolicyHash != policyHash
                || p.executorCodeHash != address(this).codehash || p.token == address(0)
        ) revert InvalidPacket();
    }

    function _destination(GraduationPacket calldata p) private view returns (address market, address vault) {
        IKuruRouterV2 router = IKuruRouterV2(environment.ROUTER());
        market = router.computeAddress(
            p.token,
            p.quoteAsset,
            Policy.SIZE_PRECISION,
            Policy.PRICE_PRECISION,
            Policy.TICK_SIZE,
            Policy.MIN_SIZE,
            Policy.MAX_SIZE,
            Policy.TAKER_FEE,
            Policy.MAKER_FEE,
            Policy.SPREAD,
            address(0),
            false
        );
        vault = router.computeVaultAddress(market, address(0), false);
    }

    function _deployMarket(GraduationPacket calldata p) private returns (address market, address vault) {
        (address expected, address expectedVault) = _destination(p);
        if (expected.code.length != 0 || expectedVault.code.length != 0) revert InvalidMarket();
        market = IKuruRouterV2(environment.ROUTER())
            .deployProxy(
                p.quoteAsset == address(0) ? 2 : 0,
                p.token,
                p.quoteAsset,
                Policy.SIZE_PRECISION,
                Policy.PRICE_PRECISION,
                Policy.TICK_SIZE,
                Policy.MIN_SIZE,
                Policy.MAX_SIZE,
                Policy.TAKER_FEE,
                Policy.MAKER_FEE,
                Policy.SPREAD
            );
        if (market != expected || market.code.length == 0 || expectedVault.code.length == 0) revert InvalidMarket();
        vault = expectedVault;
    }

    function _verifyMarket(GraduationPacket calldata p, address market, address vault) private view {
        if (IKuruMarketStateV2(market).marketState() != IKuruMarketStateV2.MarketState.ACTIVE) revert InvalidMarket();
        (bool ok, bytes memory data) = market.staticcall(abi.encodeWithSignature("getMarketParams()"));
        (bool registered, bytes memory routerData) =
            environment.ROUTER().staticcall(abi.encodeWithSignature("verifiedMarket(address)", market));
        if (
            !ok || !registered || keccak256(data) != keccak256(routerData)
                || keccak256(data)
                    != keccak256(
                        abi.encode(
                            Policy.PRICE_PRECISION,
                            Policy.SIZE_PRECISION,
                            p.token,
                            uint256(18),
                            p.quoteAsset,
                            uint256(p.quoteDecimals),
                            Policy.TICK_SIZE,
                            Policy.MIN_SIZE,
                            Policy.MAX_SIZE,
                            Policy.TAKER_FEE,
                            Policy.MAKER_FEE
                        )
                    )
        ) revert InvalidMarket();
        IKuruVaultV2 v = IKuruVaultV2(vault);
        if (
            v.token1() != p.token || v.token2() != p.quoteAsset || v.market() != market
                || v.marginAccount() != environment.MARGIN() || v.owner() != environment.ROUTER()
                || v.SPREAD_CONSTANT() != Policy.SPREAD
        ) revert InvalidMarket();
        (address reported,,,,,,, uint96 spread) = IKuruOrderBookV2(market).getVaultParams();
        if (reported != vault || spread != Policy.SPREAD) revert InvalidMarket();
    }

    function _deposit(
        GraduationPacket calldata p,
        address market,
        address vault,
        address receiver,
        uint256 quoteAmount,
        uint256 baseSeed,
        uint256 terminalTokens
    ) private returns (uint256 shares) {
        IKuruVaultV2 v = IKuruVaultV2(vault);
        (uint256 initialBase, uint256 initialQuote) = v.totalAssets();
        if (
            initialBase != 0 || initialQuote != 0 || v.balanceOf(receiver) != 0
                || IERC20(p.token).allowance(address(this), vault) != 0
        ) revert InvalidDeposit();
        uint256 marginBefore = ExactAssetV2.balance(p.quoteAsset, environment.MARGIN());
        uint256 marginBaseBefore = IERC20(p.token).balanceOf(environment.MARGIN());
        IERC20(p.token).forceApprove(vault, baseSeed);
        if (p.quoteAsset != address(0)) {
            if (IERC20(p.quoteAsset).allowance(address(this), vault) != 0) revert ResidualOrAllowance();
            IERC20(p.quoteAsset).forceApprove(vault, quoteAmount);
        }
        shares = v.deposit{value: p.quoteAsset == address(0) ? quoteAmount : 0}(
            baseSeed, quoteAmount, quoteAmount, receiver
        );
        IERC20(p.token).forceApprove(vault, 0);
        if (p.quoteAsset != address(0)) IERC20(p.quoteAsset).forceApprove(vault, 0);
        (uint256 actualBase, uint256 actualQuote) = v.totalAssets();
        if (
            shares != Math.sqrt(baseSeed * quoteAmount) - 1000 || v.balanceOf(receiver) != shares
                || actualBase != baseSeed || actualQuote != quoteAmount
                || IERC20(p.token).balanceOf(address(this)) != terminalTokens - baseSeed
                || IERC20(p.token).balanceOf(environment.MARGIN()) != marginBaseBefore + baseSeed
                || ExactAssetV2.balance(p.quoteAsset, address(this)) != 0
                || ExactAssetV2.balance(p.quoteAsset, environment.MARGIN()) != marginBefore + quoteAmount
        ) {
            revert InvalidDeposit();
        }
        _verifyOpening(p, market, vault, quoteAmount, baseSeed, terminalTokens);
    }

    function _verifyOpening(
        GraduationPacket calldata p,
        address market,
        address vault,
        uint256 quoteAmount,
        uint256 baseSeed,
        uint256 terminalTokens
    ) private view {
        (address reported, uint256 bid,, uint256 ask,, uint96 bidSize, uint96 askSize,) =
            IKuruOrderBookV2(market).getVaultParams();
        (uint256 expectedBid, uint256 expectedAsk, uint256 expectedBidSize, uint256 expectedAskSize) =
            Policy.opening(baseSeed, quoteAmount, p.quoteDecimals);
        uint256 referencePrice = Policy.referencePrice(terminalTokens, quoteAmount, p.phantomQuote, p.quoteDecimals);
        uint256 errorAmount = ask > referencePrice ? ask - referencePrice : referencePrice - ask;
        if (
            reported != vault || bid != expectedBid || ask != expectedAsk || bidSize != expectedBidSize
                || askSize != expectedAskSize || errorAmount * 10000 > referencePrice * Policy.SEED_TOLERANCE_BPS
        ) revert InvalidDeposit();
        uint256 askTick = ask * Policy.PRICE_PRECISION / 1 ether;
        uint256 bidTick = bid * Policy.PRICE_PRECISION / 1 ether;
        askTick -= askTick % Policy.TICK_SIZE;
        bidTick -= bidTick % Policy.TICK_SIZE;
        uint256 bidReference = (referencePrice * 10000 + (10000 + Policy.SPREAD) / 2) / (10000 + Policy.SPREAD);
        _tickTolerance(askTick, referencePrice);
        _tickTolerance(bidTick, bidReference);
        (uint256 bestBid, uint256 bestAsk) = IKuruOrderBookV2(market).bestBidAsk();
        if (bestBid != bid || bestAsk != ask) revert InvalidDeposit();
    }

    function _tickTolerance(uint256 tick, uint256 referencePrice) private pure {
        if (tick == 0 || tick > type(uint32).max) revert InvalidDeposit();
        uint256 represented = tick * 1 ether / Policy.PRICE_PRECISION;
        uint256 errorAmount = represented > referencePrice ? represented - referencePrice : referencePrice - represented;
        if (errorAmount * 10000 > referencePrice * Policy.SEED_TOLERANCE_BPS) revert InvalidDeposit();
    }

    function _salt(GraduationPacket calldata p) private pure returns (bytes32) {
        return keccak256(abi.encode(p.token, p.quoteAsset, p.venuePolicyHash));
    }

    function _lockAddress(GraduationPacket calldata p, address market, address vault) private view returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            _salt(p),
                            keccak256(
                                abi.encodePacked(
                                    type(KuruLiquidityLockV2).creationCode,
                                    abi.encode(p.token, p.quoteAsset, market, vault)
                                )
                            )
                        )
                    )
                )
            )
        );
    }
}

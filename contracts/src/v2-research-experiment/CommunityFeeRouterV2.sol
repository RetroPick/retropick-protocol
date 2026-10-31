// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ExactAssetV2} from "./libraries/ExactAssetV2.sol";
import {CommunityPolicyRegistryV2, ICommunityCheckpointV2} from "./CommunityPolicyRegistryV2.sol";
import {ICommunityFeeSourceV2} from "./interfaces/ICommunityFeesV2.sol";

interface ICommunityLaunchIdentityV2 {
    function communitySource(address token) external view returns (address);
}

/// @notice Per-launch final custody of pre-separated community fees. No owner or rescue path.
contract CommunityFeeRouterV2 is ReentrancyGuard, ICommunityCheckpointV2 {
    ICommunityFeeSourceV2 public immutable source;
    address public immutable factory;
    address public immutable launchToken;
    address public immutable feeAsset;
    address public immutable registrar;
    address public immutable authority;
    CommunityPolicyRegistryV2 public registry;
    bool public ready;
    uint256 public sequence;
    uint256 public totalFunded;
    uint256 public totalPaid;
    uint256 public totalLiability;
    mapping(address => uint256) public credit;
    mapping(uint256 => uint256) public epochFunded;
    error Unauthorized();
    error InvalidBinding();
    error InvalidSettlement();
    error BackingDeficit();
    error TransferFailed();
    event Funded(uint256 indexed epoch, uint256 indexed sequence, uint256 amount);
    event Allocated(uint256 indexed epoch, address indexed beneficiary, uint256 amount);
    event Claimed(address indexed beneficiary, address indexed recipient, uint256 amount);

    constructor(address factory_, ICommunityFeeSourceV2 source_, address token_, address authority_) {
        if (
            factory_.code.length == 0 || address(source_).code.length == 0 || authority_.code.length == 0
                || source_.factory() != factory_ || source_.token() != token_
                || ICommunityLaunchIdentityV2(factory_).communitySource(token_) != address(source_)
        ) revert InvalidBinding();
        address asset = source_.pairToken();
        if (block.chainid != 10143 || (asset != address(0) && asset != 0x534b2f3A21130d7a60830c2Df862319e593943A3)) {
            revert InvalidBinding();
        }
        factory = factory_;
        source = source_;
        launchToken = token_;
        feeAsset = asset;
        registrar = msg.sender;
        authority = authority_;
    }
    receive() external payable {} // Unattributed donations never create credit.

    function bindRegistry(CommunityPolicyRegistryV2 r) external {
        if (
            msg.sender != registrar || ready || r.launchToken() != launchToken || address(r.source()) != address(this)
                || address(r.authority()) != authority
        ) revert InvalidBinding();
        registry = r;
        ready = true;
    }

    function activeEpoch() public view returns (uint256) {
        if (!ready) revert InvalidBinding();
        return registry.epoch();
    }

    function pending() external view returns (uint256) {
        return source.communityPending();
    }

    function checkpoint(uint256 oldEpoch) external {
        if (msg.sender != address(registry) || oldEpoch != activeEpoch()) revert Unauthorized();
        // Do not hold router's deposit guard: source legitimately calls fund() during this checkpoint.
        source.checkpointCommunityFees();
        if (source.communityPending() != 0) revert InvalidSettlement();
    }

    function settle() external {
        if (!ready) revert InvalidBinding();
        source.checkpointCommunityFees();
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
        if (feeAsset == address(0)) {
            if (msg.value != amount) revert InvalidSettlement();
            if (address(this).balance - msg.value < totalLiability) revert BackingDeficit();
        } else {
            if (msg.value != 0) revert InvalidSettlement();
            _backing();
            ExactAssetV2.pull(feeAsset, msg.sender, address(this), amount);
        }
        sequence = seq;
        totalFunded += amount;
        totalLiability += amount;
        epochFunded[epoch_] += amount;
        CommunityPolicyRegistryV2.Allocation[] memory a = registry.policyAtVersion(epoch_);
        uint256 assigned;
        for (uint256 i; i < a.length; ++i) {
            uint256 share = Math.mulDiv(amount, a[i].bps, 10000);
            assigned += share;
            credit[a[i].beneficiary] += share;
            emit Allocated(epoch_, a[i].beneficiary, share);
        }
        uint256 dust = amount - assigned;
        if (dust != 0) {
            address treasury = registry.module(2);
            credit[treasury] += dust;
            emit Allocated(epoch_, treasury, dust);
        }
        _backing();
        emit Funded(epoch_, seq, amount);
    }

    function claim(uint256 amount) external {
        _claim(msg.sender, amount);
    }

    function claimTo(address recipient, uint256 amount) external {
        _claim(recipient, amount);
    }

    function _claim(address recipient, uint256 amount) private nonReentrant {
        if (recipient == address(0) || amount == 0 || amount > credit[msg.sender]) revert InvalidSettlement();
        _backing();
        credit[msg.sender] -= amount;
        totalLiability -= amount;
        totalPaid += amount;
        if (feeAsset == address(0)) {
            (bool ok,) = payable(recipient).call{value: amount}("");
            if (!ok) revert TransferFailed();
        } else {
            ExactAssetV2.send(feeAsset, recipient, amount);
        }
        _backing();
        emit Claimed(msg.sender, recipient, amount);
    }

    function _backing() private view {
        if (ExactAssetV2.balance(feeAsset, address(this)) < totalLiability) revert BackingDeficit();
    }
}

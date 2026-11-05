// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {CommunityRevenueRouterV2} from "./CommunityRevenueRouterV2.sol";
import {CommunityTimelockV2} from "../CommunityTimelockV2.sol";
import {RetroPickLauncherTokenV2} from "../RetroPickLauncherTokenV2.sol";
import {ExactAssetV2} from "../libraries/ExactAssetV2.sol";

interface IAssetTreasuryFactoryV2 {
    function communityBuilder() external view returns (address);
    function communitySource(address token) external view returns (address);
}

/// @notice Experimental two-asset earned-fee custody. No LP access, rescue or conversion.
contract CommunityAssetTreasuryVaultV2 is ReentrancyGuard {
    address public immutable factory;
    address public immutable launchToken;
    address public immutable feeAsset;
    address public immutable creator;
    uint256 public immutable deploymentChainId;
    CommunityRevenueRouterV2 public immutable router;
    CommunityTimelockV2 public immutable timelock;
    mapping(address => uint256) public claimedAsset;
    mapping(address => uint256) public spentAsset;
    mapping(bytes32 => bool) public spentIds;

    error InvalidBinding();
    error Unauthorized();
    error InvalidAmount();
    error BackingDeficit();
    error InexactReceipt();
    error TransferFailed();
    event TreasuryInitialized(address indexed token, address indexed router, address indexed timelock, address quote);
    event RevenueClaimed(address indexed asset, uint256 amount, uint256 cumulativeClaimed);
    event RevenueSpent(address indexed asset, address indexed recipient, bytes32 indexed spendId, uint256 amount);

    constructor(address factory_, CommunityRevenueRouterV2 router_, address creator_, CommunityTimelockV2 timelock_) {
        if (
            factory_.code.length == 0 || address(router_).code.length == 0 || address(timelock_).code.length == 0
                || block.chainid != 10143 || creator_ == address(0) || router_.factory() != factory_
                || router_.registrar() != IAssetTreasuryFactoryV2(factory_).communityBuilder() || router_.ready()
                || router_.totalFunded() != 0 || router_.sequence() != 0 || timelock_.getMinDelay() != 72 hours
        ) revert InvalidBinding();
        address token = router_.launchToken();
        RetroPickLauncherTokenV2 t = RetroPickLauncherTokenV2(token);
        if (
            IAssetTreasuryFactoryV2(factory_).communitySource(token) != address(router_.source())
                || router_.source().communityRouter() != address(0) || t.deployer() != creator_
                || t.launchFactory() != factory_ || t.curve() != address(router_.source())
        ) revert InvalidBinding();
        factory = factory_;
        launchToken = token;
        feeAsset = router_.feeAsset();
        creator = creator_;
        deploymentChainId = block.chainid;
        router = router_;
        timelock = timelock_;
        emit TreasuryInitialized(token, address(router_), address(timelock_), feeAsset);
    }

    receive() external payable {}

    function claimed() external view returns (uint256) {
        return claimedAsset[feeAsset];
    }

    function spent() external view returns (uint256) {
        return spentAsset[feeAsset];
    }

    function held() external view returns (uint256) {
        return heldAsset(feeAsset);
    }

    function actualBalance() external view returns (uint256) {
        return actualBalanceAsset(feeAsset);
    }

    function surplus() external view returns (uint256) {
        return surplusAsset(feeAsset);
    }

    function deficit() external view returns (uint256) {
        return deficitAsset(feeAsset);
    }

    function claimableRouterCredit() external view returns (uint256) {
        return router.creditOf(feeAsset, address(this));
    }

    function heldAsset(address asset) public view returns (uint256) {
        _supported(asset);
        return claimedAsset[asset] - spentAsset[asset];
    }

    function actualBalanceAsset(address asset) public view returns (uint256) {
        _supported(asset);
        return ExactAssetV2.balance(asset, address(this));
    }

    function surplusAsset(address asset) public view returns (uint256) {
        uint256 physical = actualBalanceAsset(asset);
        uint256 earned = heldAsset(asset);
        return physical > earned ? physical - earned : 0;
    }

    function deficitAsset(address asset) public view returns (uint256) {
        uint256 physical = actualBalanceAsset(asset);
        uint256 earned = heldAsset(asset);
        return earned > physical ? earned - physical : 0;
    }

    function claimFromRouter(uint256 amount) external {
        _claim(feeAsset, amount);
    }

    function claimAssetFromRouter(address asset, uint256 amount) external {
        _claim(asset, amount);
    }

    function _claim(address asset, uint256 amount) private nonReentrant {
        _sealed();
        _supported(asset);
        uint256 oldCredit = router.creditOf(asset, address(this));
        if (amount == 0 || amount > oldCredit) revert InvalidAmount();
        uint256 beforeBalance = _backing(asset);
        router.claimAssetTo(asset, address(this), amount);
        if (
            router.creditOf(asset, address(this)) != oldCredit - amount
                || actualBalanceAsset(asset) != beforeBalance + amount
        ) revert InexactReceipt();
        claimedAsset[asset] += amount;
        _backing(asset);
        emit RevenueClaimed(asset, amount, claimedAsset[asset]);
    }

    /// @notice Only an authorized, delayed call through the unchanged qualified timelock may spend earnings.
    function spend(address asset, address recipient, uint256 amount, bytes32 spendId) external nonReentrant {
        if (msg.sender != address(timelock)) revert Unauthorized();
        _sealed();
        _supported(asset);
        if (
            recipient == address(0) || recipient == address(this) || amount == 0 || amount > heldAsset(asset)
                || spendId == bytes32(0) || spentIds[spendId]
        ) revert InvalidAmount();
        uint256 beforeBalance = _backing(asset);
        spentIds[spendId] = true;
        spentAsset[asset] += amount;
        if (asset == address(0)) {
            (bool ok,) = payable(recipient).call{value: amount}("");
            if (!ok) revert TransferFailed();
        } else {
            ExactAssetV2.send(asset, recipient, amount);
        }
        if (actualBalanceAsset(asset) != beforeBalance - amount) revert InexactReceipt();
        _backing(asset);
        emit RevenueSpent(asset, recipient, spendId, amount);
    }

    function _supported(address asset) private view {
        if (asset != feeAsset && asset != launchToken) revert InvalidBinding();
    }

    function _sealed() private view {
        if (
            block.chainid != deploymentChainId || !router.ready() || router.registry().module(2) != address(this)
                || router.registry().launchToken() != launchToken
                || address(router.registry().source()) != address(router)
                || router.source().communityRouter() != address(router)
        ) revert InvalidBinding();
    }

    function _backing(address asset) private view returns (uint256 physical) {
        physical = actualBalanceAsset(asset);
        if (physical < heldAsset(asset)) revert BackingDeficit();
    }
}

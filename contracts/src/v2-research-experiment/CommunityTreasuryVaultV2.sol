// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {CommunityFeeRouterV2} from "./CommunityFeeRouterV2.sol";
import {CommunityTimelockV2} from "./CommunityTimelockV2.sol";
import {RetroPickLauncherTokenV2} from "./RetroPickLauncherTokenV2.sol";
import {ICommunityFeeSourceV2} from "./interfaces/ICommunityFeesV2.sol";
import {ExactAssetV2} from "./libraries/ExactAssetV2.sol";

interface ITreasuryFactoryIdentityV2 {
    function communityBuilder() external view returns (address);
    function communitySource(address token) external view returns (address);
}

/// @notice Experimental earned-fee custody. Surplus is quarantined; governance cannot rescue it.
/// @dev Constructed atomically before registry/curve sealing. No mutable initializer or owner exists.
contract CommunityTreasuryVaultV2 is ReentrancyGuard {
    address public immutable factory;
    address public immutable launchToken;
    address public immutable feeAsset;
    address public immutable creator;
    uint256 public immutable deploymentChainId;
    CommunityFeeRouterV2 public immutable router;
    CommunityTimelockV2 public immutable timelock;
    uint256 public claimed;
    uint256 public spent;
    mapping(bytes32 => bool) public spentIds;

    error InvalidBinding();
    error Unauthorized();
    error InvalidSpend();
    error InvalidClaim();
    error BackingDeficit();
    error InexactReceipt();
    error TransferFailed();

    event TreasuryInitialized(
        address indexed token, address indexed router, address indexed timelock, address feeAsset
    );
    event RevenueClaimed(address indexed router, uint256 amount, uint256 totalClaimed);
    event RevenueSpent(address indexed asset, address indexed recipient, bytes32 indexed spendId, uint256 amount);

    constructor(address factory_, CommunityFeeRouterV2 router_, address creator_, CommunityTimelockV2 timelock_) {
        if (
            factory_.code.length == 0 || address(router_).code.length == 0 || address(timelock_).code.length == 0
                || creator_ == address(0) || block.chainid != 10143 || router_.factory() != factory_
                || router_.registrar() != ITreasuryFactoryIdentityV2(factory_).communityBuilder() || router_.ready()
                || router_.totalFunded() != 0 || router_.sequence() != 0 || timelock_.getMinDelay() != 72 hours
        ) revert InvalidBinding();
        address token = router_.launchToken();
        ICommunityFeeSourceV2 source = router_.source();
        RetroPickLauncherTokenV2 t = RetroPickLauncherTokenV2(token);
        if (
            ITreasuryFactoryIdentityV2(factory_).communitySource(token) != address(source)
                || source.factory() != factory_ || source.token() != token || source.pairToken() != router_.feeAsset()
                || source.communityRouter() != address(0) || t.deployer() != creator_ || t.launchFactory() != factory_
                || t.curve() != address(source)
        ) revert InvalidBinding();
        factory = factory_;
        launchToken = token;
        feeAsset = router_.feeAsset();
        creator = creator_;
        deploymentChainId = block.chainid;
        router = router_;
        timelock = timelock_;
        emit TreasuryInitialized(token, address(router_), address(timelock_), router_.feeAsset());
    }

    receive() external payable {}

    function held() public view returns (uint256) {
        return claimed - spent;
    }

    function actualBalance() public view returns (uint256) {
        return ExactAssetV2.balance(feeAsset, address(this));
    }

    function surplus() external view returns (uint256) {
        uint256 balance = actualBalance();
        uint256 earned = held();
        return balance > earned ? balance - earned : 0;
    }

    function deficit() external view returns (uint256) {
        uint256 balance = actualBalance();
        uint256 earned = held();
        return earned > balance ? earned - balance : 0;
    }

    function claimableRouterCredit() external view returns (uint256) {
        return router.credit(address(this));
    }

    /// @notice Anyone can collect only this vault's credit, exclusively into this vault.
    function claimFromRouter(uint256 amount) external nonReentrant {
        _sealed();
        uint256 oldCredit = router.credit(address(this));
        if (amount == 0 || amount > oldCredit) revert InvalidClaim();
        uint256 beforeBalance = _backing();
        router.claimTo(address(this), amount);
        if (router.credit(address(this)) != oldCredit - amount || actualBalance() != beforeBalance + amount) {
            revert InexactReceipt();
        }
        claimed += amount;
        _backing();
        emit RevenueClaimed(address(router), amount, claimed);
    }

    /// @notice Invoke through the qualified timelock's existing schedule/execute APIs.
    function spend(address asset, address recipient, uint256 amount, bytes32 spendId) external nonReentrant {
        if (msg.sender != address(timelock)) revert Unauthorized();
        _sealed();
        if (
            asset != feeAsset || recipient == address(0) || recipient == address(this) || amount == 0 || amount > held()
                || spendId == bytes32(0) || spentIds[spendId]
        ) revert InvalidSpend();
        uint256 beforeBalance = _backing();
        spentIds[spendId] = true;
        spent += amount;
        if (asset == address(0)) {
            (bool ok,) = payable(recipient).call{value: amount}("");
            if (!ok) revert TransferFailed();
        } else {
            ExactAssetV2.send(asset, recipient, amount);
        }
        if (actualBalance() != beforeBalance - amount) revert InexactReceipt();
        _backing();
        emit RevenueSpent(asset, recipient, spendId, amount);
    }

    function _sealed() private view {
        if (
            block.chainid != deploymentChainId || !router.ready() || router.registry().module(2) != address(this)
                || router.registry().launchToken() != launchToken
                || address(router.registry().source()) != address(router)
                || router.source().communityRouter() != address(router)
        ) revert InvalidBinding();
    }

    function _backing() private view returns (uint256 balance) {
        balance = actualBalance();
        if (balance < held()) revert BackingDeficit();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CommunityLaunchBuilderV2 as Legacy} from "../CommunityLaunchBuilderV2.sol";
import {CommunityPolicyRegistryV2 as Registry} from "../CommunityPolicyRegistryV2.sol";
import {CommunityControllerV2} from "../CommunityControllerV2.sol";
import {RetroPickLauncherTokenV2} from "../RetroPickLauncherTokenV2.sol";
import {ICommunityBuilderV2} from "../interfaces/ICommunityFeesV2.sol";
import {CommunityRevenueRouterV2} from "./CommunityRevenueRouterV2.sol";
import {CommunityAssetTreasuryVaultV2} from "./CommunityAssetTreasuryVaultV2.sol";
import {CommunityRevenueDeployerV2, CommunityAssetTreasuryDeployerV2} from "./CommunityRevenueDeployersV2.sol";

interface IRevenueFactoryEnvironmentV2 {
    function communityBuilder() external view returns (address);
    function memeHook() external view returns (address);
    function graduationCoordinator() external view returns (address);
    function poolManager() external view returns (address);
    function positionManager() external view returns (address);
    function permit2() external view returns (address);
    function locker() external view returns (address);
    function feeEscrow() external view returns (address);
    function quoteRegistry() external view returns (address);
}

interface IRevenueCoordinatorEnvironmentV2 {
    function executors(uint8 venue) external view returns (address);
}

interface IRevenueCurveTermsV2 {
    function feeBps() external view returns (uint256);
    function creatorTaxBps() external view returns (uint256);
}

/// @notice Experimental versioned opt-in builder. Actual identities are created and sealed atomically.
contract CommunityRevenueLaunchBuilderV2 is ICommunityBuilderV2 {
    struct ConfigV2 {
        uint8 version;
        Legacy.Config community;
        address proposer;
        bytes32 expectedVenueTermsHash;
    }
    address public immutable factory;
    CommunityRevenueDeployerV2 public immutable revenueDeployer;
    CommunityAssetTreasuryDeployerV2 public immutable treasuryDeployer;
    bytes32 public immutable revenueDeployerCodeHash;
    bytes32 public immutable treasuryDeployerCodeHash;
    bytes32 public immutable venueEnvironmentHash;
    error InvalidLaunch();
    event RevenueCommunityCreated(
        address indexed token,
        address indexed router,
        address indexed treasury,
        address registry,
        address controller,
        bytes32 venueTermsHash
    );

    constructor(address factory_, CommunityRevenueDeployerV2 revenue_, CommunityAssetTreasuryDeployerV2 treasury_) {
        if (
            factory_.code.length == 0 || address(revenue_).code.length == 0 || address(treasury_).code.length == 0
                || revenue_.factory() != factory_ || treasury_.factory() != factory_
        ) revert InvalidLaunch();
        factory = factory_;
        revenueDeployer = revenue_;
        treasuryDeployer = treasury_;
        revenueDeployerCodeHash = address(revenue_).codehash;
        treasuryDeployerCodeHash = address(treasury_).codehash;
        venueEnvironmentHash = _environment(factory_);
    }

    function configure(address token, address curve, address creator, bytes calldata config, bytes32 commitment)
        external
        returns (address)
    {
        if (
            msg.sender != factory || IRevenueFactoryEnvironmentV2(factory).communityBuilder() != address(this)
                || address(revenueDeployer).codehash != revenueDeployerCodeHash
                || address(treasuryDeployer).codehash != treasuryDeployerCodeHash
                || _environment(factory) != venueEnvironmentHash || commitment == bytes32(0)
                || commitment != keccak256(abi.encode(address(this), address(this).codehash, config))
        ) revert InvalidLaunch();
        RetroPickLauncherTokenV2 t = RetroPickLauncherTokenV2(token);
        if (t.deployer() != creator || t.launchFactory() != factory || t.curve() != curve) revert InvalidLaunch();
        ConfigV2 memory v = abi.decode(config, (ConfigV2));
        Legacy.Config memory c = v.community;
        if (
            v.version != 2 || v.proposer == address(0) || c.modules[0] != address(0) || c.allocations.length == 0
                || c.allocations.length > 10
        ) revert InvalidLaunch();
        for (uint256 i = 1; i < 5; ++i) {
            if (c.modules[i] != address(0)) revert InvalidLaunch();
        }
        uint256 treasuryCount;
        for (uint256 i; i < c.allocations.length; ++i) {
            if (c.allocations[i].kind > 2) revert InvalidLaunch();
            if (c.allocations[i].kind == 2) {
                ++treasuryCount;
                if (c.allocations[i].beneficiary != address(0) || c.allocations[i].bps == 0) revert InvalidLaunch();
            }
        }
        if (treasuryCount != 1) revert InvalidLaunch();
        (CommunityRevenueRouterV2 router, CommunityControllerV2 control) = revenueDeployer.deployForLaunch(
            token, curve, c.controller, c.guardian, IRevenueFactoryEnvironmentV2(factory).memeHook()
        );
        // Optional per-launch terms pin supplements the mandatory environment and existing economics commitment.
        if (v.expectedVenueTermsHash != bytes32(0) && v.expectedVenueTermsHash != router.venueTermsHash()) {
            revert InvalidLaunch();
        }
        CommunityAssetTreasuryVaultV2 vault = treasuryDeployer.deployForLaunch(router, creator, v.proposer);
        if (address(vault).code.length == 0 || address(vault.router()) != address(router)) revert InvalidLaunch();
        c.modules[0] = address(vault);
        for (uint256 i; i < c.allocations.length; ++i) {
            if (c.allocations[i].kind == 2) c.allocations[i].beneficiary = address(vault);
        }
        uint256 curveFees = IRevenueCurveTermsV2(curve).feeBps() + IRevenueCurveTermsV2(curve).creatorTaxBps();
        uint256 venueFees = uint256(router.venueHookFeeBps()) + router.creatorTaxBps();
        uint256 maxFees = curveFees > venueFees ? curveFees : venueFees;
        if (maxFees > 2000) revert InvalidLaunch();
        Registry registry = new Registry(token, control, router, c.bounds, uint16(maxFees), c.modules, c.allocations);
        router.bindRegistry(registry);
        emit RevenueCommunityCreated(
            token, address(router), address(vault), address(registry), address(control), router.venueTermsHash()
        );
        return address(router);
    }

    function _environment(address f) private view returns (bytes32) {
        IRevenueFactoryEnvironmentV2 env = IRevenueFactoryEnvironmentV2(f);
        address hook = env.memeHook();
        address coordinator = env.graduationCoordinator();
        address executor = IRevenueCoordinatorEnvironmentV2(coordinator).executors(0);
        if (hook.code.length == 0 || coordinator.code.length == 0 || executor.code.length == 0) revert InvalidLaunch();
        return keccak256(
            abi.encode(
                block.chainid,
                f,
                hook,
                hook.codehash,
                coordinator,
                executor,
                executor.codehash,
                env.poolManager(),
                env.positionManager(),
                env.permit2(),
                env.locker(),
                env.feeEscrow(),
                env.quoteRegistry()
            )
        );
    }
}

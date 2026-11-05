// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {CommunityControllerV2} from "../CommunityControllerV2.sol";
import {CommunityTimelockV2} from "../CommunityTimelockV2.sol";
import {ICommunityFeeSourceV2} from "../interfaces/ICommunityFeesV2.sol";
import {CommunityRevenueRouterV2} from "./CommunityRevenueRouterV2.sol";
import {CommunityAssetTreasuryVaultV2, IAssetTreasuryFactoryV2} from "./CommunityAssetTreasuryVaultV2.sol";

interface IRevenueBuilderHelpersV2 {
    function revenueDeployer() external view returns (address);
    function treasuryDeployer() external view returns (address);
}

/// @notice Isolated creation code, not additional Factory runtime or a public initializer.
contract CommunityRevenueDeployerV2 is ReentrancyGuard {
    address public immutable factory;
    mapping(address => address) public routerForToken;
    error InvalidDeployment();
    event RevenueCreated(address indexed token, address indexed router, address indexed controller);

    constructor(address factory_) {
        if (factory_.code.length == 0) revert InvalidDeployment();
        factory = factory_;
    }

    function deployForLaunch(address token, address curve, address controller, address guardian, address hook)
        external
        nonReentrant
        returns (CommunityRevenueRouterV2 router, CommunityControllerV2 authority)
    {
        if (
            msg.sender != IAssetTreasuryFactoryV2(factory).communityBuilder()
                || IRevenueBuilderHelpersV2(msg.sender).revenueDeployer() != address(this)
                || IAssetTreasuryFactoryV2(factory).communitySource(token) != curve
                || routerForToken[token] != address(0)
        ) revert InvalidDeployment();
        authority = new CommunityControllerV2(controller, guardian);
        router = new CommunityRevenueRouterV2(
            factory, ICommunityFeeSourceV2(curve), token, address(authority), msg.sender, hook
        );
        routerForToken[token] = address(router);
        emit RevenueCreated(token, address(router), address(authority));
    }
}

/// @notice Each launch receives its actual distinct Vault before any entitlement can accrue.
contract CommunityAssetTreasuryDeployerV2 is ReentrancyGuard {
    address public immutable factory;
    mapping(address => address) public vaultForRouter;
    mapping(address => address) public vaultForToken;
    error InvalidDeployment();
    event TreasuryCreated(address indexed token, address indexed router, address indexed vault, address timelock);

    constructor(address factory_) {
        if (factory_.code.length == 0) revert InvalidDeployment();
        factory = factory_;
    }

    function deployForLaunch(CommunityRevenueRouterV2 router, address creator, address proposer)
        external
        nonReentrant
        returns (CommunityAssetTreasuryVaultV2 vault)
    {
        if (
            msg.sender != IAssetTreasuryFactoryV2(factory).communityBuilder()
                || IRevenueBuilderHelpersV2(msg.sender).treasuryDeployer() != address(this)
                || address(router).code.length == 0 || router.factory() != factory || router.registrar() != msg.sender
                || router.ready() || router.totalFunded() != 0 || router.sequence() != 0
                || vaultForRouter[address(router)] != address(0) || vaultForToken[router.launchToken()] != address(0)
        ) {
            revert InvalidDeployment();
        }
        CommunityTimelockV2 governance = new CommunityTimelockV2(proposer);
        vault = new CommunityAssetTreasuryVaultV2(factory, router, creator, governance);
        vaultForRouter[address(router)] = address(vault);
        vaultForToken[router.launchToken()] = address(vault);
        emit TreasuryCreated(router.launchToken(), address(router), address(vault), address(governance));
    }
}

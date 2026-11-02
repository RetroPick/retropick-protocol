// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {CommunityFeeRouterV2} from "./CommunityFeeRouterV2.sol";
import {CommunityTimelockV2} from "./CommunityTimelockV2.sol";
import {CommunityTreasuryVaultV2, ITreasuryFactoryIdentityV2} from "./CommunityTreasuryVaultV2.sol";
import {IAtomicTreasuryDeployerV2} from "./CommunityTreasuryLaunchBuilderV2.sol";

/// @notice Factory-builder-authorized atomic creation; never selects among already-funded launches.
contract CommunityTreasuryDeployerV2 is ReentrancyGuard, IAtomicTreasuryDeployerV2 {
    address public immutable factory;
    mapping(address => address) public vaultForRouter;
    mapping(address => address) public vaultForToken;
    error InvalidDeployment();
    event TreasuryCreated(address indexed token, address indexed router, address indexed vault, address timelock);

    constructor(address factory_) {
        if (factory_.code.length == 0) revert InvalidDeployment();
        factory = factory_;
    }

    function deployForLaunch(CommunityFeeRouterV2 router, address creator, address proposer)
        external
        nonReentrant
        returns (address vault)
    {
        if (
            msg.sender != ITreasuryFactoryIdentityV2(factory).communityBuilder() || address(router).code.length == 0
                || router.factory() != factory || router.registrar() != msg.sender || router.ready()
                || router.totalFunded() != 0 || router.sequence() != 0 || vaultForRouter[address(router)] != address(0)
                || vaultForToken[router.launchToken()] != address(0)
        ) revert InvalidDeployment();
        CommunityTimelockV2 governance = new CommunityTimelockV2(proposer);
        vault = address(new CommunityTreasuryVaultV2(factory, router, creator, governance));
        vaultForRouter[address(router)] = vault;
        vaultForToken[router.launchToken()] = vault;
        emit TreasuryCreated(router.launchToken(), address(router), vault, address(governance));
    }
}

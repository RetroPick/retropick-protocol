// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {CommunityLaunchBuilderV2 as Legacy} from "./CommunityLaunchBuilderV2.sol";
import {CommunityPolicyRegistryV2 as Registry} from "./CommunityPolicyRegistryV2.sol";
import {CommunityControllerV2} from "./CommunityControllerV2.sol";
import {CommunityFeeRouterV2} from "./CommunityFeeRouterV2.sol";
import {RetroPickLauncherTokenV2} from "./RetroPickLauncherTokenV2.sol";
import {ICommunityBuilderV2, ICommunityFeeSourceV2} from "./interfaces/ICommunityFeesV2.sol";

interface IAtomicTreasuryDeployerV2 {
    function factory() external view returns (address);
    function deployForLaunch(CommunityFeeRouterV2 router, address creator, address proposer) external returns (address);
}

interface IAtomicTreasuryBindingV2 {
    function router() external view returns (address);
}

interface ITreasuryCurveTermsV2 {
    function feeBps() external view returns (uint256);
    function creatorTaxBps() external view returns (uint256);
}

/// @notice Experimental atomic binding builder; deployer behavior requires independent qualification.
contract CommunityTreasuryLaunchBuilderV2 is ICommunityBuilderV2 {
    struct ConfigV1 {
        uint8 version;
        Legacy.Config community;
        address proposer;
    }
    address public immutable factory;
    IAtomicTreasuryDeployerV2 public immutable treasuryDeployer;
    bytes32 public immutable treasuryDeployerCodeHash;
    error InvalidLaunch();
    event TreasuryBound(address indexed token, address indexed router, address indexed treasury, address registry);

    constructor(address factory_, IAtomicTreasuryDeployerV2 deployer_) {
        if (factory_.code.length == 0 || address(deployer_).code.length == 0 || deployer_.factory() != factory_) {
            revert InvalidLaunch();
        }
        factory = factory_;
        treasuryDeployer = deployer_;
        treasuryDeployerCodeHash = address(deployer_).codehash;
    }

    function configure(address token, address curve, address creator, bytes calldata config, bytes32 commitment)
        external
        returns (address)
    {
        if (
            msg.sender != factory || address(treasuryDeployer).codehash != treasuryDeployerCodeHash
                || commitment == bytes32(0)
                || commitment != keccak256(abi.encode(address(this), address(this).codehash, config))
        ) revert InvalidLaunch();
        RetroPickLauncherTokenV2 t = RetroPickLauncherTokenV2(token);
        if (t.deployer() != creator || t.launchFactory() != factory || t.curve() != curve) revert InvalidLaunch();
        ConfigV1 memory v = abi.decode(config, (ConfigV1));
        Legacy.Config memory c = v.community;
        if (
            v.version != 1 || v.proposer == address(0) || c.modules[0] != address(0) || c.allocations.length == 0
                || c.allocations.length > 10
        ) revert InvalidLaunch();
        for (uint256 i = 1; i < 5; ++i) {
            if (c.modules[i] != address(0)) revert InvalidLaunch();
        }
        uint256 n;
        for (uint256 i; i < c.allocations.length; ++i) {
            if (c.allocations[i].kind > 2) revert InvalidLaunch();
            if (c.allocations[i].kind == 2) {
                ++n;
                if (c.allocations[i].beneficiary != address(0) || c.allocations[i].bps == 0) revert InvalidLaunch();
            }
        }
        if (n != 1) revert InvalidLaunch();
        CommunityControllerV2 control = new CommunityControllerV2(c.controller, c.guardian);
        CommunityFeeRouterV2 router =
            new CommunityFeeRouterV2(factory, ICommunityFeeSourceV2(curve), token, address(control));
        address vault = treasuryDeployer.deployForLaunch(router, creator, v.proposer);
        if (vault.code.length == 0 || IAtomicTreasuryBindingV2(vault).router() != address(router)) {
            revert InvalidLaunch();
        }
        c.modules[0] = vault;
        for (uint256 i; i < c.allocations.length; ++i) {
            if (c.allocations[i].kind == 2) c.allocations[i].beneficiary = vault;
        }
        uint256 fee = ITreasuryCurveTermsV2(curve).feeBps() + ITreasuryCurveTermsV2(curve).creatorTaxBps();
        if (fee > 2000) revert InvalidLaunch();
        Registry r = new Registry(token, control, router, c.bounds, uint16(fee), c.modules, c.allocations);
        router.bindRegistry(r);
        emit TreasuryBound(token, address(router), vault, address(r));
        return address(router);
    }
}

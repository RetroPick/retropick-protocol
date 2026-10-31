// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {CommunityPolicyRegistryV2 as Registry} from "./CommunityPolicyRegistryV2.sol";
import {CommunityControllerV2} from "./CommunityControllerV2.sol";
import {CommunityFeeRouterV2} from "./CommunityFeeRouterV2.sol";
import {ICommunityFeeSourceV2, ICommunityBuilderV2} from "./interfaces/ICommunityFeesV2.sol";

interface ICommunityCurveTermsV2 {
    function feeBps() external view returns (uint256);
    function creatorTaxBps() external view returns (uint256);
}

/// @notice Factory-only deployment helper; no arbitrary post-launch registrations.
contract CommunityLaunchBuilderV2 is ICommunityBuilderV2 {
    struct Config {
        address controller;
        address guardian;
        Registry.Bounds bounds;
        address[5] modules;
        Registry.Allocation[] allocations;
    }
    address public immutable factory;
    error Unauthorized();
    error InvalidCommitment();
    event CommunityCreated(address indexed token, address indexed router, address registry, address controller);

    constructor(address factory_) {
        if (factory_.code.length == 0) revert Unauthorized();
        factory = factory_;
    }

    function configure(address token, address curve, address, bytes calldata config, bytes32 commitment)
        external
        returns (address)
    {
        if (msg.sender != factory) revert Unauthorized();
        if (
            commitment == bytes32(0)
                || commitment != keccak256(abi.encode(address(this), address(this).codehash, config))
        ) {
            revert InvalidCommitment();
        }
        Config memory c = abi.decode(config, (Config));
        CommunityControllerV2 control = new CommunityControllerV2(c.controller, c.guardian);
        CommunityFeeRouterV2 router =
            new CommunityFeeRouterV2(factory, ICommunityFeeSourceV2(curve), token, address(control));
        uint256 fee = ICommunityCurveTermsV2(curve).feeBps() + ICommunityCurveTermsV2(curve).creatorTaxBps();
        if (fee > 2000) revert InvalidCommitment();
        Registry reg = new Registry(token, control, router, c.bounds, uint16(fee), c.modules, c.allocations);
        router.bindRegistry(reg);
        emit CommunityCreated(token, address(router), address(reg), address(control));
        return address(router);
    }
}

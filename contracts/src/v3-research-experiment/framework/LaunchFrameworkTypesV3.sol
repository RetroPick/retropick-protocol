// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SettlementKind} from "../VenueRegistryV3.sol";

/// @notice Shared protocol vocabulary. No imports of concrete venue implementations.
/// @dev Research framework: existing V2 launch/token/curve contracts are NOT wired here.
struct LaunchBlueprintV3 {
    address creator;
    address token;
    address quoteAsset;
    bytes32 venueId;
    uint32 venueVersion;
    bytes32 venueConfigHash;
    bytes32 economicsHash;
    bytes32 communityPolicyHash;
}

struct LaunchCommitmentV3 {
    bytes32 launchId;
    uint256 sourceChainId;
    address factory;
    address creator;
    address token;
    address quoteAsset;
    bytes32 venueId;
    uint32 venueVersion;
    address adapter;
    bytes32 adapterCodeHash;
    bytes32 venuePolicyHash;
    bytes32 quotePolicyHash;
    bytes32 venueConfigHash;
    bytes32 economicsHash;
    bytes32 communityPolicyHash;
    SettlementKind settlementKind;
}

/// @notice Atomic EVM graduation call parameters. Native routes use a DIFFERENT interface.
struct AtomicExecutionContextV3 {
    bytes32 launchId;
    address token;
    address quoteAsset;
    uint256 tokenAmount;
    uint256 quoteAmount;
    bytes32 venueConfigHash;
    bytes32 economicsHash;
    bytes32 venuePolicyHash;
}

struct AtomicGraduationReceiptV3 {
    bytes32 launchId;
    bytes32 destinationId;
    uint256 tokenSpent;
    uint256 quoteSpent;
    bytes32 settlementProof;
}

/// @notice Trusted, independently qualified adapter contract, not a delegatecall plugin.
/// @dev Actual destination verification belongs to the adapter and must be
///      specific to the concrete venue. The coordinator enforces custody deltas.
interface IAtomicVenueExecutorV3 {
    function coordinator() external view returns (address);
    function validate(LaunchCommitmentV3 calldata launch) external view;
    function execute(AtomicExecutionContextV3 calldata context)
        external
        returns (AtomicGraduationReceiptV3 memory receipt);
    function verify(AtomicExecutionContextV3 calldata context, AtomicGraduationReceiptV3 calldata receipt)
        external
        view
        returns (bool);
}

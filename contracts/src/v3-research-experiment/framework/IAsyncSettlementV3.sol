// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Interface-only boundary for future native HyperCore / cross-chain routes.
/// @dev DO NOT DEPLOY OR IMPLEMENT until proof semantics, funding authority,
///      cancellation, supply identity and recovery are accepted in a dedicated ADR.
///      These checkpoints are NOT sufficient evidence of HyperCore settlement.
enum AsyncRoutePhaseV3 {
    NONE,
    COMMITTED,
    FUNDED,
    NATIVE_SUBMITTED,
    NATIVE_VERIFIED,
    ACTIVE,
    EXCEPTION
}

struct AsyncRoutePlanV3 {
    bytes32 launchId;
    uint256 sourceChainId;
    bytes32 destinationDomain;
    bytes32 venueId;
    uint32 adapterVersion;
    bytes32 tokenIdentityHash;
    bytes32 supplyPlanHash;
    bytes32 fundingPlanHash;
    bytes32 nativeDeploymentPlanHash;
    bytes32 verifierPolicyHash;
}

struct AsyncSettlementCheckpointV3 {
    bytes32 launchId;
    bytes32 nativeActionId;
    bytes32 destinationIdentity;
    bytes32 evidenceHash;
    uint64 observationHeight;
    AsyncRoutePhaseV3 claimedPhase;
}

/// @notice A state query for observability, not a trusted proof of external state.
interface IAsyncRouteStateV3 {
    function plan(bytes32 launchId) external view returns (AsyncRoutePlanV3 memory);
    function phase(bytes32 launchId) external view returns (AsyncRoutePhaseV3);
    function checkpoint(bytes32 launchId) external view returns (AsyncSettlementCheckpointV3 memory);
}

/// @notice Independent verifier specification must bind *actual* HyperCore/bridge
///         state to each checkpoint; a generic relayer signature is not enough.
interface IAsyncSettlementVerifierV3 {
    function verify(
        AsyncRoutePlanV3 calldata route,
        AsyncSettlementCheckpointV3 calldata checkpoint_,
        bytes calldata objectiveEvidence
    ) external view returns (bool);
}

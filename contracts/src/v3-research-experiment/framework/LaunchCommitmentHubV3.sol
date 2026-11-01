// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VenueRegistryV3, SettlementKind} from "../VenueRegistryV3.sol";
import {QuoteVenuePolicyV3} from "./QuoteVenuePolicyV3.sol";
import {LaunchBlueprintV3, LaunchCommitmentV3, IAtomicVenueExecutorV3} from "./LaunchFrameworkTypesV3.sol";

/// @notice Venue-neutral launch-commitment kernel to be embedded or called by a
///         future verified V3 factory. Does not deploy tokens or curves.
/// @dev The authorized Factory must separately verify the real token/curve,
///      immutable supply economics, permissions, and the caller's launch intent.
///      This contract is research only; do NOT use it as an unrestricted issuer.
contract LaunchCommitmentHubV3 {
    address public immutable factory;
    VenueRegistryV3 public immutable venueRegistry;
    QuoteVenuePolicyV3 public immutable quotePolicy;
    uint256 public immutable deploymentChainId;
    uint256 public nextNonce;

    mapping(bytes32 launchId => LaunchCommitmentV3) private _commitments;
    mapping(address token => bytes32 launchId) public launchIdForToken;

    error OnlyFactory();
    error InvalidLaunch();
    error DuplicateToken();
    error WrongChain();

    event LaunchCommitted(
        bytes32 indexed launchId,
        address indexed token,
        bytes32 indexed venueId,
        uint32 venueVersion,
        address adapter,
        bytes32 commitmentHash
    );

    constructor(address factory_, VenueRegistryV3 registry_, QuoteVenuePolicyV3 quotePolicy_) {
        if (
            factory_ == address(0) || address(registry_).code.length == 0
                || address(quotePolicy_).code.length == 0
        ) revert InvalidLaunch();
        factory = factory_;
        venueRegistry = registry_;
        quotePolicy = quotePolicy_;
        deploymentChainId = block.chainid;
    }

    modifier onlyFactory() {
        if (msg.sender != factory) revert OnlyFactory();
        _;
    }

    function commitLaunch(LaunchBlueprintV3 calldata blueprint) external onlyFactory returns (bytes32 launchId) {
        if (block.chainid != deploymentChainId) revert WrongChain();
        if (
            blueprint.creator == address(0) || blueprint.token.code.length == 0
                || blueprint.quoteAsset == address(0) || blueprint.token == blueprint.quoteAsset
                || blueprint.venueConfigHash == bytes32(0) || blueprint.economicsHash == bytes32(0)
        ) revert InvalidLaunch();
        if (launchIdForToken[blueprint.token] != bytes32(0)) revert DuplicateToken();

        VenueRegistryV3.VenueConfig memory cfg = venueRegistry.resolve(blueprint.venueId, blueprint.venueVersion);
        QuoteVenuePolicyV3.QuoteRule memory quoteRule =
            quotePolicy.resolve(blueprint.venueId, blueprint.venueVersion, blueprint.quoteAsset);

        uint256 nonce = ++nextNonce;
        launchId = keccak256(
            abi.encode("RETROPICK_V3_LAUNCH", deploymentChainId, factory, address(this), nonce, blueprint.token)
        );

        LaunchCommitmentV3 memory commitment = LaunchCommitmentV3({
            launchId: launchId,
            sourceChainId: deploymentChainId,
            factory: factory,
            creator: blueprint.creator,
            token: blueprint.token,
            quoteAsset: blueprint.quoteAsset,
            venueId: blueprint.venueId,
            venueVersion: blueprint.venueVersion,
            adapter: cfg.adapter,
            adapterCodeHash: cfg.adapterCodeHash,
            venuePolicyHash: cfg.policyHash,
            quotePolicyHash: quoteRule.policyHash,
            venueConfigHash: blueprint.venueConfigHash,
            economicsHash: blueprint.economicsHash,
            communityPolicyHash: blueprint.communityPolicyHash,
            settlementKind: cfg.settlementKind
        });

        // Only atomic EVM venue adapters can validate at launch using the
        // atomic interface. Native/bridge routes need a separately qualified
        // preflight workflow, not an optimistic onchain check here.
        if (cfg.settlementKind == SettlementKind.ATOMIC_EVM) {
            IAtomicVenueExecutorV3(cfg.adapter).validate(commitment);
        }

        _commitments[launchId] = commitment;
        launchIdForToken[blueprint.token] = launchId;
        emit LaunchCommitted(
            launchId, blueprint.token, blueprint.venueId, blueprint.venueVersion, cfg.adapter,
            keccak256(abi.encode(commitment))
        );
    }

    function commitment(bytes32 launchId) external view returns (LaunchCommitmentV3 memory) {
        return _commitments[launchId];
    }

    function commitmentHash(bytes32 launchId) external view returns (bytes32) {
        if (_commitments[launchId].launchId == bytes32(0)) revert InvalidLaunch();
        return keccak256(abi.encode(_commitments[launchId]));
    }
}

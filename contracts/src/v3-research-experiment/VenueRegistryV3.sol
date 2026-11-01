// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @notice A venue's settlement mechanism; never conflate native-system activation
///         or cross-chain settlement with a synchronous EVM executor.
enum SettlementKind {
    ATOMIC_EVM,
    NATIVE_ASYNC,
    CROSS_CHAIN_ASYNC
}

/// @notice EXPERIMENTAL: admission directory only; does not custody assets or execute graduation.
/// @dev Existing launch commitments must SNAPSHOT the returned adapter address, code hash,
///      policy hash, settlement kind and version. Do not re-resolve mutable admission
///      when executing a previously committed launch.
contract VenueRegistryV3 is Ownable2Step {
    struct VenueConfig {
        address adapter;
        bytes32 adapterCodeHash;
        bytes32 policyHash;
        SettlementKind settlementKind;
        bool enabled;
    }

    uint256 public immutable deploymentChainId;
    mapping(bytes32 venueId => mapping(uint32 version => VenueConfig)) private _venues;

    error InvalidVenue();
    error VenueAlreadyRegistered();
    error VenueNotAdmitted();
    error WrongChain();
    error AdapterCodeChanged();

    event VenueRegistered(
        bytes32 indexed venueId,
        uint32 indexed version,
        address indexed adapter,
        bytes32 adapterCodeHash,
        bytes32 policyHash,
        SettlementKind settlementKind
    );
    event VenueDisabled(bytes32 indexed venueId, uint32 indexed version);

    constructor(address initialOwner) Ownable(initialOwner) {
        deploymentChainId = block.chainid;
    }

    /// @notice Register a new version; records are not overwritten or silently re-enabled.
    /// @dev Governance must independently qualify adapter behavior, provenance and
    ///      permissions BEFORE registering it. A code hash alone is not a security audit.
    function register(
        bytes32 venueId,
        uint32 version,
        address adapter,
        bytes32 policyHash,
        SettlementKind settlementKind
    ) external onlyOwner {
        if (block.chainid != deploymentChainId) revert WrongChain();
        if (venueId == bytes32(0) || version == 0 || adapter.code.length == 0 || policyHash == bytes32(0)) {
            revert InvalidVenue();
        }
        if (_venues[venueId][version].adapter != address(0)) revert VenueAlreadyRegistered();

        bytes32 codeHash = adapter.codehash;
        _venues[venueId][version] = VenueConfig({
            adapter: adapter,
            adapterCodeHash: codeHash,
            policyHash: policyHash,
            settlementKind: settlementKind,
            enabled: true
        });
        emit VenueRegistered(venueId, version, adapter, codeHash, policyHash, settlementKind);
    }

    /// @notice Prevent NEW launch commitments from using an adapter version.
    /// @dev Must NOT mutate previously snapshotted launch terms. An active-launch
    ///      emergency stop requires a separate, explicitly governed policy.
    function disable(bytes32 venueId, uint32 version) external onlyOwner {
        if (block.chainid != deploymentChainId) revert WrongChain();
        VenueConfig storage cfg = _venues[venueId][version];
        if (cfg.adapter == address(0) || !cfg.enabled) revert VenueNotAdmitted();
        cfg.enabled = false;
        emit VenueDisabled(venueId, version);
    }

    /// @notice Admission view for NEW launches only, not a settlement oracle.
    function resolve(bytes32 venueId, uint32 version) external view returns (VenueConfig memory cfg) {
        if (block.chainid != deploymentChainId) revert WrongChain();
        cfg = _venues[venueId][version];
        if (!cfg.enabled || cfg.adapter == address(0)) revert VenueNotAdmitted();
        if (cfg.adapter.codehash != cfg.adapterCodeHash) revert AdapterCodeChanged();
    }

    /// @notice Historical lookup, including disabled versions, for audit/reconciliation.
    function get(bytes32 venueId, uint32 version) external view returns (VenueConfig memory) {
        return _venues[venueId][version];
    }
}

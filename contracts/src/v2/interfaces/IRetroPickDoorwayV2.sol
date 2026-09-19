// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @notice Shared RetroPick Doorway V2 interfaces.
 *
 * The Doorway is the cross-chain liquidity migration layer of the RetroPick
 * ecosystem, coordinating migrations between:
 *
 *      Solana <-> RetroPick Doorway <-> Monad Chain
 *
 * `IRetroPickDoorwayV2` describes the external surface of the primary
 * orchestrator (`RetroPickDoorwayV2`). The remaining interfaces are narrow
 * scaffolding contracts for the modular components hinted at in the Doorway
 * architecture (registry, vault, relayer staking). They are declared here so
 * that future modules and their consumers share a single, stable ABI without
 * re-declaring these types.
 */

/**
 * @notice Direction of a cross-chain liquidity migration.
 */
enum MigrationDirection {
    SOLANA_TO_MONAD,
    MONAD_TO_SOLANA
}

/**
 * @notice Explicit lifecycle state of a migration.
 */
enum MigrationStatus {
    NONE,
    REQUESTED,
    ATTESTED,
    EXECUTING,
    COMPLETED,
    CANCELLED,
    FAILED
}

/**
 * @notice Full migration record tracked by the Doorway.
 */
struct Migration {
    bytes32 id;
    MigrationDirection direction;
    MigrationStatus status;
    address initiator;
    address monadToken;
    bytes32 solanaMint;
    bytes32 destination;
    uint256 amount;
    uint256 minAmountOut;
    uint256 nonce;
    uint256 createdAt;
    uint256 completedAt;
    bytes32 sourceTxHash;
    bytes32 destinationTxHash;
    uint256 fee;
}

/**
 * @notice Guardian attestation payload asserting a source-side event occurred.
 */
struct Attestation {
    bytes32 migrationId;
    bytes32 sourceTxHash;
    uint256 amount;
    uint256 timestamp;
    uint256 nonce;
}

/**
 * @notice External surface of the RetroPick Doorway migration orchestrator.
 */
interface IRetroPickDoorwayV2 {
    event MigrationRequested(
        bytes32 indexed migrationId,
        MigrationDirection indexed direction,
        address indexed initiator,
        address monadToken,
        bytes32 solanaMint,
        bytes32 destination,
        uint256 amount,
        uint256 fee,
        uint256 nonce
    );

    event MigrationAttested(
        bytes32 indexed migrationId, bytes32 indexed sourceTxHash, uint256 amount, uint256 timestamp
    );

    event MigrationExecutionStarted(bytes32 indexed migrationId);

    event MigrationCompleted(bytes32 indexed migrationId, bytes32 indexed destinationTxHash, uint256 amount);

    event MigrationCancelled(bytes32 indexed migrationId);

    event TokenSupportUpdated(address indexed token, bool supported);

    event SolanaMintSupportUpdated(bytes32 indexed mint, bool supported);

    event RelayerUpdated(address indexed oldRelayer, address indexed newRelayer);

    event GuardianUpdated(address indexed oldGuardian, address indexed newGuardian);

    event FeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function migrateToSolana(
        address token,
        bytes32 solanaMint,
        bytes32 solanaRecipient,
        uint256 amount,
        uint256 minAmountOut
    ) external returns (bytes32 migrationId);

    function requestFromSolana(
        bytes32 solanaMint,
        bytes32 solanaSender,
        address monadToken,
        address monadRecipient,
        uint256 amount,
        uint256 sourceNonce,
        bytes32 sourceTxHash
    ) external returns (bytes32 migrationId);

    function attestMigration(Attestation calldata attestation) external;

    function executeMigration(bytes32 migrationId, bytes32 destinationTxHash) external;

    function cancelMigration(bytes32 migrationId) external;

    function getMigration(bytes32 migrationId) external view returns (Migration memory);

    function migrationExists(bytes32 migrationId) external view returns (bool);

    function calculateFee(uint256 amount) external view returns (uint256);

    function calculateNetAmount(uint256 amount) external view returns (uint256);
}

/**
 * @notice Registry of assets eligible for migration. A production Doorway can
 * back this with richer metadata (decimals, migration limits, adapters); the
 * reference orchestrator inlines a minimal boolean registry instead.
 */
interface IRetroPickDoorwayRegistryV2 {
    function setMonadToken(address token, bool enabled) external;
    function setSolanaMint(bytes32 mint, bool enabled) external;
    function isMonadTokenSupported(address token) external view returns (bool);
    function isSolanaMintSupported(bytes32 mint) external view returns (bool);
}

/**
 * @notice Liquidity accounting / custody layer. The Doorway treats liquidity
 * separately from the migration request itself so a migration is more than a
 * simple token transfer.
 */
interface IRetroPickDoorwayVaultV2 {
    function tokenLiquidity(address token) external view returns (uint256);
    function solanaLiquidity(bytes32 mint) external view returns (uint256);
    function pendingFees(address token) external view returns (uint256);
}

/**
 * @notice Relayer security-bond module. Relayers stake the Doorway's native
 * security asset; misbehaviour is punished by slashing part of the bond.
 */
interface IRetroPickDoorwayStakingV2 {
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function slash(address relayer, uint256 amount, bytes32 migrationId) external;
    function bondedBalance(address relayer) external view returns (uint256);
}

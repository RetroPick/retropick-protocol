// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {
    IRetroPickDoorwayV1,
    IRetroPickDoorwayRegistryV1,
    IRetroPickDoorwayVaultV1,
    MigrationDirection,
    MigrationStatus,
    Migration,
    Attestation
} from "./interfaces/IRetroPickDoorwayV1.sol";

/**
 * @title RetroPickDoorwayV1
 * @notice Cross-chain liquidity migration doorway between Monad Chain and Solana.
 *
 * @dev
 * This contract is an architectural reference implementation for the RetroPick
 * Doorway. It models the lifecycle of liquidity migration requests between:
 *
 *      Solana <-> RetroPick Doorway <-> Monad Chain
 *
 * The actual Solana settlement layer is represented by an off-chain relayer /
 * attestation network. This contract is intentionally simplified and is not
 * intended to hold production funds without a complete bridge security model.
 *
 * RetroPick Doorway is designed around the same modular philosophy used
 * throughout the RetroPick V1 architecture:
 *
 *  - explicit lifecycle state
 *  - permissioned settlement only at the execution boundary
 *  - nonce-based replay protection
 *  - guardian attestations
 *  - delayed cancellation
 *  - isolated vault accounting
 *  - deterministic migration identifiers
 *
 * Known reference-implementation limitations (documented, not fixed in this
 * baseline; see docs/rebrand/SECURITY_ANALYSIS.md):
 *  - migrateToSolana / requestFromSolana perform pure liquidity accounting and
 *    do NOT pull ERC-20 tokens via transferFrom.
 *  - attestMigration keys replay protection on sourceTxHash; MONAD_TO_SOLANA
 *    migrations use sourceTxHash == bytes32(0), so only the first such migration
 *    can ever be attested (the zero-hash slot latches).
 *  - ATTESTATION_DELAY is declared but currently unused.
 */
contract RetroPickDoorwayV1 is IRetroPickDoorwayV1, IRetroPickDoorwayRegistryV1, IRetroPickDoorwayVaultV1 {
    // =============================================================
    //                         CONFIGURATION
    // =============================================================

    uint256 public constant MAX_FEE_BPS = 100; // 1%

    uint256 public constant ATTESTATION_DELAY = 3 minutes;

    uint256 public constant CANCELLATION_DELAY = 30 minutes;

    address public owner;

    address public treasury;

    address public relayer;

    address public guardian;

    uint256 public migrationNonce;

    uint256 public migrationFeeBps = 25; // 0.25%

    bool public doorwayActive = true;

    // =============================================================
    //                            STORAGE
    // =============================================================

    mapping(bytes32 => Migration) public migrations;

    mapping(bytes32 => bool) public usedSourceTransactions;

    mapping(bytes32 => bool) public processedAttestations;

    mapping(address => bool) public supportedMonadTokens;

    mapping(bytes32 => bool) public supportedSolanaMints;

    mapping(address => uint256) public pendingFees;

    mapping(address => uint256) public tokenLiquidity;

    mapping(bytes32 => uint256) public solanaLiquidity;

    // =============================================================
    //                           MODIFIERS
    // =============================================================

    modifier onlyOwner() {
        require(msg.sender == owner, "RetroPickDoorwayV1: not owner");
        _;
    }

    modifier onlyRelayer() {
        require(msg.sender == relayer, "RetroPickDoorwayV1: not relayer");
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == guardian, "RetroPickDoorwayV1: not guardian");
        _;
    }

    modifier doorwayOpen() {
        require(doorwayActive, "RetroPickDoorwayV1: paused");
        _;
    }

    // =============================================================
    //                         CONSTRUCTOR
    // =============================================================

    constructor(address _treasury, address _relayer, address _guardian) {
        require(_treasury != address(0), "RetroPickDoorwayV1: zero treasury");
        require(_relayer != address(0), "RetroPickDoorwayV1: zero relayer");
        require(_guardian != address(0), "RetroPickDoorwayV1: zero guardian");

        owner = msg.sender;

        treasury = _treasury;
        relayer = _relayer;
        guardian = _guardian;
    }

    // =============================================================
    //                    MONAD -> SOLANA
    // =============================================================

    /**
     * @notice Locks Monad-side liquidity and creates a Solana migration.
     *
     * The doorway records the Monad token and the destination Solana mint.
     * A remote relayer observes the emitted event and prepares the Solana-side
     * settlement.
     */
    function migrateToSolana(
        address token,
        bytes32 solanaMint,
        bytes32 solanaRecipient,
        uint256 amount,
        uint256 minAmountOut
    ) external doorwayOpen returns (bytes32 migrationId) {
        require(supportedMonadTokens[token], "RetroPickDoorwayV1: token unsupported");

        require(supportedSolanaMints[solanaMint], "RetroPickDoorwayV1: mint unsupported");

        require(amount > 0, "RetroPickDoorwayV1: zero amount");

        uint256 fee = (amount * migrationFeeBps) / 10_000;
        uint256 netAmount = amount - fee;

        migrationNonce++;

        migrationId = keccak256(
            abi.encodePacked(
                block.chainid, address(this), msg.sender, token, solanaMint, solanaRecipient, amount, migrationNonce
            )
        );

        migrations[migrationId] = Migration({
            id: migrationId,
            direction: MigrationDirection.MONAD_TO_SOLANA,
            status: MigrationStatus.REQUESTED,
            initiator: msg.sender,
            monadToken: token,
            solanaMint: solanaMint,
            destination: solanaRecipient,
            amount: netAmount,
            minAmountOut: minAmountOut,
            nonce: migrationNonce,
            createdAt: block.timestamp,
            completedAt: 0,
            sourceTxHash: bytes32(0),
            destinationTxHash: bytes32(0),
            fee: fee
        });

        pendingFees[token] += fee;
        tokenLiquidity[token] += netAmount;

        emit MigrationRequested(
            migrationId,
            MigrationDirection.MONAD_TO_SOLANA,
            msg.sender,
            token,
            solanaMint,
            solanaRecipient,
            netAmount,
            fee,
            migrationNonce
        );
    }

    // =============================================================
    //                    SOLANA -> MONAD
    // =============================================================

    /**
     * @notice Creates a migration request originating from Solana.
     *
     * In production, the relayer would only call this after observing and
     * validating the Solana source transaction.
     */
    function requestFromSolana(
        bytes32 solanaMint,
        bytes32 solanaSender,
        address monadToken,
        address monadRecipient,
        uint256 amount,
        uint256 sourceNonce,
        bytes32 sourceTxHash
    ) external onlyRelayer doorwayOpen returns (bytes32 migrationId) {
        require(supportedSolanaMints[solanaMint], "RetroPickDoorwayV1: mint unsupported");

        require(supportedMonadTokens[monadToken], "RetroPickDoorwayV1: token unsupported");

        require(!usedSourceTransactions[sourceTxHash], "RetroPickDoorwayV1: source tx used");

        require(amount > 0, "RetroPickDoorwayV1: zero amount");

        usedSourceTransactions[sourceTxHash] = true;

        uint256 fee = (amount * migrationFeeBps) / 10_000;
        uint256 netAmount = amount - fee;

        migrationNonce++;

        migrationId = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                solanaMint,
                solanaSender,
                monadRecipient,
                sourceTxHash,
                sourceNonce,
                migrationNonce
            )
        );

        migrations[migrationId] = Migration({
            id: migrationId,
            direction: MigrationDirection.SOLANA_TO_MONAD,
            status: MigrationStatus.REQUESTED,
            initiator: monadRecipient,
            monadToken: monadToken,
            solanaMint: solanaMint,
            destination: bytes32(uint256(uint160(monadRecipient))),
            amount: netAmount,
            minAmountOut: netAmount,
            nonce: migrationNonce,
            createdAt: block.timestamp,
            completedAt: 0,
            sourceTxHash: sourceTxHash,
            destinationTxHash: bytes32(0),
            fee: fee
        });

        pendingFees[monadToken] += fee;

        emit MigrationRequested(
            migrationId,
            MigrationDirection.SOLANA_TO_MONAD,
            monadRecipient,
            monadToken,
            solanaMint,
            bytes32(uint256(uint160(monadRecipient))),
            netAmount,
            fee,
            migrationNonce
        );
    }

    // =============================================================
    //                         ATTESTATION
    // =============================================================

    /**
     * @notice Guardian attestation for a cross-chain migration.
     *
     * This represents the security boundary between the EVM contract and the
     * Solana settlement layer.
     */
    function attestMigration(Attestation calldata attestation) external onlyGuardian {
        Migration storage migration = migrations[attestation.migrationId];

        require(migration.status == MigrationStatus.REQUESTED, "RetroPickDoorwayV1: invalid status");

        require(attestation.amount == migration.amount, "RetroPickDoorwayV1: amount mismatch");

        require(
            attestation.sourceTxHash == migration.sourceTxHash || migration.sourceTxHash == bytes32(0),
            "RetroPickDoorwayV1: source mismatch"
        );

        require(!processedAttestations[attestation.sourceTxHash], "RetroPickDoorwayV1: already attested");

        processedAttestations[attestation.sourceTxHash] = true;

        migration.status = MigrationStatus.ATTESTED;

        emit MigrationAttested(attestation.migrationId, attestation.sourceTxHash, attestation.amount, block.timestamp);
    }

    // =============================================================
    //                         EXECUTION
    // =============================================================

    /**
     * @notice Executes an attested migration.
     *
     * Actual token mint/burn/escrow mechanics would be delegated to a
     * token adapter in a production deployment.
     */
    function executeMigration(bytes32 migrationId, bytes32 destinationTxHash) external onlyRelayer doorwayOpen {
        Migration storage migration = migrations[migrationId];

        require(migration.status == MigrationStatus.ATTESTED, "RetroPickDoorwayV1: not attested");

        migration.status = MigrationStatus.EXECUTING;

        emit MigrationExecutionStarted(migrationId);

        // ---------------------------------------------------------
        // Reference implementation:
        //
        // MONAD -> SOLANA
        //     Locked liquidity remains accounted for on Monad.
        //     Relayer releases equivalent liquidity on Solana.
        //
        // SOLANA -> MONAD
        //     Solana source liquidity is considered burned/locked.
        //     Equivalent Monad representation is released.
        //
        // A production implementation would invoke a token adapter here.
        // ---------------------------------------------------------

        migration.destinationTxHash = destinationTxHash;
        migration.completedAt = block.timestamp;

        migration.status = MigrationStatus.COMPLETED;

        emit MigrationCompleted(migrationId, destinationTxHash, migration.amount);
    }

    // =============================================================
    //                         CANCELLATION
    // =============================================================

    /**
     * @notice Cancels an unexecuted migration after the safety delay.
     */
    function cancelMigration(bytes32 migrationId) external {
        Migration storage migration = migrations[migrationId];

        require(migration.initiator == msg.sender || msg.sender == guardian, "RetroPickDoorwayV1: not authorized");

        require(
            migration.status == MigrationStatus.REQUESTED || migration.status == MigrationStatus.ATTESTED,
            "RetroPickDoorwayV1: cannot cancel"
        );

        // block-timestamp: CANCELLATION_DELAY is coarse (minutes+); miner timestamp drift of seconds cannot bypass the lock.
        // forge-lint: disable-next-line(block-timestamp)
        require(block.timestamp >= migration.createdAt + CANCELLATION_DELAY, "RetroPickDoorwayV1: cancellation locked");

        migration.status = MigrationStatus.CANCELLED;

        emit MigrationCancelled(migrationId);
    }

    // =============================================================
    //                         VIEW FUNCTIONS
    // =============================================================

    function getMigration(bytes32 migrationId) external view returns (Migration memory) {
        return migrations[migrationId];
    }

    function migrationExists(bytes32 migrationId) external view returns (bool) {
        return migrations[migrationId].status != MigrationStatus.NONE;
    }

    function calculateFee(uint256 amount) public view returns (uint256) {
        return (amount * migrationFeeBps) / 10_000;
    }

    function calculateNetAmount(uint256 amount) external view returns (uint256) {
        return amount - calculateFee(amount);
    }

    function isMonadTokenSupported(address token) external view returns (bool) {
        return supportedMonadTokens[token];
    }

    function isSolanaMintSupported(bytes32 mint) external view returns (bool) {
        return supportedSolanaMints[mint];
    }

    // =============================================================
    //                       ADMINISTRATION
    // =============================================================

    function setMonadToken(address token, bool enabled) external onlyOwner {
        supportedMonadTokens[token] = enabled;

        emit TokenSupportUpdated(token, enabled);
    }

    function setSolanaMint(bytes32 mint, bool enabled) external onlyOwner {
        supportedSolanaMints[mint] = enabled;

        emit SolanaMintSupportUpdated(mint, enabled);
    }

    function setRelayer(address newRelayer) external onlyOwner {
        require(newRelayer != address(0), "RetroPickDoorwayV1: zero relayer");

        emit RelayerUpdated(relayer, newRelayer);

        // missing-events-access-control: RelayerUpdated(old, new) is emitted immediately above; the linter does not recognize the adjacent emit as covering this assignment.
        // forge-lint: disable-next-line(missing-events-access-control)
        relayer = newRelayer;
    }

    function setGuardian(address newGuardian) external onlyOwner {
        require(newGuardian != address(0), "RetroPickDoorwayV1: zero guardian");

        emit GuardianUpdated(guardian, newGuardian);

        // missing-events-access-control: GuardianUpdated(old, new) is emitted immediately above; the linter does not recognize the adjacent emit as covering this assignment.
        // forge-lint: disable-next-line(missing-events-access-control)
        guardian = newGuardian;
    }

    function setFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= MAX_FEE_BPS, "RetroPickDoorwayV1: fee too high");

        emit FeeUpdated(migrationFeeBps, newFeeBps);

        // missing-events-arithmetic: FeeUpdated(old, new) is emitted immediately above; the linter does not recognize the adjacent emit as covering this assignment.
        // forge-lint: disable-next-line(missing-events-arithmetic)
        migrationFeeBps = newFeeBps;
    }

    function setDoorwayActive(bool active) external onlyOwner {
        doorwayActive = active;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "RetroPickDoorwayV1: zero owner");

        emit OwnershipTransferred(owner, newOwner);

        // missing-events-access-control: OwnershipTransferred(old, new) is emitted immediately above; the linter does not recognize the adjacent emit as covering this assignment.
        // forge-lint: disable-next-line(missing-events-access-control)
        owner = newOwner;
    }
}

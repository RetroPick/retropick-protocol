// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {RetroPickDoorwayV1} from "../../src/RetroPickDoorwayV1.sol";
import {
    IRetroPickDoorwayV1,
    MigrationDirection,
    MigrationStatus,
    Migration,
    Attestation
} from "../../src/interfaces/IRetroPickDoorwayV1.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

/**
 * @notice End-to-end lifecycle integration tests wiring realistic actors
 * (owner, treasury, relayer, guardian, project user) through complete
 * cross-chain migrations in both directions, plus a delayed-cancellation branch.
 * Asserts the full audit trail: source tx -> migration id -> attestation ->
 * destination tx.
 */
contract RetroPickDoorwayE2ETest is Test {
    RetroPickDoorwayV1 internal doorway;
    MockERC20 internal token;

    address internal owner = makeAddr("owner");
    address internal treasury = makeAddr("treasury");
    address internal relayer = makeAddr("relayer");
    address internal guardian = makeAddr("guardian");
    address internal project = makeAddr("project");

    bytes32 internal constant MINT = bytes32(uint256(0x7A11));
    bytes32 internal constant SOL_RECIPIENT = bytes32(uint256(0x5011));
    bytes32 internal constant SOL_SENDER = bytes32(uint256(0x5EED));

    function setUp() public {
        // Owner deploys and configures the Doorway registry.
        vm.startPrank(owner);
        doorway = new RetroPickDoorwayV1(treasury, relayer, guardian);
        token = new MockERC20("RetroPick Bridged Token", "RPBT", 18);
        doorway.setMonadToken(address(token), true);
        doorway.setSolanaMint(MINT, true);
        vm.stopPrank();
    }

    /// @notice Monad -> Solana: request -> attest -> execute -> COMPLETED.
    function test_e2e_monadToSolana_fullLifecycle() public {
        uint256 gross = 250_000 ether;
        uint256 fee = doorway.calculateFee(gross);
        uint256 net = gross - fee;

        // 1. Project initiates a migration into Solana.
        vm.prank(project);
        bytes32 id = doorway.migrateToSolana(address(token), MINT, SOL_RECIPIENT, gross, net);

        Migration memory m = doorway.getMigration(id);
        assertEq(uint8(m.status), uint8(MigrationStatus.REQUESTED), "requested");
        assertEq(uint8(m.direction), uint8(MigrationDirection.MONAD_TO_SOLANA), "direction");
        assertEq(doorway.tokenLiquidity(address(token)), net, "liquidity locked");
        assertEq(doorway.pendingFees(address(token)), fee, "fee accrued");

        // 2. Guardian attests (Monad->Solana carries a zero source hash).
        Attestation memory a = Attestation(id, m.sourceTxHash, m.amount, vm.getBlockTimestamp(), m.nonce);
        vm.prank(guardian);
        doorway.attestMigration(a);
        assertEq(uint8(doorway.getMigration(id).status), uint8(MigrationStatus.ATTESTED), "attested");

        // 3. Relayer executes with the Solana destination tx hash.
        bytes32 destTx = keccak256("solana-destination-tx");
        vm.warp(vm.getBlockTimestamp() + 5 minutes);
        vm.prank(relayer);
        doorway.executeMigration(id, destTx);

        Migration memory done = doorway.getMigration(id);
        assertEq(uint8(done.status), uint8(MigrationStatus.COMPLETED), "completed");
        assertEq(done.destinationTxHash, destTx, "dest tx recorded");
        assertEq(done.completedAt, block.timestamp, "completedAt");
        assertEq(done.amount, net, "net preserved through lifecycle");
    }

    /// @notice Solana -> Monad: relayer request -> attest -> execute -> COMPLETED,
    /// with the source tx hash threaded through the whole audit trail.
    function test_e2e_solanaToMonad_fullLifecycle() public {
        uint256 gross = 80_000 ether;
        uint256 fee = doorway.calculateFee(gross);
        uint256 net = gross - fee;
        bytes32 srcTx = keccak256("solana-source-tx");

        // 1. Relayer reports the observed Solana source transaction.
        vm.prank(relayer);
        bytes32 id = doorway.requestFromSolana(MINT, SOL_SENDER, address(token), project, gross, 42, srcTx);

        Migration memory m = doorway.getMigration(id);
        assertEq(uint8(m.direction), uint8(MigrationDirection.SOLANA_TO_MONAD), "direction");
        assertEq(m.sourceTxHash, srcTx, "source tx threaded");
        assertEq(m.initiator, project, "initiator is recipient");
        assertTrue(doorway.usedSourceTransactions(srcTx), "source consumed");

        // 2. Guardian attests against the real source tx hash.
        Attestation memory a = Attestation(id, srcTx, net, block.timestamp, m.nonce);
        vm.prank(guardian);
        doorway.attestMigration(a);
        assertTrue(doorway.processedAttestations(srcTx), "attestation processed");

        // 3. Relayer executes with the Monad destination tx hash.
        bytes32 destTx = keccak256("monad-destination-tx");
        vm.prank(relayer);
        doorway.executeMigration(id, destTx);

        Migration memory done = doorway.getMigration(id);
        assertEq(uint8(done.status), uint8(MigrationStatus.COMPLETED), "completed");

        // Full audit trail: srcTx -> id -> attestation(srcTx) -> destTx.
        assertEq(done.sourceTxHash, srcTx, "trail source");
        assertEq(done.destinationTxHash, destTx, "trail destination");
        assertEq(fee, doorway.pendingFees(address(token)), "fee accounted");
    }

    /// @notice A stuck migration can be cancelled by the initiator after the delay.
    function test_e2e_delayedCancellationBranch() public {
        vm.prank(project);
        bytes32 id = doorway.migrateToSolana(address(token), MINT, SOL_RECIPIENT, 10_000 ether, 0);

        // Too early: cancellation is locked.
        vm.prank(project);
        vm.expectRevert("RetroPickDoorwayV1: cancellation locked");
        doorway.cancelMigration(id);

        // After the safety window, the initiator can cancel.
        vm.warp(vm.getBlockTimestamp() + doorway.CANCELLATION_DELAY());
        vm.prank(project);
        doorway.cancelMigration(id);
        assertEq(uint8(doorway.getMigration(id).status), uint8(MigrationStatus.CANCELLED), "cancelled");

        // A cancelled migration can no longer be attested.
        Migration memory m = doorway.getMigration(id);
        Attestation memory a = Attestation(id, m.sourceTxHash, m.amount, block.timestamp, m.nonce);
        vm.prank(guardian);
        vm.expectRevert("RetroPickDoorwayV1: invalid status");
        doorway.attestMigration(a);
    }

    /// @notice Owner pause halts new migrations and blocks in-flight execution,
    /// then resuming restores normal operation.
    function test_e2e_pauseAndResume() public {
        vm.prank(relayer);
        bytes32 id = doorway.requestFromSolana(
            MINT, SOL_SENDER, address(token), project, 5_000 ether, 1, keccak256("src-pause")
        );

        // Attest while active.
        Migration memory m = doorway.getMigration(id);
        Attestation memory a = Attestation(id, m.sourceTxHash, m.amount, block.timestamp, m.nonce);
        vm.prank(guardian);
        doorway.attestMigration(a);

        // Owner pauses: execution is blocked.
        vm.prank(owner);
        doorway.setDoorwayActive(false);
        vm.prank(relayer);
        vm.expectRevert("RetroPickDoorwayV1: paused");
        doorway.executeMigration(id, keccak256("dest-pause"));

        // Owner resumes: execution completes.
        vm.prank(owner);
        doorway.setDoorwayActive(true);
        vm.prank(relayer);
        doorway.executeMigration(id, keccak256("dest-pause"));
        assertEq(uint8(doorway.getMigration(id).status), uint8(MigrationStatus.COMPLETED), "completed after resume");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {RetroPickDoorwayBaseTest} from "./RetroPickDoorwayBase.t.sol";
import {
    MigrationDirection,
    MigrationStatus,
    Migration,
    Attestation
} from "../../src/interfaces/IRetroPickDoorwayV1.sol";

/**
 * @notice Unit tests for the Solana -> Monad request path plus the shared
 * attestation / execution / cancellation state machine.
 */
contract RetroPickDoorwayLifecycleTest is RetroPickDoorwayBaseTest {
    bytes32 internal constant SRC_TX = bytes32(uint256(0xF00D));
    bytes32 internal constant DEST_TX = bytes32(uint256(0xD00D));

    // ------------------------------------------------------------------
    // requestFromSolana
    // ------------------------------------------------------------------

    function test_requestFromSolana_happyPath() public {
        uint256 amount = 50_000 ether;
        uint256 fee = (amount * 25) / 10_000;
        uint256 net = amount - fee;

        bytes32 id = _requestFromSolana(amount, SRC_TX, 7);

        Migration memory m = doorway.getMigration(id);
        assertEq(uint8(m.direction), uint8(MigrationDirection.SOLANA_TO_MONAD), "direction");
        assertEq(uint8(m.status), uint8(MigrationStatus.REQUESTED), "status");
        assertEq(m.initiator, user, "initiator");
        assertEq(m.amount, net, "net");
        assertEq(m.minAmountOut, net, "minOut == net");
        assertEq(m.sourceTxHash, SRC_TX, "sourceTx");
        assertEq(m.fee, fee, "fee");
        assertTrue(doorway.usedSourceTransactions(SRC_TX), "source marked used");
        assertEq(doorway.pendingFees(address(token)), fee, "pendingFees");
    }

    function test_requestFromSolana_onlyRelayer() public {
        vm.prank(stranger);
        vm.expectRevert("RetroPickDoorwayV1: not relayer");
        doorway.requestFromSolana(SOLANA_MINT, SOLANA_SENDER, address(token), user, 1 ether, 1, SRC_TX);
    }

    function test_requestFromSolana_replayRevertsOnUsedSourceTx() public {
        _requestFromSolana(1_000 ether, SRC_TX, 1);

        vm.prank(relayer);
        vm.expectRevert("RetroPickDoorwayV1: source tx used");
        doorway.requestFromSolana(SOLANA_MINT, SOLANA_SENDER, address(token), user, 1_000 ether, 2, SRC_TX);
    }

    function test_requestFromSolana_revertsUnsupportedMintTokenZero() public {
        vm.startPrank(relayer);

        vm.expectRevert("RetroPickDoorwayV1: mint unsupported");
        doorway.requestFromSolana(bytes32(uint256(0xBAD)), SOLANA_SENDER, address(token), user, 1 ether, 1, SRC_TX);

        vm.expectRevert("RetroPickDoorwayV1: token unsupported");
        doorway.requestFromSolana(SOLANA_MINT, SOLANA_SENDER, address(0xdead), user, 1 ether, 1, SRC_TX);

        vm.expectRevert("RetroPickDoorwayV1: zero amount");
        doorway.requestFromSolana(SOLANA_MINT, SOLANA_SENDER, address(token), user, 0, 1, SRC_TX);

        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // attestMigration
    // ------------------------------------------------------------------

    function test_attest_happyPath_solanaToMonad() public {
        bytes32 id = _requestFromSolana(10_000 ether, SRC_TX, 1);
        _attest(id);
        assertEq(uint8(doorway.getMigration(id).status), uint8(MigrationStatus.ATTESTED), "attested");
        assertTrue(doorway.processedAttestations(SRC_TX), "processed");
    }

    function test_attest_onlyGuardian() public {
        bytes32 id = _requestFromSolana(10_000 ether, SRC_TX, 1);
        Migration memory m = doorway.getMigration(id);
        Attestation memory a = Attestation(id, m.sourceTxHash, m.amount, block.timestamp, m.nonce);

        vm.prank(stranger);
        vm.expectRevert("RetroPickDoorwayV1: not guardian");
        doorway.attestMigration(a);
    }

    function test_attest_revertsOnAmountMismatch() public {
        bytes32 id = _requestFromSolana(10_000 ether, SRC_TX, 1);
        Migration memory m = doorway.getMigration(id);
        Attestation memory a = Attestation(id, m.sourceTxHash, m.amount + 1, block.timestamp, m.nonce);

        vm.prank(guardian);
        vm.expectRevert("RetroPickDoorwayV1: amount mismatch");
        doorway.attestMigration(a);
    }

    function test_attest_revertsOnInvalidStatus() public {
        // Attest twice: second attempt sees status ATTESTED, not REQUESTED.
        bytes32 id = _requestFromSolana(10_000 ether, SRC_TX, 1);
        _attest(id);

        Migration memory m = doorway.getMigration(id);
        Attestation memory a = Attestation(id, m.sourceTxHash, m.amount, block.timestamp, m.nonce);
        vm.prank(guardian);
        vm.expectRevert("RetroPickDoorwayV1: invalid status");
        doorway.attestMigration(a);
    }

    /**
     * @notice DOCUMENTED KNOWN LIMITATION (reference baseline).
     * Monad -> Solana migrations store sourceTxHash == bytes32(0). The
     * attestation replay guard keys on sourceTxHash, so the zero-hash slot
     * latches after the first Monad->Solana attestation and every subsequent
     * Monad->Solana migration can never be attested. This test pins that behavior
     * so a future fix (e.g. keying replay protection on migrationId) is a
     * deliberate, visible change.
     */
    function test_attest_knownLimitation_zeroHashLatchesForMonadToSolana() public {
        bytes32 id1 = _requestToSolana(1_000 ether, 0);
        bytes32 id2 = _requestToSolana(2_000 ether, 0);

        // First Monad->Solana attestation succeeds and latches processedAttestations[0].
        _attest(id1);
        assertEq(uint8(doorway.getMigration(id1).status), uint8(MigrationStatus.ATTESTED), "first attested");
        assertTrue(doorway.processedAttestations(bytes32(0)), "zero-hash latched");

        // Second Monad->Solana attestation reverts because the zero-hash slot is set.
        Migration memory m2 = doorway.getMigration(id2);
        Attestation memory a2 = Attestation(id2, m2.sourceTxHash, m2.amount, block.timestamp, m2.nonce);
        vm.prank(guardian);
        vm.expectRevert("RetroPickDoorwayV1: already attested");
        doorway.attestMigration(a2);
    }

    // ------------------------------------------------------------------
    // executeMigration
    // ------------------------------------------------------------------

    function test_execute_happyPath() public {
        bytes32 id = _requestFromSolana(10_000 ether, SRC_TX, 1);
        _attest(id);

        vm.warp(vm.getBlockTimestamp() + 1);
        _execute(id, DEST_TX);

        Migration memory m = doorway.getMigration(id);
        assertEq(uint8(m.status), uint8(MigrationStatus.COMPLETED), "completed");
        assertEq(m.destinationTxHash, DEST_TX, "dest tx recorded");
        assertEq(m.completedAt, block.timestamp, "completedAt");
    }

    function test_execute_onlyRelayer() public {
        bytes32 id = _requestFromSolana(10_000 ether, SRC_TX, 1);
        _attest(id);

        vm.prank(stranger);
        vm.expectRevert("RetroPickDoorwayV1: not relayer");
        doorway.executeMigration(id, DEST_TX);
    }

    function test_execute_revertsIfNotAttested() public {
        bytes32 id = _requestFromSolana(10_000 ether, SRC_TX, 1);
        vm.prank(relayer);
        vm.expectRevert("RetroPickDoorwayV1: not attested");
        doorway.executeMigration(id, DEST_TX);
    }

    function test_execute_blockedWhenPaused() public {
        bytes32 id = _requestFromSolana(10_000 ether, SRC_TX, 1);
        _attest(id);

        vm.prank(owner);
        doorway.setDoorwayActive(false);

        vm.prank(relayer);
        vm.expectRevert("RetroPickDoorwayV1: paused");
        doorway.executeMigration(id, DEST_TX);
    }

    // ------------------------------------------------------------------
    // cancelMigration
    // ------------------------------------------------------------------

    function test_cancel_byInitiatorAfterDelay() public {
        bytes32 id = _requestToSolana(1_000 ether, 0);

        vm.warp(block.timestamp + doorway.CANCELLATION_DELAY());
        vm.prank(user);
        doorway.cancelMigration(id);
        assertEq(uint8(doorway.getMigration(id).status), uint8(MigrationStatus.CANCELLED), "cancelled");
    }

    function test_cancel_byGuardianAfterDelay() public {
        bytes32 id = _requestFromSolana(1_000 ether, SRC_TX, 1);

        vm.warp(block.timestamp + doorway.CANCELLATION_DELAY());
        vm.prank(guardian);
        doorway.cancelMigration(id);
        assertEq(uint8(doorway.getMigration(id).status), uint8(MigrationStatus.CANCELLED), "cancelled");
    }

    function test_cancel_revertsBeforeDelay() public {
        bytes32 id = _requestToSolana(1_000 ether, 0);
        vm.prank(user);
        vm.expectRevert("RetroPickDoorwayV1: cancellation locked");
        doorway.cancelMigration(id);
    }

    function test_cancel_revertsForUnauthorized() public {
        bytes32 id = _requestToSolana(1_000 ether, 0);
        vm.warp(block.timestamp + doorway.CANCELLATION_DELAY());
        vm.prank(stranger);
        vm.expectRevert("RetroPickDoorwayV1: not authorized");
        doorway.cancelMigration(id);
    }

    function test_cancel_revertsWhenCompleted() public {
        bytes32 id = _requestFromSolana(1_000 ether, SRC_TX, 1);
        _attest(id);
        _execute(id, DEST_TX);

        vm.warp(block.timestamp + doorway.CANCELLATION_DELAY());
        vm.prank(user);
        vm.expectRevert("RetroPickDoorwayV1: cannot cancel");
        doorway.cancelMigration(id);
    }

    function test_cancel_allowedFromAttestedState() public {
        bytes32 id = _requestFromSolana(1_000 ether, SRC_TX, 1);
        _attest(id);

        vm.warp(block.timestamp + doorway.CANCELLATION_DELAY());
        vm.prank(guardian);
        doorway.cancelMigration(id);
        assertEq(uint8(doorway.getMigration(id).status), uint8(MigrationStatus.CANCELLED), "cancelled from attested");
    }
}

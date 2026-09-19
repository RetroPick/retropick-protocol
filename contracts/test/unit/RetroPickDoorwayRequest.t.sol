// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {RetroPickDoorwayBaseTest} from "./RetroPickDoorwayBase.t.sol";
import {RetroPickDoorwayV1} from "../../src/RetroPickDoorwayV1.sol";
import {
    IRetroPickDoorwayV1,
    MigrationDirection,
    MigrationStatus,
    Migration
} from "../../src/interfaces/IRetroPickDoorwayV1.sol";

/**
 * @notice Unit tests for the Monad -> Solana request path and the full
 * owner-gated administration surface of RetroPickDoorwayV1.
 */
contract RetroPickDoorwayRequestTest is RetroPickDoorwayBaseTest {
    // ------------------------------------------------------------------
    // Deployment
    // ------------------------------------------------------------------

    function test_deploy_setsRolesAndDefaults() public view {
        assertEq(doorway.owner(), owner, "owner");
        assertEq(doorway.treasury(), treasury, "treasury");
        assertEq(doorway.relayer(), relayer, "relayer");
        assertEq(doorway.guardian(), guardian, "guardian");
        assertEq(doorway.migrationFeeBps(), 25, "default fee");
        assertTrue(doorway.doorwayActive(), "active");
        assertEq(doorway.MAX_FEE_BPS(), 100, "max fee");
        assertEq(doorway.CANCELLATION_DELAY(), 30 minutes, "cancel delay");
    }

    // ------------------------------------------------------------------
    // migrateToSolana happy path
    // ------------------------------------------------------------------

    function test_migrateToSolana_recordsMigrationAndAccounting() public {
        uint256 amount = 100_000 ether;
        uint256 expectedFee = (amount * 25) / 10_000; // 0.25%
        uint256 expectedNet = amount - expectedFee;

        bytes32 id = _requestToSolana(amount, expectedNet);

        Migration memory m = doorway.getMigration(id);
        assertEq(uint8(m.direction), uint8(MigrationDirection.MONAD_TO_SOLANA), "direction");
        assertEq(uint8(m.status), uint8(MigrationStatus.REQUESTED), "status");
        assertEq(m.initiator, user, "initiator");
        assertEq(m.monadToken, address(token), "token");
        assertEq(m.solanaMint, SOLANA_MINT, "mint");
        assertEq(m.destination, SOLANA_RECIPIENT, "dest");
        assertEq(m.amount, expectedNet, "net amount");
        assertEq(m.fee, expectedFee, "fee");
        assertEq(m.nonce, 1, "nonce");
        assertEq(m.sourceTxHash, bytes32(0), "sourceTx zero");
        assertEq(m.completedAt, 0, "not completed");

        assertEq(doorway.pendingFees(address(token)), expectedFee, "pendingFees");
        assertEq(doorway.tokenLiquidity(address(token)), expectedNet, "tokenLiquidity");
        assertTrue(doorway.migrationExists(id), "exists");
        assertEq(doorway.migrationNonce(), 1, "global nonce");
    }

    function test_migrateToSolana_emitsMigrationRequested() public {
        uint256 amount = 40_000 ether;
        uint256 fee = (amount * 25) / 10_000;
        uint256 net = amount - fee;

        // topic0..topic3 checked = false for data section; we assert full record
        // by not pre-computing id (id is a data field here, so use partial match).
        vm.expectEmit(false, true, true, false);
        emit IRetroPickDoorwayV1.MigrationRequested(
            bytes32(0),
            MigrationDirection.MONAD_TO_SOLANA,
            user,
            address(token),
            SOLANA_MINT,
            SOLANA_RECIPIENT,
            net,
            fee,
            1
        );

        vm.prank(user);
        doorway.migrateToSolana(address(token), SOLANA_MINT, SOLANA_RECIPIENT, amount, net);
    }

    function test_migrateToSolana_incrementsNonceAndUniqueIds() public {
        bytes32 id1 = _requestToSolana(1_000 ether, 0);
        bytes32 id2 = _requestToSolana(1_000 ether, 0);
        assertTrue(id1 != id2, "ids unique across nonce");
        assertEq(doorway.migrationNonce(), 2, "nonce incremented twice");
    }

    // ------------------------------------------------------------------
    // migrateToSolana reverts
    // ------------------------------------------------------------------

    function test_migrateToSolana_revertsOnUnsupportedToken() public {
        vm.prank(user);
        vm.expectRevert("RetroPickDoorwayV1: token unsupported");
        doorway.migrateToSolana(address(0xdead), SOLANA_MINT, SOLANA_RECIPIENT, 1 ether, 0);
    }

    function test_migrateToSolana_revertsOnUnsupportedMint() public {
        vm.prank(user);
        vm.expectRevert("RetroPickDoorwayV1: mint unsupported");
        doorway.migrateToSolana(address(token), bytes32(uint256(0xBAD)), SOLANA_RECIPIENT, 1 ether, 0);
    }

    function test_migrateToSolana_revertsOnZeroAmount() public {
        vm.prank(user);
        vm.expectRevert("RetroPickDoorwayV1: zero amount");
        doorway.migrateToSolana(address(token), SOLANA_MINT, SOLANA_RECIPIENT, 0, 0);
    }

    function test_migrateToSolana_revertsWhenPaused() public {
        vm.prank(owner);
        doorway.setDoorwayActive(false);

        vm.prank(user);
        vm.expectRevert("RetroPickDoorwayV1: paused");
        doorway.migrateToSolana(address(token), SOLANA_MINT, SOLANA_RECIPIENT, 1 ether, 0);
    }

    // ------------------------------------------------------------------
    // Fee views
    // ------------------------------------------------------------------

    function test_calculateFeeAndNet() public view {
        uint256 amount = 100_000 ether;
        uint256 fee = doorway.calculateFee(amount);
        assertEq(fee, (amount * 25) / 10_000, "fee");
        assertEq(doorway.calculateNetAmount(amount), amount - fee, "net");
    }

    // ------------------------------------------------------------------
    // Administration: access control
    // ------------------------------------------------------------------

    function test_setMonadToken_onlyOwner() public {
        vm.prank(stranger);
        vm.expectRevert("RetroPickDoorwayV1: not owner");
        doorway.setMonadToken(address(token), false);

        vm.prank(owner);
        doorway.setMonadToken(address(0xbeef), true);
        assertTrue(doorway.isMonadTokenSupported(address(0xbeef)), "enabled");
    }

    function test_setSolanaMint_onlyOwner() public {
        vm.prank(stranger);
        vm.expectRevert("RetroPickDoorwayV1: not owner");
        doorway.setSolanaMint(SOLANA_MINT, false);

        vm.prank(owner);
        doorway.setSolanaMint(bytes32(uint256(0xFEED)), true);
        assertTrue(doorway.isSolanaMintSupported(bytes32(uint256(0xFEED))), "enabled");
    }

    function test_setRelayer_onlyOwner() public {
        vm.prank(stranger);
        vm.expectRevert("RetroPickDoorwayV1: not owner");
        doorway.setRelayer(stranger);

        vm.prank(owner);
        doorway.setRelayer(address(0xabc));
        assertEq(doorway.relayer(), address(0xabc), "relayer updated");
    }

    function test_setGuardian_onlyOwner() public {
        vm.prank(stranger);
        vm.expectRevert("RetroPickDoorwayV1: not owner");
        doorway.setGuardian(stranger);

        vm.prank(owner);
        doorway.setGuardian(address(0xdef));
        assertEq(doorway.guardian(), address(0xdef), "guardian updated");
    }

    function test_setFee_onlyOwnerAndRespectsMax() public {
        vm.prank(stranger);
        vm.expectRevert("RetroPickDoorwayV1: not owner");
        doorway.setFee(10);

        vm.prank(owner);
        doorway.setFee(100); // exactly MAX_FEE_BPS
        assertEq(doorway.migrationFeeBps(), 100, "fee set to max");

        vm.prank(owner);
        vm.expectRevert("RetroPickDoorwayV1: fee too high");
        doorway.setFee(101);
    }

    function test_setDoorwayActive_onlyOwner() public {
        vm.prank(stranger);
        vm.expectRevert("RetroPickDoorwayV1: not owner");
        doorway.setDoorwayActive(false);

        vm.prank(owner);
        doorway.setDoorwayActive(false);
        assertFalse(doorway.doorwayActive(), "paused");
    }

    function test_transferOwnership_onlyOwnerAndNonZero() public {
        vm.prank(stranger);
        vm.expectRevert("RetroPickDoorwayV1: not owner");
        doorway.transferOwnership(stranger);

        vm.prank(owner);
        vm.expectRevert("RetroPickDoorwayV1: zero owner");
        doorway.transferOwnership(address(0));

        vm.prank(owner);
        doorway.transferOwnership(user);
        assertEq(doorway.owner(), user, "ownership transferred");
    }
}

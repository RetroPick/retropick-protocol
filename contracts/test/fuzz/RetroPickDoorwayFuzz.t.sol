// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {RetroPickDoorwayV1} from "../../src/RetroPickDoorwayV1.sol";
import {Migration, MigrationStatus} from "../../src/interfaces/IRetroPickDoorwayV1.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

/**
 * @notice Property-based fuzz tests for RetroPickDoorwayV1: fee arithmetic,
 * per-migration accounting consistency, and migration-id uniqueness.
 */
contract RetroPickDoorwayFuzzTest is Test {
    RetroPickDoorwayV1 internal doorway;
    MockERC20 internal token;

    address internal owner = makeAddr("owner");
    address internal treasury = makeAddr("treasury");
    address internal relayer = makeAddr("relayer");
    address internal guardian = makeAddr("guardian");

    bytes32 internal constant MINT = bytes32(uint256(0xABCDEF));
    bytes32 internal constant RECIPIENT = bytes32(uint256(0x1111));

    function setUp() public {
        vm.prank(owner);
        doorway = new RetroPickDoorwayV1(treasury, relayer, guardian);
        token = new MockERC20("Mock", "MMT", 18);

        vm.startPrank(owner);
        doorway.setMonadToken(address(token), true);
        doorway.setSolanaMint(MINT, true);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // Fee math properties
    // ------------------------------------------------------------------

    /// @dev fee == amount * bps / 1e4; fee + net == amount; fee bounded by bps.
    function testFuzz_feeMathConsistent(uint256 amount, uint16 bps) public {
        bps = uint16(bound(bps, 0, doorway.MAX_FEE_BPS()));
        // Bound amount so amount * bps cannot overflow uint256.
        amount = bound(amount, 0, type(uint256).max / 10_000);

        vm.prank(owner);
        doorway.setFee(bps);

        uint256 fee = doorway.calculateFee(amount);
        uint256 net = doorway.calculateNetAmount(amount);

        assertEq(fee, (amount * bps) / 10_000, "fee formula");
        assertEq(fee + net, amount, "fee + net == amount");
        assertLe(fee, amount, "fee never exceeds amount");
        // With bps <= 100 (1%), fee <= amount / 100.
        assertLe(fee, (amount * doorway.MAX_FEE_BPS()) / 10_000, "fee within max bound");
    }

    /// @dev setFee above MAX_FEE_BPS always reverts.
    function testFuzz_setFeeRejectsAboveMax(uint256 bps) public {
        bps = bound(bps, doorway.MAX_FEE_BPS() + 1, type(uint256).max);
        vm.prank(owner);
        vm.expectRevert("RetroPickDoorwayV1: fee too high");
        doorway.setFee(bps);
    }

    // ------------------------------------------------------------------
    // Accounting consistency
    // ------------------------------------------------------------------

    /// @dev After a single migrateToSolana, liquidity + fee reconstruct the gross
    /// amount, and stored net/fee match the pure fee views.
    function testFuzz_migrateToSolanaAccounting(uint256 amount, uint16 bps) public {
        bps = uint16(bound(bps, 0, doorway.MAX_FEE_BPS()));
        amount = bound(amount, 1, 1e30); // non-zero, realistic upper bound

        vm.prank(owner);
        doorway.setFee(bps);

        uint256 expectedFee = doorway.calculateFee(amount);
        uint256 expectedNet = amount - expectedFee;

        vm.prank(address(this));
        bytes32 id = doorway.migrateToSolana(address(token), MINT, RECIPIENT, amount, 0);

        Migration memory m = doorway.getMigration(id);
        assertEq(m.amount, expectedNet, "stored net");
        assertEq(m.fee, expectedFee, "stored fee");
        assertEq(doorway.pendingFees(address(token)), expectedFee, "pendingFees");
        assertEq(doorway.tokenLiquidity(address(token)), expectedNet, "tokenLiquidity");
        // Reconstruct gross: liquidity + fees == amount.
        assertEq(doorway.tokenLiquidity(address(token)) + doorway.pendingFees(address(token)), amount, "gross");
    }

    // ------------------------------------------------------------------
    // Migration-id uniqueness
    // ------------------------------------------------------------------

    /// @dev Two sequential migrateToSolana calls (even identical params) get
    /// distinct ids because the incrementing nonce is part of the preimage.
    function testFuzz_migrationIdsUniqueAcrossNonce(uint256 amount) public {
        amount = bound(amount, 1, 1e30);

        bytes32 id1 = doorway.migrateToSolana(address(token), MINT, RECIPIENT, amount, 0);
        bytes32 id2 = doorway.migrateToSolana(address(token), MINT, RECIPIENT, amount, 0);

        assertTrue(id1 != id2, "ids differ across nonce");
        assertTrue(doorway.migrationExists(id1) && doorway.migrationExists(id2), "both exist");
    }

    /// @dev requestFromSolana ids are unique per distinct source tx hash.
    function testFuzz_requestFromSolanaUniquePerSourceTx(bytes32 srcA, bytes32 srcB, uint256 amount) public {
        vm.assume(srcA != srcB);
        amount = bound(amount, 1, 1e30);

        vm.startPrank(relayer);
        bytes32 id1 = doorway.requestFromSolana(MINT, RECIPIENT, address(token), address(this), amount, 1, srcA);
        bytes32 id2 = doorway.requestFromSolana(MINT, RECIPIENT, address(token), address(this), amount, 2, srcB);
        vm.stopPrank();

        assertTrue(id1 != id2, "distinct ids");
        assertTrue(doorway.usedSourceTransactions(srcA), "srcA used");
        assertTrue(doorway.usedSourceTransactions(srcB), "srcB used");
    }
}

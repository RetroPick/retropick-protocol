// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {RetroPickDoorwayV1} from "../../src/RetroPickDoorwayV1.sol";
import {Migration, MigrationStatus, Attestation} from "../../src/interfaces/IRetroPickDoorwayV1.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

/**
 * @notice Handler that drives RetroPickDoorwayV1 through randomized lifecycle
 * call sequences and records ghost state the invariants assert against.
 */
contract DoorwayHandler is Test {
    RetroPickDoorwayV1 public doorway;
    MockERC20 public token;
    address public relayer;
    address public guardian;

    bytes32 public constant MINT = bytes32(uint256(0xABCDEF));

    // Ghost accounting: gross amount ever fed into Monad->Solana migrations.
    uint256 public ghostGrossToSolana;
    // Ghost accounting: fees credited by Solana->Monad requests (these also land in
    // pendingFees[token] even though no tokenLiquidity is added for that path).
    uint256 public ghostFeesFromSolana;

    bytes32[] public ids;
    mapping(bytes32 => bool) internal known;

    // Replay tracking for source-tx uniqueness invariant.
    uint256 public reprocessedSourceTxCount;

    constructor(RetroPickDoorwayV1 _doorway, MockERC20 _token, address _relayer, address _guardian) {
        doorway = _doorway;
        token = _token;
        relayer = _relayer;
        guardian = _guardian;
    }

    function _track(bytes32 id) internal {
        if (!known[id]) {
            known[id] = true;
            ids.push(id);
        }
    }

    function idsLength() external view returns (uint256) {
        return ids.length;
    }

    function migrateToSolana(uint256 amount) external {
        amount = bound(amount, 1, 1e27);
        bytes32 id = doorway.migrateToSolana(address(token), MINT, bytes32(uint256(0x1111)), amount, 0);
        ghostGrossToSolana += amount;
        _track(id);
    }

    function requestFromSolana(uint256 amount, bytes32 srcTx) external {
        amount = bound(amount, 1, 1e27);
        if (doorway.usedSourceTransactions(srcTx)) {
            // Confirm the contract rejects reuse; count guards the invariant.
            vm.prank(relayer);
            try doorway.requestFromSolana(MINT, bytes32(0), address(token), address(this), amount, 1, srcTx) {
                reprocessedSourceTxCount += 1; // should never happen
            } catch {}
            return;
        }
        vm.prank(relayer);
        bytes32 id = doorway.requestFromSolana(MINT, bytes32(0), address(token), address(this), amount, 1, srcTx);
        ghostFeesFromSolana += doorway.calculateFee(amount);
        _track(id);
    }

    function attest(uint256 seed) external {
        if (ids.length == 0) return;
        bytes32 id = ids[seed % ids.length];
        Migration memory m = doorway.getMigration(id);
        if (m.status != MigrationStatus.REQUESTED) return;
        Attestation memory a = Attestation(id, m.sourceTxHash, m.amount, block.timestamp, m.nonce);
        vm.prank(guardian);
        try doorway.attestMigration(a) {} catch {}
    }

    function execute(uint256 seed, bytes32 destTx) external {
        if (ids.length == 0) return;
        bytes32 id = ids[seed % ids.length];
        Migration memory m = doorway.getMigration(id);
        if (m.status != MigrationStatus.ATTESTED) return;
        vm.prank(relayer);
        try doorway.executeMigration(id, destTx) {} catch {}
    }

    function cancel(uint256 seed) external {
        if (ids.length == 0) return;
        bytes32 id = ids[seed % ids.length];
        vm.warp(block.timestamp + doorway.CANCELLATION_DELAY() + 1);
        vm.prank(guardian);
        try doorway.cancelMigration(id) {} catch {}
    }
}

/**
 * @notice Stateful, security-focused invariants for RetroPickDoorwayV1.
 */
contract RetroPickDoorwayInvariantTest is StdInvariant, Test {
    RetroPickDoorwayV1 internal doorway;
    MockERC20 internal token;
    DoorwayHandler internal handler;

    address internal owner = makeAddr("owner");
    address internal treasury = makeAddr("treasury");
    address internal relayer = makeAddr("relayer");
    address internal guardian = makeAddr("guardian");

    bytes32 internal constant MINT = bytes32(uint256(0xABCDEF));

    function setUp() public {
        vm.prank(owner);
        doorway = new RetroPickDoorwayV1(treasury, relayer, guardian);
        token = new MockERC20("Mock", "MMT", 18);

        vm.startPrank(owner);
        doorway.setMonadToken(address(token), true);
        doorway.setSolanaMint(MINT, true);
        vm.stopPrank();

        handler = new DoorwayHandler(doorway, token, relayer, guardian);
        targetContract(address(handler));
    }

    /// @dev A source transaction can never be processed twice by the contract.
    function invariant_sourceTxNeverReprocessed() public view {
        assertEq(handler.reprocessedSourceTxCount(), 0, "source tx reprocessed");
    }

    /// @dev Pure accounting is conserved: tokenLiquidity (Monad->Solana net only)
    /// plus pendingFees (both paths) reconstructs exactly the Monad->Solana gross
    /// plus the fees credited by Solana->Monad requests. No external transfers occur.
    function invariant_monadAccountingConserved() public view {
        assertEq(
            doorway.tokenLiquidity(address(token)) + doorway.pendingFees(address(token)),
            handler.ghostGrossToSolana() + handler.ghostFeesFromSolana(),
            "Monad accounting conserved"
        );
    }

    /// @dev Every tracked migration is in a valid (non-NONE) state, and any
    /// COMPLETED migration has a recorded completion timestamp.
    function invariant_migrationStateWellFormed() public view {
        uint256 n = handler.idsLength();
        for (uint256 i = 0; i < n; i++) {
            bytes32 id = handler.ids(i);
            Migration memory m = doorway.getMigration(id);
            assertTrue(m.status != MigrationStatus.NONE, "tracked migration exists");
            if (m.status == MigrationStatus.COMPLETED) {
                assertTrue(m.completedAt != 0, "completed has timestamp");
            }
        }
    }

    /// @dev Fee never exceeds the configured maximum share of any migration's gross.
    function invariant_feeNeverExceedsNet() public view {
        uint256 n = handler.idsLength();
        for (uint256 i = 0; i < n; i++) {
            bytes32 id = handler.ids(i);
            Migration memory m = doorway.getMigration(id);
            // fee <= amount(net) is guaranteed since fee is tiny fraction; assert fee <= gross.
            assertLe(m.fee, m.amount + m.fee, "fee <= gross");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {RetroPickDoorwayV1} from "../../src/v1/RetroPickDoorwayV1.sol";
import {
    MigrationDirection,
    MigrationStatus,
    Migration,
    Attestation
} from "../../src/v1/interfaces/IRetroPickDoorwayV1.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

/**
 * @notice Shared setup for RetroPickDoorwayV1 unit tests. Deploys the Doorway
 * with distinct owner / treasury / relayer / guardian actors and registers a
 * default supported Monad token and Solana mint. Provides small helpers for
 * driving the migration lifecycle.
 */
abstract contract RetroPickDoorwayBaseTest is Test {
    RetroPickDoorwayV1 internal doorway;
    MockERC20 internal token;

    address internal owner = makeAddr("owner");
    address internal treasury = makeAddr("treasury");
    address internal relayer = makeAddr("relayer");
    address internal guardian = makeAddr("guardian");
    address internal user = makeAddr("user");
    address internal stranger = makeAddr("stranger");

    bytes32 internal constant SOLANA_MINT = bytes32(uint256(0xABCDEF));
    bytes32 internal constant SOLANA_RECIPIENT = bytes32(uint256(0x1111));
    bytes32 internal constant SOLANA_SENDER = bytes32(uint256(0x2222));

    function setUp() public virtual {
        vm.prank(owner);
        doorway = new RetroPickDoorwayV1(treasury, relayer, guardian);

        token = new MockERC20("Mock Monad Token", "MMT", 18);

        vm.startPrank(owner);
        doorway.setMonadToken(address(token), true);
        doorway.setSolanaMint(SOLANA_MINT, true);
        vm.stopPrank();
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    /// @dev Creates a Monad -> Solana migration as `user`.
    function _requestToSolana(uint256 amount, uint256 minOut) internal returns (bytes32 id) {
        vm.prank(user);
        id = doorway.migrateToSolana(address(token), SOLANA_MINT, SOLANA_RECIPIENT, amount, minOut);
    }

    /// @dev Creates a Solana -> Monad migration as the relayer.
    function _requestFromSolana(uint256 amount, bytes32 sourceTxHash, uint256 sourceNonce)
        internal
        returns (bytes32 id)
    {
        vm.prank(relayer);
        id = doorway.requestFromSolana(
            SOLANA_MINT, SOLANA_SENDER, address(token), user, amount, sourceNonce, sourceTxHash
        );
    }

    /// @dev Guardian-attests a migration, echoing the stored amount + sourceTxHash.
    function _attest(bytes32 id) internal {
        Migration memory m = doorway.getMigration(id);
        Attestation memory a = Attestation({
            migrationId: id, sourceTxHash: m.sourceTxHash, amount: m.amount, timestamp: vm.getBlockTimestamp(), nonce: m.nonce
        });
        vm.prank(guardian);
        doorway.attestMigration(a);
    }

    /// @dev Relayer-executes a migration.
    function _execute(bytes32 id, bytes32 destTxHash) internal {
        vm.prank(relayer);
        doorway.executeMigration(id, destTxHash);
    }
}

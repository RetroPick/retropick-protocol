// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidateReservationLedger} from "../../src/prism/CandidateReservationLedger.sol";

/// @notice Reserve 60, then reserve the remaining 40, against a deposited balance of 100.
/// @dev Reserve is not edited. No release and no withdraw. The failing reserve of 50 is not repeated.
contract RemainderReserveTest is Test {
    bytes32 internal constant ASSET = bytes32(uint256(1));
    bytes32 internal constant SERIES_A = bytes32(uint256(1));
    bytes32 internal constant SERIES_B = bytes32(uint256(2));

    function test_second_reserve_of_exact_remainder() public {
        CandidateReservationLedger ledger = new CandidateReservationLedger();
        ledger.deposit(ASSET, 100);
        ledger.reserve(SERIES_A, ASSET, 60);

        assertEq(ledger.balance(ASSET), 100);
        assertEq(ledger.totalReserved(ASSET), 60);
        assertEq(ledger.available(ASSET), 40);
        assertEq(ledger.reservedFor(SERIES_A, ASSET), 60);
        assertEq(ledger.reservedFor(SERIES_B, ASSET), 0);

        ledger.reserve(SERIES_B, ASSET, 40);

        assertEq(ledger.balance(ASSET), 100);
        assertEq(ledger.totalReserved(ASSET), 100);
        assertEq(ledger.available(ASSET), 0);
        assertEq(ledger.reservedFor(SERIES_A, ASSET), 60);
        assertEq(ledger.reservedFor(SERIES_B, ASSET), 40);

        emit log_string("classification: existing_rule");
        emit log_string("balance_after: 100");
        emit log_string("reserved_after: 100");
        emit log_string("available_after: 0");
        emit log_string("series_a_after: 60");
        emit log_string("series_b_after: 40");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidateReservationLedger} from "../../src/prism/CandidateReservationLedger.sol";

/// @notice Series A reserves 60, then series A reserves 40, against balance 100.
/// @dev Reserve is not edited. No release and no withdraw. The failing reserve of 50
///      and a second series reserving 40 are not repeated.
contract SameSeriesReserveTest is Test {
    bytes32 internal constant ASSET = bytes32(uint256(1));
    bytes32 internal constant SERIES_A = bytes32(uint256(1));

    function test_same_series_reserves_the_remainder() public {
        CandidateReservationLedger ledger = new CandidateReservationLedger();
        ledger.deposit(ASSET, 100);
        ledger.reserve(SERIES_A, ASSET, 60);

        assertEq(ledger.balance(ASSET), 100);
        assertEq(ledger.totalReserved(ASSET), 60);
        assertEq(ledger.available(ASSET), 40);
        assertEq(ledger.reservedFor(SERIES_A, ASSET), 60);

        ledger.reserve(SERIES_A, ASSET, 40);

        assertEq(ledger.balance(ASSET), 100);
        assertEq(ledger.totalReserved(ASSET), 100);
        assertEq(ledger.available(ASSET), 0);
        assertEq(ledger.reservedFor(SERIES_A, ASSET), 100);

        emit log_string("classification: existing_rule");
        emit log_string("balance_after: 100");
        emit log_string("reserved_after: 100");
        emit log_string("available_after: 0");
        emit log_string("series_a_after: 100");
    }
}

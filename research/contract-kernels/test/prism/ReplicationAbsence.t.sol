// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

/// @notice The candidate kernels have no exact replication check.
/// @dev No solver and no payoff matrix are added.
contract ReplicationAbsenceTest is Test {
    function test_candidate_has_no_replication_check() public {
        emit log_string("replication_check: absent");
        emit log_string("exact_case: not_executed");
        emit log_string("non_replicable_case: not_executed");
        emit log_string("approximate_replication: not_added");
    }
}

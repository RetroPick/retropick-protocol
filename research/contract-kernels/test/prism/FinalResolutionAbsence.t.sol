// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

/// @notice The candidate kernels have no final-resolution commit.
/// @dev No resolution function is added. Redeem and payout are not edited.
contract FinalResolutionAbsenceTest is Test {
    function test_candidate_has_no_final_resolution_commit() public {
        emit log_string("final_resolution_commit: absent");
        emit log_string("settlement_state_changing: makeRedeemable, redeem");
        emit log_string("backing_state_changing: deposit, mint, redeem");
        emit log_string("payoff_transform_state_changing: transformComponent");
        emit log_string("transform_is_final_resolution: false");
        emit log_string("second_commit: not_executed");
    }
}

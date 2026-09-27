// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidatePayoffTransform} from "../../src/prism/CandidatePayoffTransform.sol";

/// @notice Index 2 with payout 1 on the fresh two-component fixture.
/// @dev No successful transform runs first. transformComponent is not edited.
contract OutOfRangeComponentTransformTest is Test {
    function test_index_two_on_the_fresh_fixture() public {
        CandidatePayoffTransform book = _book();
        emit log_named_uint("backing0_before", book.backing(0));
        emit log_named_uint("backing1_before", book.backing(1));
        emit log_named_uint("transformed_before", book.transformed());
        emit log_named_uint("possible_mask_before", book.possibleMask());
        emit log_named_uint("resolved_mask_before", book.resolvedMask());

        vm.expectRevert(abi.encodeWithSelector(CandidatePayoffTransform.BadComponent.selector, uint256(2)));
        book.transformComponent(2, 1);

        emit log_string("call: rejected");
        emit log_string("error: BadComponent(2)");
        emit log_named_uint("backing0_after", book.backing(0));
        emit log_named_uint("backing1_after", book.backing(1));
        emit log_named_uint("transformed_after", book.transformed());
        emit log_named_uint("possible_mask_after", book.possibleMask());
        emit log_named_uint("resolved_mask_after", book.resolvedMask());
        emit log_named_uint("supply_after", book.supplyUnits());
        emit log_string("classification: existing_rule");

        assertEq(book.supplyUnits(), 1000);
        assertEq(book.backing(0), 600);
        assertEq(book.backing(1), 400);
        assertEq(book.transformed(), 0);
        assertEq(book.possibleMask(), 15);
        assertEq(book.resolvedMask(), 0);
    }

    function _book() internal returns (CandidatePayoffTransform) {
        uint256[] memory payoff = new uint256[](8);
        payoff[1] = 1;
        payoff[4] = 1;
        payoff[5] = 1;
        payoff[6] = 1;
        uint256[] memory weights = new uint256[](2);
        weights[0] = 600000000000000000;
        weights[1] = 400000000000000000;
        uint256[] memory backing_ = new uint256[](2);
        backing_[0] = 600;
        backing_[1] = 400;
        return new CandidatePayoffTransform(payoff, 4, weights, backing_, 1000);
    }
}

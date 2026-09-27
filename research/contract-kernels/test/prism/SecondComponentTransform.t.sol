// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidatePayoffTransform} from "../../src/prism/CandidatePayoffTransform.sol";

/// @notice One accepted transform of component 1, then the same index again.
/// @dev Uses the fixture payoff already accepted by CandidatePayoffTransform.t.sol.
///      transformComponent is not edited.
contract SecondComponentTransformTest is Test {
    function test_second_transform_of_the_same_component() public {
        CandidatePayoffTransform book = _book();
        uint256 cash = book.transformComponent(1, 1);
        emit log_named_uint("first_cash_added", cash);
        emit log_named_uint("supply_after_first", book.supplyUnits());
        emit log_named_uint("backing0_after_first", book.backing(0));
        emit log_named_uint("backing1_after_first", book.backing(1));
        emit log_named_uint("transformed_after_first", book.transformed());
        emit log_named_uint("possible_mask_after_first", book.possibleMask());
        emit log_named_uint("resolved_mask_after_first", book.resolvedMask());

        vm.expectRevert(abi.encodeWithSelector(CandidatePayoffTransform.AlreadyResolved.selector, uint256(1)));
        book.transformComponent(1, 1);

        emit log_string("second_call: rejected");
        emit log_string("second_error: AlreadyResolved(1)");
        emit log_named_uint("supply_after_second", book.supplyUnits());
        emit log_named_uint("backing0_after_second", book.backing(0));
        emit log_named_uint("backing1_after_second", book.backing(1));
        emit log_named_uint("transformed_after_second", book.transformed());
        emit log_named_uint("possible_mask_after_second", book.possibleMask());
        emit log_named_uint("resolved_mask_after_second", book.resolvedMask());
        emit log_string("classification: existing_rule");

        assertEq(cash, 400);
        assertEq(book.supplyUnits(), 1000);
        assertEq(book.backing(0), 600);
        assertEq(book.backing(1), 0);
        assertEq(book.transformed(), 400);
        assertEq(book.possibleMask(), 5);
        assertEq(book.resolvedMask(), 2);
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

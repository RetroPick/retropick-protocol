// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice Holder A redeems 1, then holder B redeems 1.
/// @dev Redeem and the payout formula are not edited. This is not the one-holder sequence.
contract TwoHolderRedeemsTest is Test {
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function test_later_holder_receives_the_unit() public {
        MockCollateral token = new MockCollateral(18);
        CandidateCumulativeSettlement book = _opened(token);

        vm.prank(alice);
        uint256 payoutA = book.redeem(1);
        assertEq(payoutA, 0);
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.balanceOf(address(book)), 2);
        assertEq(book.paidRaw(), 0);

        vm.prank(bob);
        uint256 payoutB = book.redeem(1);
        assertEq(payoutB, 1);
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), 1);
        assertEq(token.balanceOf(address(book)), 1);
        assertEq(book.paidRaw(), 1);

        emit log_string("classification: cumulative_floor_match");
        emit log_string("payout_a: 0");
        emit log_string("payout_b: 1");
        emit log_string("alice_after_first: 0");
        emit log_string("bob_after_first: 0");
        emit log_string("kernel_after_first: 2");
        emit log_string("paid_raw_after_first: 0");
        emit log_string("alice_after_second: 0");
        emit log_string("bob_after_second: 1");
        emit log_string("kernel_after_second: 1");
        emit log_string("paid_raw_after_second: 1");
        emit log_string("unit_goes_to_later_redeem: true");
    }

    function _opened(MockCollateral token) internal returns (CandidateCumulativeSettlement book) {
        address[] memory holders = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        holders[0] = alice;
        holders[1] = bob;
        amounts[0] = 1;
        amounts[1] = 1;
        book = new CandidateCumulativeSettlement(address(token), 10 ** 18 - 1, 18, holders, amounts);
        assertEq(book.supplyUnits(), 2);
        assertEq(book.ceilFunding(), 2);
        token.mint(address(this), 2);
        assertTrue(token.transfer(address(book), 2));
        book.makeRedeemable();
    }
}

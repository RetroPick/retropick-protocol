// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice One holder redeems 1, then 1. Redeem and the payout formula are not edited.
/// @dev Supply 2, payout 10^18-1, decimals 18, ceil funding 2.
contract TwoUnitRedeemsTest is Test {
    address internal holder = address(0xA11CE);

    function test_two_redeems_of_one_pay_zero_then_one() public {
        MockCollateral token = new MockCollateral(18);
        CandidateCumulativeSettlement book = _opened(token);

        vm.prank(holder);
        uint256 firstPayout = book.redeem(1);
        assertEq(firstPayout, 0);
        assertEq(book.paidRaw(), 0);
        assertEq(token.balanceOf(holder), 0);
        assertEq(token.balanceOf(address(book)), 2);
        assertEq(book.balances(holder), 1);

        vm.prank(holder);
        uint256 secondPayout = book.redeem(1);
        assertEq(secondPayout, 1);
        assertEq(book.paidRaw(), 1);
        assertEq(token.balanceOf(holder), 1);
        assertEq(token.balanceOf(address(book)), 1);
        assertEq(book.balances(holder), 0);

        emit log_string("classification: cumulative_floor_match");
        emit log_string("first_payout: 0");
        emit log_string("second_payout: 1");
        emit log_string("paid_raw_after_first: 0");
        emit log_string("paid_raw_after_second: 1");
        emit log_string("holder_token_after_first: 0");
        emit log_string("holder_token_after_second: 1");
        emit log_string("kernel_after_first: 2");
        emit log_string("kernel_after_second: 1");
    }

    function _opened(MockCollateral token) internal returns (CandidateCumulativeSettlement book) {
        address[] memory holders = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        holders[0] = holder;
        amounts[0] = 2;
        book = new CandidateCumulativeSettlement(address(token), 10 ** 18 - 1, 18, holders, amounts);
        token.mint(address(this), 2);
        assertTrue(token.transfer(address(book), 2));
        book.makeRedeemable();
        assertEq(book.ceilFunding(), 2);
        assertEq(book.supplyUnits(), 2);
    }
}

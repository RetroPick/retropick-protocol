// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice Observe the existing zero-supply residual. This test does not add a sweep.
contract CandidateZeroSupplyDustTest is Test {
    function test_constructor_reverts_when_supply_is_zero() public {
        MockCollateral token = new MockCollateral(18);
        address[] memory holders = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        vm.expectRevert(CandidateCumulativeSettlement.ZeroSupply.selector);
        new CandidateCumulativeSettlement(address(token), 10 ** 18 - 1, 18, holders, amounts);
    }

    function test_exact_ceil_residual_sits_after_supply_reaches_zero() public {
        (MockCollateral token, CandidateCumulativeSettlement book, address[] memory holders) = _open(10 ** 18 - 1, 2);
        vm.prank(holders[0]);
        assertEq(book.redeem(1), 0);
        vm.prank(holders[1]);
        assertEq(book.redeem(1), 1);
        assertEq(book.supplyUnits(), 0);
        assertEq(book.paidRaw(), 1);
        assertEq(token.balanceOf(address(book)), 1);
        _rejectedOneUnit(book, holders[0]);
        assertEq(token.balanceOf(address(book)), 1);
        book.makeRedeemable();
        assertEq(token.balanceOf(address(book)), 1);
    }

    function test_zero_payout_leaves_a_zero_balance() public {
        (MockCollateral token, CandidateCumulativeSettlement book, address[] memory holders) = _open(0, 0);
        vm.prank(holders[0]);
        assertEq(book.redeem(1), 0);
        vm.prank(holders[1]);
        assertEq(book.redeem(1), 0);
        assertEq(book.supplyUnits(), 0);
        assertEq(token.balanceOf(address(book)), 0);
        _rejectedOneUnit(book, holders[0]);
        assertEq(token.balanceOf(address(book)), 0);
    }

    function test_surplus_above_ceil_also_sits() public {
        (MockCollateral token, CandidateCumulativeSettlement book, address[] memory holders) = _open(10 ** 18 - 1, 5);
        vm.prank(holders[0]);
        assertEq(book.redeem(1), 0);
        vm.prank(holders[1]);
        assertEq(book.redeem(1), 1);
        assertEq(token.balanceOf(address(book)), 4);
        _rejectedOneUnit(book, holders[1]);
        assertEq(token.balanceOf(address(book)), 4);
    }

    function _open(uint256 payoutWad, uint256 funding)
        private
        returns (MockCollateral token, CandidateCumulativeSettlement book, address[] memory holders)
    {
        token = new MockCollateral(18);
        uint256[] memory amounts;
        (holders, amounts) = _pair();
        book = new CandidateCumulativeSettlement(address(token), payoutWad, 18, holders, amounts);
        token.mint(address(book), funding);
        book.makeRedeemable();
    }

    function _rejectedOneUnit(CandidateCumulativeSettlement book, address holder) private {
        vm.prank(holder);
        vm.expectRevert(abi.encodeWithSelector(CandidateCumulativeSettlement.InvalidQuantity.selector, 1, 0));
        book.redeem(1);
    }

    function _pair() private pure returns (address[] memory holders, uint256[] memory amounts) {
        holders = new address[](2);
        amounts = new uint256[](2);
        holders[0] = address(0xA0);
        holders[1] = address(0xA1);
        amounts[0] = 1;
        amounts[1] = 1;
    }
}

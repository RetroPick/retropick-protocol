// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Decimals 6 and 18. Mint 2, redeem 1, then redeem the remaining 1.
/// @dev requiredRaw is read from the kernel. Mint, redeem, and payout are not edited.
contract MixedDecimalSecondRedeemTest is Test {
    uint256 internal constant WEIGHT = 10 ** 30 + 1;

    address internal alice = address(0xA11CE);

    function test_mixed_decimals_second_redeem() public {
        MockCollateral first = new MockCollateral(6);
        MockCollateral second = new MockCollateral(18);
        CandidateComponentBacking book = _book(first, second);

        uint256[] memory required = book.requiredRaw(2);
        emit log_string("constructor_rejected: false");
        emit log_named_uint("required_supply_2_0", required[0]);
        emit log_named_uint("required_supply_2_1", required[1]);

        first.mint(alice, required[0]);
        second.mint(alice, required[1]);
        vm.startPrank(alice);
        first.approve(address(book), required[0]);
        second.approve(address(book), required[1]);
        book.deposit(required);
        book.mint(2);
        uint256[] memory firstPaid = book.redeem(1);
        _emitBefore(book);
        uint256[] memory secondPaid = book.redeem(1);
        vm.stopPrank();

        uint256 supplyAfter = book.supplyUnits();
        uint256[] memory requiredAfter = book.requiredRaw(supplyAfter);
        emit log_named_uint("first_paid_0", firstPaid[0]);
        emit log_named_uint("first_paid_1", firstPaid[1]);
        emit log_named_uint("second_paid_0", secondPaid[0]);
        emit log_named_uint("second_paid_1", secondPaid[1]);
        emit log_named_uint("supply_after", supplyAfter);
        emit log_named_uint("backing_after_0", book.backingRaw(0));
        emit log_named_uint("backing_after_1", book.backingRaw(1));
        emit log_named_uint("required_after_0", requiredAfter[0]);
        emit log_named_uint("required_after_1", requiredAfter[1]);
        emit log_named_uint("kernel_balance_0", first.balanceOf(address(book)));
        emit log_named_uint("kernel_balance_1", second.balanceOf(address(book)));
        emit log_named_uint("series_balance", book.balanceOf(alice));
        emit log_string("classification: existing_rule");
        emit log_string("kuru_decimals_18: not_established");
        emit log_string("sweep_policy: NOT_YET_VALIDATED");

        assertEq(required[0], 3);
        assertEq(required[1], 2000000000001);
        assertEq(firstPaid[0], 1);
        assertEq(firstPaid[1], 1000000000000);
        assertEq(secondPaid[0], 2);
        assertEq(secondPaid[1], 1000000000001);
        assertEq(supplyAfter, 0);
        assertEq(book.backingRaw(0), 0);
        assertEq(book.backingRaw(1), 0);
        assertEq(requiredAfter[0], 0);
        assertEq(requiredAfter[1], 0);
        assertEq(first.balanceOf(address(book)), 0);
        assertEq(second.balanceOf(address(book)), 0);
        assertEq(book.balanceOf(alice), 0);
        assertGe(book.backingRaw(0), requiredAfter[0]);
        assertGe(book.backingRaw(1), requiredAfter[1]);
    }

    function _book(MockCollateral first, MockCollateral second) internal returns (CandidateComponentBacking) {
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        uint8[] memory decimals_ = new uint8[](2);
        tokens[0] = address(first);
        tokens[1] = address(second);
        weights[0] = WEIGHT;
        weights[1] = WEIGHT;
        decimals_[0] = 6;
        decimals_[1] = 18;
        return new CandidateComponentBacking(tokens, weights, decimals_);
    }

    function _emitBefore(CandidateComponentBacking book) internal {
        uint256 supply = book.supplyUnits();
        uint256[] memory required = book.requiredRaw(supply);
        emit log_named_uint("supply_before", supply);
        emit log_named_uint("backing_before_0", book.backingRaw(0));
        emit log_named_uint("backing_before_1", book.backingRaw(1));
        emit log_named_uint("required_before_0", required[0]);
        emit log_named_uint("required_before_1", required[1]);
    }
}

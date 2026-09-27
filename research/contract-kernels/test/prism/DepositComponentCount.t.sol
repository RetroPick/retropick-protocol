// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice One deposit walks the two constructor components and no further slot.
/// @dev Weights are 0, the smallest value the constructor accepts. Deposit is not edited.
contract DepositComponentCountTest is Test {
    function test_deposit_credits_only_the_constructor_slots() public {
        MockCollateral first = new MockCollateral(18);
        MockCollateral second = new MockCollateral(18);
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        uint8[] memory decimals_ = new uint8[](2);
        tokens[0] = address(first);
        tokens[1] = address(second);
        weights[0] = 0;
        weights[1] = 0;
        decimals_[0] = 18;
        decimals_[1] = 18;

        CandidateComponentBacking book = new CandidateComponentBacking(tokens, weights, decimals_);
        assertEq(book.componentCount(), 2);
        assertEq(book.backingRaw(0), 0);
        assertEq(book.backingRaw(1), 0);
        assertFalse(_slotReadable(book, 2));

        first.mint(address(this), 1);
        second.mint(address(this), 1);
        assertEq(first.balanceOf(address(this)), 1);
        assertEq(second.balanceOf(address(this)), 1);
        assertEq(first.balanceOf(address(book)), 0);
        assertEq(second.balanceOf(address(book)), 0);
        first.approve(address(book), 1);
        second.approve(address(book), 1);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        book.deposit(amounts);

        assertEq(book.componentCount(), 2);
        assertEq(book.backingRaw(0), 1);
        assertEq(book.backingRaw(1), 1);
        assertEq(first.balanceOf(address(book)), 1);
        assertEq(second.balanceOf(address(book)), 1);
        assertEq(first.balanceOf(address(this)), 0);
        assertEq(second.balanceOf(address(this)), 0);
        assertFalse(_slotReadable(book, 2));

        emit log_string("classification: bounded_by_constructor");
        emit log_named_uint("component_count", book.componentCount());
        emit log_named_uint("backing_raw_0", book.backingRaw(0));
        emit log_named_uint("backing_raw_1", book.backingRaw(1));
    }

    function _slotReadable(CandidateComponentBacking book, uint256 index) internal returns (bool) {
        (bool ok,) = address(book).call(abi.encodeWithSignature("backingRaw(uint256)", index));
        return ok;
    }
}

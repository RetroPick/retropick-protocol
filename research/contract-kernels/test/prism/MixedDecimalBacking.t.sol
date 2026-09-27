// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Decimals 6 and 18. Weights are 10^30+1 and 10^30+1.
/// @dev requiredRaw is read from the kernel. The requirement formula is not edited.
contract MixedDecimalBackingTest is Test {
    uint256 internal constant WEIGHT = 10 ** 30 + 1;

    address internal alice = address(0xA11CE);

    function test_mixed_decimals_mint_one_redeem_one() public {
        MockCollateral first = new MockCollateral(6);
        MockCollateral second = new MockCollateral(18);
        CandidateComponentBacking book = _book(first, second);
        assertEq(book.componentDecimals(0), 6);
        assertEq(book.componentDecimals(1), 18);
        assertEq(book.weightWad(0), WEIGHT);
        assertEq(book.weightWad(1), WEIGHT);

        uint256[] memory required = book.requiredRaw(1);
        emit log_string("constructor_rejected: false");
        emit log_named_uint("required_0", required[0]);
        emit log_named_uint("required_1", required[1]);

        first.mint(alice, required[0]);
        second.mint(alice, required[1]);
        vm.startPrank(alice);
        first.approve(address(book), required[0]);
        second.approve(address(book), required[1]);
        book.deposit(required);
        book.mint(1);
        uint256 backingBefore0 = book.backingRaw(0);
        uint256 backingBefore1 = book.backingRaw(1);
        assertEq(book.supplyUnits(), 1);
        uint256[] memory released = book.redeem(1);
        vm.stopPrank();

        uint256[] memory requiredAfter = book.requiredRaw(book.supplyUnits());
        assertEq(required[0], 2);
        assertEq(required[1], 1000000000001);
        assertEq(released[0], 2);
        assertEq(released[1], 1000000000001);
        assertEq(book.supplyUnits(), 0);
        assertEq(book.backingRaw(0), 0);
        assertEq(book.backingRaw(1), 0);
        assertEq(requiredAfter[0], 0);
        assertEq(requiredAfter[1], 0);
        assertGe(book.backingRaw(0), requiredAfter[0]);
        assertGe(book.backingRaw(1), requiredAfter[1]);

        emit log_named_uint("paid_0", released[0]);
        emit log_named_uint("paid_1", released[1]);
        emit log_named_uint("supply_before", 1);
        emit log_named_uint("supply_after", book.supplyUnits());
        emit log_named_uint("backing_before_0", backingBefore0);
        emit log_named_uint("backing_before_1", backingBefore1);
        emit log_named_uint("backing_after_0", book.backingRaw(0));
        emit log_named_uint("backing_after_1", book.backingRaw(1));
        emit log_string("classification: existing_rule");
        emit log_string("kuru_decimals_18: not_established");
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
}

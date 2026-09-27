// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Decimals 6 and 6. Weights are 10^30+1 and 10^30+1.
/// @dev requiredRaw is read from the kernel. The requirement formula is not edited.
contract SixDecimalIndivisibleWeightTest is Test {
    uint256 internal constant WEIGHT = 10 ** 30 + 1;

    address internal alice = address(0xA11CE);

    function test_ceiling_when_weight_does_not_divide_the_scale() public {
        MockCollateral first = new MockCollateral(6);
        MockCollateral second = new MockCollateral(6);
        CandidateComponentBacking book = _book(first, second);
        assertEq(book.componentDecimals(0), 6);
        assertEq(book.componentDecimals(1), 6);
        assertEq(book.weightWad(0), WEIGHT);
        assertEq(book.weightWad(1), WEIGHT);

        uint256[] memory atSupply2 = book.requiredRaw(2);
        uint256[] memory atSupply1 = book.requiredRaw(1);
        emit log_string("constructor_rejected: false");
        emit log_named_uint("required_supply_2_0", atSupply2[0]);
        emit log_named_uint("required_supply_2_1", atSupply2[1]);
        emit log_named_uint("required_supply_1_0", atSupply1[0]);
        emit log_named_uint("required_supply_1_1", atSupply1[1]);

        first.mint(alice, atSupply2[0]);
        second.mint(alice, atSupply2[1]);
        vm.startPrank(alice);
        first.approve(address(book), atSupply2[0]);
        second.approve(address(book), atSupply2[1]);
        book.deposit(atSupply2);
        book.mint(2);
        _emitState("before", book);
        uint256[] memory released = book.redeem(1);
        vm.stopPrank();
        emit log_named_uint("paid_0", released[0]);
        emit log_named_uint("paid_1", released[1]);
        _emitState("after", book);

        assertEq(atSupply2[0], 3);
        assertEq(atSupply2[1], 3);
        assertEq(atSupply1[0], 2);
        assertEq(atSupply1[1], 2);
        assertEq(released[0], 1);
        assertEq(released[1], 1);
        assertEq(book.supplyUnits(), 1);
        assertEq(book.backingRaw(0), 2);
        assertEq(book.backingRaw(1), 2);
        uint256[] memory requiredAfter = book.requiredRaw(book.supplyUnits());
        assertEq(requiredAfter[0], 2);
        assertEq(requiredAfter[1], 2);
        assertGe(book.backingRaw(0), requiredAfter[0]);
        assertGe(book.backingRaw(1), requiredAfter[1]);
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
        decimals_[1] = 6;
        return new CandidateComponentBacking(tokens, weights, decimals_);
    }

    function _emitState(string memory tag, CandidateComponentBacking book) internal {
        uint256 supply = book.supplyUnits();
        uint256[] memory required = book.requiredRaw(supply);
        emit log_string(tag);
        emit log_named_uint("supply", supply);
        emit log_named_uint("backing0", book.backingRaw(0));
        emit log_named_uint("backing1", book.backingRaw(1));
        emit log_named_uint("required0", required[0]);
        emit log_named_uint("required1", required[1]);
    }
}

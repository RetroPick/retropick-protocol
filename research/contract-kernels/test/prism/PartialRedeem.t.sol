// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice The minter calls redeem(1) after mint(2) at wad weights.
/// @dev Redeem, mint, and the backing formula are not edited.
contract PartialRedeemTest is Test {
    uint256 internal constant WAD = 10 ** 18;

    address internal alice = address(0xA11CE);

    function test_minter_redeems_one_of_two() public {
        MockCollateral first = new MockCollateral(18);
        MockCollateral second = new MockCollateral(18);
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        uint8[] memory decimals_ = new uint8[](2);
        tokens[0] = address(first);
        tokens[1] = address(second);
        weights[0] = WAD;
        weights[1] = WAD;
        decimals_[0] = 18;
        decimals_[1] = 18;

        CandidateComponentBacking book = new CandidateComponentBacking(tokens, weights, decimals_);

        first.mint(alice, 2);
        second.mint(alice, 2);
        vm.startPrank(alice);
        first.approve(address(book), 2);
        second.approve(address(book), 2);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2;
        amounts[1] = 2;
        book.deposit(amounts);
        book.mint(2);

        assertEq(book.supplyUnits(), 2);
        assertEq(book.backingRaw(0), 2);
        assertEq(book.backingRaw(1), 2);
        assertEq(book.balanceOf(alice), 2);
        uint256[] memory requiredBefore = book.requiredRaw(book.supplyUnits());
        assertEq(requiredBefore[0], 2);
        assertEq(requiredBefore[1], 2);
        assertEq(first.balanceOf(alice), 0);
        assertEq(second.balanceOf(alice), 0);

        uint256[] memory released = book.redeem(1);
        vm.stopPrank();

        assertEq(released[0], 1);
        assertEq(released[1], 1);
        assertEq(book.supplyUnits(), 1);
        assertEq(book.backingRaw(0), 1);
        assertEq(book.backingRaw(1), 1);
        assertEq(book.balanceOf(alice), 1);
        uint256[] memory requiredAfter = book.requiredRaw(book.supplyUnits());
        assertEq(requiredAfter[0], 1);
        assertEq(requiredAfter[1], 1);
        assertEq(first.balanceOf(alice), 1);
        assertEq(second.balanceOf(alice), 1);
        assertGe(book.backingRaw(0), requiredAfter[0]);
        assertGe(book.backingRaw(1), requiredAfter[1]);

        emit log_string("classification: existing_rule");
        emit log_string("solidity_rejected: false");
        emit log_string("component_tokens_paid: 1,1");
        emit log_string("supply_before: 2");
        emit log_string("supply_after: 1");
        emit log_string("backing_raw_before: 2,2");
        emit log_string("backing_raw_after: 1,1");
        emit log_string("required_raw_before: 2,2");
        emit log_string("required_raw_after: 1,1");
        emit log_string("series_balance_before: 2");
        emit log_string("series_balance_after: 1");
        emit log_string("caller_component_balances_before: 0,0");
        emit log_string("caller_component_balances_after: 1,1");
    }
}

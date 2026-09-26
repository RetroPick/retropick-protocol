// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Account B mints after account A deposits. Mint is not edited.
/// @dev Weights and decimals match the deposit-count witness: 0, 0 and 18, 18.
contract NonDepositorMintTest is Test {
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function test_non_depositor_mints_the_largest_backed_quantity() public {
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

        first.mint(alice, 1);
        second.mint(alice, 1);
        vm.startPrank(alice);
        first.approve(address(book), 1);
        second.approve(address(book), 1);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        book.deposit(amounts);
        vm.stopPrank();

        assertEq(book.supplyUnits(), 0);
        assertEq(first.balanceOf(alice), 0);
        assertEq(second.balanceOf(alice), 0);
        assertEq(book.balanceOf(bob), 0);
        assertEq(book.backingRaw(0), 1);
        assertEq(book.backingRaw(1), 1);
        _assertRequirementIsZero(book, type(uint256).max);

        vm.prank(bob);
        book.mint(type(uint256).max);

        assertEq(book.supplyUnits(), type(uint256).max);
        assertEq(first.balanceOf(alice), 0);
        assertEq(second.balanceOf(alice), 0);
        assertEq(book.balanceOf(bob), type(uint256).max);
        assertEq(book.balanceOf(alice), 0);
        assertEq(book.backingRaw(0), 1);
        assertEq(book.backingRaw(1), 1);
        _assertRequirementIsZero(book, book.supplyUnits());

        emit log_string("classification: permissionless_mint");
        emit log_string("supply_before: 0");
        emit log_string("backing_raw_before: 1,1");
        emit log_string("alice_component_balances_before: 0,0");
        emit log_string("bob_series_before: 0");
        emit log_string("supply_after: uint256 max");
        emit log_string("backing_raw_after: 1,1");
        emit log_string("alice_component_balances_after: 0,0");
        emit log_string("bob_received_series: true");
    }

    function _assertRequirementIsZero(CandidateComponentBacking book, uint256 supply_) internal view {
        uint256[] memory requirement = book.requiredRaw(supply_);
        assertEq(requirement[0], 0);
        assertEq(requirement[1], 0);
        assertGe(book.backingRaw(0), requirement[0]);
        assertGe(book.backingRaw(1), requirement[1]);
    }
}

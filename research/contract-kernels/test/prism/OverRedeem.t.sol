// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice The minter calls redeem(2) after mint(1) at wad weights.
/// @dev Redeem, mint, and the backing formula are not edited.
contract OverRedeemTest is Test {
    uint256 internal constant WAD = 10 ** 18;

    address internal alice = address(0xA11CE);

    function test_minter_redeem_of_two_reverts() public {
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

        first.mint(alice, 1);
        second.mint(alice, 1);
        vm.startPrank(alice);
        first.approve(address(book), 1);
        second.approve(address(book), 1);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        book.deposit(amounts);
        book.mint(1);
        vm.stopPrank();

        assertEq(book.supplyUnits(), 1);
        assertEq(book.backingRaw(0), 1);
        assertEq(book.backingRaw(1), 1);
        assertEq(book.balanceOf(alice), 1);
        uint256[] memory requiredBefore = book.requiredRaw(book.supplyUnits());
        assertEq(requiredBefore[0], 1);
        assertEq(requiredBefore[1], 1);

        vm.expectRevert(abi.encodeWithSelector(CandidateComponentBacking.InvalidQuantity.selector, 2, 1));
        vm.prank(alice);
        book.redeem(2);

        assertEq(book.supplyUnits(), 1);
        assertEq(book.backingRaw(0), 1);
        assertEq(book.backingRaw(1), 1);
        assertEq(book.balanceOf(alice), 1);
        uint256[] memory requiredAfter = book.requiredRaw(book.supplyUnits());
        assertEq(requiredAfter[0], 1);
        assertEq(requiredAfter[1], 1);

        emit log_string("classification: existing_rule");
        emit log_string("solidity_rejected: true");
        emit log_string("error: InvalidQuantity(2, 1)");
        emit log_string("supply_after: 1");
        emit log_string("backing_raw_after: 1,1");
        emit log_string("required_raw_at_supply_1: 1,1");
        emit log_string("series_balance_before: 1");
        emit log_string("series_balance_after: 1");
    }
}

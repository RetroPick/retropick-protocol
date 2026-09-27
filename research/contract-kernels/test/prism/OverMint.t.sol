// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Account B calls mint(2) after a deposit of 1 and 1 at wad weights.
/// @dev Mint and the weight formula are not edited.
contract OverMintTest is Test {
    uint256 internal constant WAD = 10 ** 18;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function test_non_depositor_mint_of_two_reverts() public {
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
        vm.stopPrank();

        assertEq(book.supplyUnits(), 0);
        assertEq(book.backingRaw(0), 1);
        assertEq(book.backingRaw(1), 1);
        assertEq(book.balanceOf(bob), 0);
        _assertRequiredAtSupplyTwo(book);

        vm.expectRevert(abi.encodeWithSelector(CandidateComponentBacking.InsufficientBacking.selector, 0, 1, 2));
        vm.prank(bob);
        book.mint(2);

        assertEq(book.supplyUnits(), 0);
        assertEq(book.backingRaw(0), 1);
        assertEq(book.backingRaw(1), 1);
        assertEq(book.balanceOf(bob), 0);
        _assertRequiredAtSupplyTwo(book);

        emit log_string("classification: existing_rule");
        emit log_string("error: InsufficientBacking(0, 1, 2)");
        emit log_string("supply_before: 0");
        emit log_string("supply_after: 0");
        emit log_string("backing_raw_before: 1,1");
        emit log_string("backing_raw_after: 1,1");
        emit log_string("required_raw_at_supply_2: 2,2");
        emit log_string("bob_received_series: false");
    }

    function _assertRequiredAtSupplyTwo(CandidateComponentBacking book) internal view {
        uint256[] memory requirement = book.requiredRaw(2);
        assertEq(requirement[0], 2);
        assertEq(requirement[1], 2);
    }
}

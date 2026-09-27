// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Account B mints 1 after account A deposits at wad weights.
/// @dev Mint and the weight formula are not edited. This is not the zero-weight case.
contract PositiveWeightNonDepositorMintTest is Test {
    uint256 internal constant WAD = 10 ** 18;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function test_non_depositor_mints_one_against_wad_weights() public {
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
        _assertRequiredAtSupplyOne(book);

        vm.prank(bob);
        book.mint(1);

        assertEq(book.supplyUnits(), 1);
        assertEq(book.backingRaw(0), 1);
        assertEq(book.backingRaw(1), 1);
        assertEq(book.balanceOf(bob), 1);
        assertEq(book.balanceOf(alice), 0);
        _assertRequiredAtSupplyOne(book);

        emit log_string("classification: permissionless_mint");
        emit log_string("supply_before: 0");
        emit log_string("supply_after: 1");
        emit log_string("backing_raw_before: 1,1");
        emit log_string("backing_raw_after: 1,1");
        emit log_string("required_raw_at_supply_1: 1,1");
        emit log_string("bob_series_before: 0");
        emit log_string("bob_received_series: true");
    }

    function _assertRequiredAtSupplyOne(CandidateComponentBacking book) internal view {
        uint256[] memory requirement = book.requiredRaw(1);
        assertEq(requirement[0], 1);
        assertEq(requirement[1], 1);
        assertGe(book.backingRaw(0), requirement[0]);
        assertGe(book.backingRaw(1), requirement[1]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Account B redeems 1 after minting 1 against account A's deposit.
/// @dev Redeem is not edited. Weights are 10^18 and 10^18. Decimals are 18.
contract NonDepositorRedeemTest is Test {
    uint256 internal constant WAD = 10 ** 18;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function test_non_depositor_redeem_sends_components_to_caller() public {
        MockCollateral first = new MockCollateral(18);
        MockCollateral second = new MockCollateral(18);
        CandidateComponentBacking book = _book(first, second);
        _deposit(first, second, book);

        vm.prank(bob);
        book.mint(1);
        _assertPostMint(first, second, book);

        vm.prank(bob);
        book.redeem(1);

        assertEq(book.supplyUnits(), 0);
        assertEq(book.backingRaw(0), 0);
        assertEq(book.backingRaw(1), 0);
        assertEq(first.balanceOf(alice), 0);
        assertEq(second.balanceOf(alice), 0);
        assertEq(first.balanceOf(bob), 1);
        assertEq(second.balanceOf(bob), 1);
        assertEq(book.balanceOf(bob), 0);
        _assertRequired(book, 0, 0);

        emit log_string("classification: redeem_pays_caller");
        emit log_string("supply_before_redeem: 1");
        emit log_string("supply_after_redeem: 0");
        emit log_string("backing_raw_before_redeem: 1,1");
        emit log_string("backing_raw_after_redeem: 0,0");
        emit log_string("required_raw_before_redeem: 1,1");
        emit log_string("required_raw_after_redeem: 0,0");
        emit log_string("alice_components_after: 0,0");
        emit log_string("bob_components_after: 1,1");
        emit log_string("bob_series_after: 0");
    }

    function _book(MockCollateral first, MockCollateral second) internal returns (CandidateComponentBacking book) {
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        uint8[] memory decimals_ = new uint8[](2);
        tokens[0] = address(first);
        tokens[1] = address(second);
        weights[0] = WAD;
        weights[1] = WAD;
        decimals_[0] = 18;
        decimals_[1] = 18;
        book = new CandidateComponentBacking(tokens, weights, decimals_);
    }

    function _deposit(MockCollateral first, MockCollateral second, CandidateComponentBacking book) internal {
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
    }

    function _assertPostMint(MockCollateral first, MockCollateral second, CandidateComponentBacking book) internal view {
        assertEq(book.supplyUnits(), 1);
        assertEq(book.backingRaw(0), 1);
        assertEq(book.backingRaw(1), 1);
        assertEq(first.balanceOf(alice), 0);
        assertEq(second.balanceOf(alice), 0);
        assertEq(first.balanceOf(bob), 0);
        assertEq(second.balanceOf(bob), 0);
        assertEq(book.balanceOf(bob), 1);
        _assertRequired(book, 1, 1);
    }

    function _assertRequired(CandidateComponentBacking book, uint256 supply_, uint256 each) internal view {
        uint256[] memory requirement = book.requiredRaw(supply_);
        assertEq(requirement[0], each);
        assertEq(requirement[1], each);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice A deposits 3 and 3, A mints 1, B mints 1, then B redeems before A.
/// @dev Weights are 10^18+1 and 10^18+1. Redeem, mint, transfer, and backing are not edited.
contract IndivisibleWeightReverseRedeemTest is Test {
    uint256 internal constant WAD = 10 ** 18;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function test_b_redeems_before_a() public {
        MockCollateral first = new MockCollateral(18);
        MockCollateral second = new MockCollateral(18);
        CandidateComponentBacking book = _book(first, second);

        first.mint(alice, 3);
        second.mint(alice, 3);
        vm.startPrank(alice);
        first.approve(address(book), 3);
        second.approve(address(book), 3);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 3;
        amounts[1] = 3;
        book.deposit(amounts);
        book.mint(1);
        vm.stopPrank();

        vm.prank(bob);
        book.mint(1);
        _emitState("after_mints", book, first, second);

        _redeem(book, bob, "paid_b");
        _emitState("after_b", book, first, second);
        _redeem(book, alice, "paid_a");
        _emitState("after_a", book, first, second);
    }

    function _book(MockCollateral first, MockCollateral second) internal returns (CandidateComponentBacking) {
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        uint8[] memory decimals_ = new uint8[](2);
        tokens[0] = address(first);
        tokens[1] = address(second);
        weights[0] = WAD + 1;
        weights[1] = WAD + 1;
        decimals_[0] = 18;
        decimals_[1] = 18;
        return new CandidateComponentBacking(tokens, weights, decimals_);
    }

    function _redeem(CandidateComponentBacking book, address who, string memory tag) internal {
        vm.prank(who);
        uint256[] memory paid = book.redeem(1);
        emit log_string(tag);
        emit log_named_uint("paid0", paid[0]);
        emit log_named_uint("paid1", paid[1]);
    }

    function _emitState(
        string memory tag,
        CandidateComponentBacking book,
        MockCollateral first,
        MockCollateral second
    ) internal {
        uint256 supply = book.supplyUnits();
        uint256[] memory required = book.requiredRaw(supply);
        emit log_string(tag);
        emit log_named_uint("supply", supply);
        emit log_named_uint("backing0", book.backingRaw(0));
        emit log_named_uint("backing1", book.backingRaw(1));
        emit log_named_uint("required0", required[0]);
        emit log_named_uint("required1", required[1]);
        emit log_named_uint("series_a", book.balanceOf(alice));
        emit log_named_uint("series_b", book.balanceOf(bob));
        emit log_named_uint("comp_a0", first.balanceOf(alice));
        emit log_named_uint("comp_a1", second.balanceOf(alice));
        emit log_named_uint("comp_b0", first.balanceOf(bob));
        emit log_named_uint("comp_b1", second.balanceOf(bob));
        emit log_named_uint("covers0", book.backingRaw(0) >= required[0] ? 1 : 0);
        emit log_named_uint("covers1", book.backingRaw(1) >= required[1] ? 1 : 0);
    }
}

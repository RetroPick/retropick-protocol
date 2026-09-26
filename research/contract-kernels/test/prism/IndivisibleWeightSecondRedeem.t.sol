// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice After redeem(1) on the indivisible-weight book, the minter redeems the remaining 1.
/// @dev Weights are 10^18+1 and 10^18+1. Redeem, mint, backing, and weights are not edited.
contract IndivisibleWeightSecondRedeemTest is Test {
    uint256 internal constant WAD = 10 ** 18;

    address internal alice = address(0xA11CE);

    function test_minter_redeems_the_remaining_unit() public {
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
        book.mint(2);
        book.redeem(1);
        _emitState("before_second", book, first, second);

        uint256[] memory released = book.redeem(1);
        vm.stopPrank();
        emit log_named_uint("second_paid_0", released[0]);
        emit log_named_uint("second_paid_1", released[1]);
        _emitState("after_second", book, first, second);
        emit log_named_uint("kernel_balance_0", first.balanceOf(address(book)));
        emit log_named_uint("kernel_balance_1", second.balanceOf(address(book)));
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
        emit log_named_uint("series", book.balanceOf(alice));
        emit log_named_uint("component0", first.balanceOf(alice));
        emit log_named_uint("component1", second.balanceOf(alice));
        emit log_named_uint("covers0", book.backingRaw(0) >= required[0] ? 1 : 0);
        emit log_named_uint("covers1", book.backingRaw(1) >= required[1] ? 1 : 0);
    }
}

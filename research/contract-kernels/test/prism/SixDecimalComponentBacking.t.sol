// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Weights 10^18 and 10^18 with component decimals 6 and 6.
/// @dev requiredRaw is read from the kernel. Decimals, mint, and redeem are not edited.
contract SixDecimalComponentBackingTest is Test {
    uint256 internal constant WAD = 10 ** 18;

    address internal alice = address(0xA11CE);

    function test_decimals_six_deposit_required_mint_one_redeem_one() public {
        CandidateComponentBacking book = _book();
        assertEq(book.componentDecimals(0), 6);
        assertEq(book.componentDecimals(1), 6);
        assertEq(book.weightWad(0), WAD);
        assertEq(book.weightWad(1), WAD);

        uint256[] memory required = book.requiredRaw(1);
        uint256 required0 = required[0];
        uint256 required1 = required[1];

        vm.startPrank(alice);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = required0;
        amounts[1] = required1;
        book.deposit(amounts);
        book.mint(1);
        uint256 backingBefore0 = book.backingRaw(0);
        uint256 backingBefore1 = book.backingRaw(1);
        assertEq(book.supplyUnits(), 1);
        assertEq(backingBefore0, required0);
        assertEq(backingBefore1, required1);
        uint256[] memory paid = book.redeem(1);
        vm.stopPrank();

        uint256 paid0 = paid[0];
        uint256 paid1 = paid[1];
        uint256 backingAfter0 = book.backingRaw(0);
        uint256 backingAfter1 = book.backingRaw(1);
        uint256[] memory requiredAfter = book.requiredRaw(book.supplyUnits());
        assertEq(book.supplyUnits(), 0);
        assertGe(backingAfter0, requiredAfter[0]);
        assertGe(backingAfter1, requiredAfter[1]);

        emit log_string("classification: existing_rule");
        emit log_string("constructor_rejected: false");
        emit log_named_uint("required_raw_0", required0);
        emit log_named_uint("required_raw_1", required1);
        emit log_named_uint("deposited_0", required0);
        emit log_named_uint("deposited_1", required1);
        emit log_named_uint("paid_0", paid0);
        emit log_named_uint("paid_1", paid1);
        emit log_named_uint("supply_before", 1);
        emit log_named_uint("supply_after", book.supplyUnits());
        emit log_named_uint("backing_before_0", backingBefore0);
        emit log_named_uint("backing_before_1", backingBefore1);
        emit log_named_uint("backing_after_0", backingAfter0);
        emit log_named_uint("backing_after_1", backingAfter1);
        emit log_named_uint("required_after_0", requiredAfter[0]);
        emit log_named_uint("required_after_1", requiredAfter[1]);
        emit log_string("kuru_decimals_18: not_established");
    }

    function _book() internal returns (CandidateComponentBacking book) {
        MockCollateral first = new MockCollateral(6);
        MockCollateral second = new MockCollateral(6);
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        uint8[] memory decimals_ = new uint8[](2);
        tokens[0] = address(first);
        tokens[1] = address(second);
        weights[0] = WAD;
        weights[1] = WAD;
        decimals_[0] = 6;
        decimals_[1] = 6;
        book = new CandidateComponentBacking(tokens, weights, decimals_);
        first.mint(alice, 1000);
        second.mint(alice, 1000);
        vm.startPrank(alice);
        first.approve(address(book), 1000);
        second.approve(address(book), 1000);
        vm.stopPrank();
    }
}

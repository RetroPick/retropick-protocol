// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice A mints 2 at indivisible weights. The series balance has no transfer to B.
/// @dev Redeem, mint, transfer, backing, and weights are not edited.
contract IndivisibleWeightTwoHoldersTest is Test {
    uint256 internal constant WAD = 10 ** 18;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function test_series_balance_has_no_transfer() public {
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
        vm.stopPrank();

        uint256 seriesA = book.balanceOf(alice);
        uint256 seriesB = book.balanceOf(bob);
        vm.prank(alice);
        (bool ok, bytes memory data) = address(book).call(abi.encodeWithSignature("transfer(address,uint256)", bob, 1));

        emit log_named_uint("transfer_declared", 0);
        emit log_named_uint("transfer_ok", ok ? 1 : 0);
        emit log_named_uint("transfer_return_len", data.length);
        emit log_named_uint("series_a_before", seriesA);
        emit log_named_uint("series_b_before", seriesB);
        emit log_named_uint("series_a_after", book.balanceOf(alice));
        emit log_named_uint("series_b_after", book.balanceOf(bob));
        emit log_named_uint("supply", book.supplyUnits());
        emit log_named_uint("backing0", book.backingRaw(0));
        emit log_named_uint("backing1", book.backingRaw(1));
        uint256[] memory required = book.requiredRaw(book.supplyUnits());
        emit log_named_uint("required0", required[0]);
        emit log_named_uint("required1", required[1]);
        emit log_string("two_holder_redeems: not_executed");
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";
import {CandidatePayoffTransform} from "../../src/prism/CandidatePayoffTransform.sol";

/// @notice Activated weights and the stored payoff stay fixed through existing calls.
/// @dev No setter, payoff matrix, or solver is added.
contract ActivatedImmutabilityTest is Test {
    uint256 internal constant W0 = 600000000000000000;
    uint256 internal constant W1 = 400000000000000000;

    address internal alice = address(0xA11CE);

    function test_backing_weights_stay_fixed() public {
        CandidateComponentBacking book = _backing();
        uint256 before0 = book.weightWad(0);
        uint256 before1 = book.weightWad(1);
        assertEq(before0, W0);
        assertEq(before1, W1);

        vm.startPrank(alice);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 600;
        amounts[1] = 400;
        book.deposit(amounts);
        book.mint(1000);
        book.redeem(100);
        vm.stopPrank();

        assertEq(book.weightWad(0), before0);
        assertEq(book.weightWad(1), before1);
        assertEq(book.supplyUnits(), 900);
        assertEq(book.backingRaw(0), 540);
        assertEq(book.backingRaw(1), 360);

        emit log_string("backing_weights_before: 600000000000000000,400000000000000000");
        emit log_string("backing_weights_after: 600000000000000000,400000000000000000");
        emit log_string("backing_setter: absent");
        emit log_string("backing_payoff_matrix: absent");
        emit log_string("weight_edge: existing_rule");
    }

    function test_transform_weights_and_payoff_stay_fixed() public {
        CandidatePayoffTransform book = _transform();
        _assertStored(book);
        uint256 cash = book.transformComponent(1, 1);
        assertEq(cash, 360);
        _assertStored(book);
        assertEq(book.backing(0), 540);
        assertEq(book.backing(1), 0);
        assertEq(book.transformed(), 360);

        emit log_string("transform_weights_before: 600000000000000000,400000000000000000");
        emit log_string("transform_weights_after: 600000000000000000,400000000000000000");
        emit log_string("transform_payoff_before: 0,1,0,0,1,1,1,0");
        emit log_string("transform_payoff_after: 0,1,0,0,1,1,1,0");
        emit log_string("transform_setter: absent");
        emit log_string("matrix_edge: existing_rule");
    }

    function _backing() internal returns (CandidateComponentBacking book) {
        MockCollateral first = new MockCollateral(18);
        MockCollateral second = new MockCollateral(18);
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        uint8[] memory decimals_ = new uint8[](2);
        tokens[0] = address(first);
        tokens[1] = address(second);
        weights[0] = W0;
        weights[1] = W1;
        decimals_[0] = 18;
        decimals_[1] = 18;
        book = new CandidateComponentBacking(tokens, weights, decimals_);
        first.mint(alice, 600);
        second.mint(alice, 400);
        vm.startPrank(alice);
        first.approve(address(book), 600);
        second.approve(address(book), 400);
        vm.stopPrank();
    }

    function _transform() internal returns (CandidatePayoffTransform book) {
        uint256[] memory payoff = new uint256[](8);
        payoff[1] = 1;
        payoff[4] = 1;
        payoff[5] = 1;
        payoff[6] = 1;
        uint256[] memory weights = new uint256[](2);
        weights[0] = W0;
        weights[1] = W1;
        uint256[] memory backing_ = new uint256[](2);
        backing_[0] = 540;
        backing_[1] = 360;
        book = new CandidatePayoffTransform(payoff, 4, weights, backing_, 900);
    }

    function _assertStored(CandidatePayoffTransform book) internal view {
        assertEq(book.weightWad(0), W0);
        assertEq(book.weightWad(1), W1);
        assertEq(book.payoffOf(0, 0), 0);
        assertEq(book.payoffOf(0, 1), 1);
        assertEq(book.payoffOf(1, 0), 0);
        assertEq(book.payoffOf(1, 1), 0);
        assertEq(book.payoffOf(2, 0), 1);
        assertEq(book.payoffOf(2, 1), 1);
        assertEq(book.payoffOf(3, 0), 1);
        assertEq(book.payoffOf(3, 1), 0);
    }
}

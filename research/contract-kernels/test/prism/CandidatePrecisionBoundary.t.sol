// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice Differential replay of the uint256-fitting cumulative-floor cells.
/// @dev Overflow products and zero supply are not in `.cases`. The per-call
///      counterexample is not implemented here.
contract CandidatePrecisionBoundaryDifferentialTest is Test {
    function test_matches_fitting_cumulative_cells() public {
        string memory json = vm.readFile("../prism-model/fixtures/precision_boundary_cumulative.json");
        assertFalse(vm.parseJsonBool(json, ".per_call_rule_in_solidity"));
        assertEq(vm.parseJsonString(json, ".math_1"), "FAIL");
        uint256 n = vm.parseJsonUint(json, ".solidity_case_count");
        assertGt(vm.parseJsonUint(json, ".excluded_overflow_count"), 0);
        assertEq(vm.parseJsonUint(json, ".excluded_zero_supply_count"), 24);
        assertEq(vm.parseJsonUint(json, ".per_call_regression_count"), 48);
        for (uint256 i; i < n; ++i) {
            _replay(json, i);
        }
    }

    function _replay(string memory json, uint256 i) internal {
        string memory prefix = string.concat(".cases[", vm.toString(i), "]");
        string memory id = vm.parseJsonString(json, string.concat(prefix, ".id"));
        (address[] memory holders, uint256[] memory amounts) = _holders(json, prefix);
        CandidateCumulativeSettlement book = _open(json, prefix, id, holders, amounts);
        _redeemAll(json, prefix, id, book, holders);
        _assertClosed(json, prefix, id, book);
    }

    function _open(
        string memory json,
        string memory prefix,
        string memory id,
        address[] memory holders,
        uint256[] memory amounts
    ) private returns (CandidateCumulativeSettlement book) {
        uint8 decimals_ = uint8(_field(json, prefix, ".decimals"));
        MockCollateral token = new MockCollateral(decimals_);
        book = new CandidateCumulativeSettlement(
            address(token), _field(json, prefix, ".payout_wad"), decimals_, holders, amounts
        );
        assertEq(book.supplyUnits(), _field(json, prefix, ".supply"), id);
        assertEq(book.initialSupply(), _field(json, prefix, ".supply"), id);
        assertEq(book.denominator(), _field(json, prefix, ".denominator"), id);
        assertEq(book.ceilFunding(), _field(json, prefix, ".ceil_funding"), id);
        assertEq(book.oneShotFloor(), _field(json, prefix, ".one_shot_floor"), id);
        token.mint(address(book), _field(json, prefix, ".ceil_funding"));
        book.makeRedeemable();
    }

    function _redeemAll(
        string memory json,
        string memory prefix,
        string memory id,
        CandidateCumulativeSettlement book,
        address[] memory holders
    ) private {
        uint256 holderCount = holders.length;
        uint256[] memory receipts = new uint256[](holderCount);
        uint256 paid;
        uint256 stepCount = _field(json, prefix, ".step_count");
        for (uint256 s; s < stepCount; ++s) {
            uint256 holderIndex = _at(json, prefix, ".holder_index[", s);
            vm.prank(holders[holderIndex]);
            uint256 got = book.redeem(_at(json, prefix, ".quantities[", s));
            assertEq(got, _at(json, prefix, ".payouts[", s), id);
            receipts[holderIndex] += got;
            paid += got;
        }
        assertEq(paid, _field(json, prefix, ".paid_total"), id);
        assertEq(paid, _field(json, prefix, ".one_shot_floor"), id);
        assertEq(book.paidRaw(), paid, id);
        for (uint256 h; h < holderCount; ++h) {
            assertEq(receipts[h], _at(json, prefix, ".receipts[", h), id);
        }
    }

    function _assertClosed(
        string memory json,
        string memory prefix,
        string memory id,
        CandidateCumulativeSettlement book
    ) private view {
        assertEq(book.settlementToken().balanceOf(address(book)), _field(json, prefix, ".residual"), id);
        assertEq(book.redeemedUnits(), _field(json, prefix, ".supply"), id);
        assertEq(book.supplyUnits(), 0, id);
    }

    function _holders(string memory json, string memory prefix)
        private
        pure
        returns (address[] memory holders, uint256[] memory amounts)
    {
        uint256 holderCount = vm.parseJsonUint(json, string.concat(prefix, ".holder_count"));
        holders = new address[](holderCount);
        amounts = new uint256[](holderCount);
        for (uint256 h; h < holderCount; ++h) {
            holders[h] = address(uint160(0xA0 + h));
            amounts[h] = _at(json, prefix, ".balances[", h);
        }
    }

    function _field(string memory json, string memory prefix, string memory key) private pure returns (uint256) {
        return vm.parseJsonUint(json, string.concat(prefix, key));
    }

    function _at(string memory json, string memory prefix, string memory key, uint256 index)
        private
        pure
        returns (uint256)
    {
        return vm.parseJsonUint(json, string.concat(prefix, key, vm.toString(index), "]"));
    }
}

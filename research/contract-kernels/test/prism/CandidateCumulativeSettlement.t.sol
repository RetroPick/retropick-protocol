// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice Differential check against fixtures generated from the Python candidate.
///         A mismatch is COUNTEREXAMPLE_FOUND. Do not edit cumulative_settlement.py to fit Solidity.
contract CandidateCumulativeSettlementDifferentialTest is Test {
    function test_matches_python_fixtures() public {
        string memory json = vm.readFile("../prism-model/fixtures/candidate_cumulative_settlement.json");
        assertEq(vm.parseJsonUint(json, ".case_count"), 7);
        uint256 n = vm.parseJsonUint(json, ".case_count");
        for (uint256 i; i < n; ++i) {
            _replay(json, i);
        }
    }

    function test_underfunded_does_not_open() public {
        MockCollateral token = new MockCollateral(18);
        (address[] memory holders, uint256[] memory amounts) = _pair();
        CandidateCumulativeSettlement book =
            new CandidateCumulativeSettlement(address(token), 10 ** 18 - 1, 18, holders, amounts);
        assertEq(book.ceilFunding(), 2);
        token.mint(address(book), 1);
        vm.expectRevert(abi.encodeWithSelector(CandidateCumulativeSettlement.Underfunded.selector, 1, 2));
        book.makeRedeemable();
        assertFalse(book.redeemable());
    }

    /// @notice R-I08. Constructor allocation is the final supply. `redeem` reverts
    ///         until `makeRedeemable`. After funding, the first unit still pays 0.
    function test_final_supply_is_not_redeemable_until_funded() public {
        MockCollateral token = new MockCollateral(18);
        (address[] memory holders, uint256[] memory amounts) = _pair();
        CandidateCumulativeSettlement book =
            new CandidateCumulativeSettlement(address(token), 10 ** 18 - 1, 18, holders, amounts);
        assertEq(book.supplyUnits(), 2);
        assertFalse(book.redeemable());

        vm.prank(holders[0]);
        vm.expectRevert(CandidateCumulativeSettlement.NotRedeemable.selector);
        book.redeem(1);

        token.mint(address(book), 1);
        vm.expectRevert(abi.encodeWithSelector(CandidateCumulativeSettlement.Underfunded.selector, 1, 2));
        book.makeRedeemable();
        assertFalse(book.redeemable());
        vm.prank(holders[0]);
        vm.expectRevert(CandidateCumulativeSettlement.NotRedeemable.selector);
        book.redeem(1);

        token.mint(address(book), 1);
        book.makeRedeemable();
        assertTrue(book.redeemable());
        vm.prank(holders[0]);
        assertEq(book.redeem(1), 0);
    }

    function _replay(string memory json, uint256 i) internal {
        string memory prefix = string.concat(".cases[", vm.toString(i), "]");
        string memory id = vm.parseJsonString(json, string.concat(prefix, ".id"));
        (address[] memory holders, uint256[] memory amounts) = _holders(json, prefix);
        CandidateCumulativeSettlement book = _open(json, prefix, id, holders, amounts);
        _redeemAll(json, prefix, id, book, holders);
        _assertClosed(json, prefix, id, book);
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

    function _open(
        string memory json,
        string memory prefix,
        string memory id,
        address[] memory holders,
        uint256[] memory amounts
    ) private returns (CandidateCumulativeSettlement book) {
        uint256 supply = _field(json, prefix, ".supply");
        uint8 decimals_ = uint8(_field(json, prefix, ".decimals"));
        MockCollateral token = new MockCollateral(decimals_);
        book = new CandidateCumulativeSettlement(
            address(token), _field(json, prefix, ".payout_wad"), decimals_, holders, amounts
        );
        assertEq(book.supplyUnits(), supply, id);
        assertEq(book.initialSupply(), supply, id);
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

    function _pair() private pure returns (address[] memory holders, uint256[] memory amounts) {
        holders = new address[](2);
        amounts = new uint256[](2);
        holders[0] = address(0xA0);
        holders[1] = address(0xA1);
        amounts[0] = 1;
        amounts[1] = 1;
    }
}

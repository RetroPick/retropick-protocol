// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice The funder is not the series holder. Redeem is not edited.
/// @dev Book already used by the gas test: one holder, supply 2, payout 10^18-1, decimals 18.
contract SettlementPaysHolderTest is Test {
    address internal holder = address(0xA11CE);
    address internal funder = address(0xB0B);

    function test_series_holder_receives_the_settlement_payout() public {
        MockCollateral token = new MockCollateral(18);
        CandidateCumulativeSettlement book = _book(token);
        _fund(token, book);

        assertEq(token.balanceOf(funder), 0);
        assertEq(token.balanceOf(holder), 0);
        assertEq(token.balanceOf(address(book)), 2);
        assertEq(book.paidRaw(), 0);
        assertTrue(book.redeemable());

        vm.prank(holder);
        uint256 payout = book.redeem(2);
        assertEq(payout, 1);

        assertEq(token.balanceOf(funder), 0);
        assertEq(token.balanceOf(holder), 1);
        assertEq(token.balanceOf(address(book)), 1);
        assertEq(book.paidRaw(), 1);
        assertTrue(book.redeemable());

        emit log_string("classification: settlement_pays_holder");
        emit log_string("funder_before: 0");
        emit log_string("holder_before: 0");
        emit log_string("kernel_before: 2");
        emit log_string("funder_after: 0");
        emit log_string("holder_after: 1");
        emit log_string("kernel_after: 1");
        emit log_string("paid_raw_after: 1");
        emit log_string("redeemable_after: true");
    }

    function _book(MockCollateral token) internal returns (CandidateCumulativeSettlement book) {
        address[] memory holders = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        holders[0] = holder;
        amounts[0] = 2;
        book = new CandidateCumulativeSettlement(address(token), 10 ** 18 - 1, 18, holders, amounts);
        assertEq(book.supplyUnits(), 2);
        assertEq(book.ceilFunding(), 2);
    }

    function _fund(MockCollateral token, CandidateCumulativeSettlement book) internal {
        token.mint(funder, 2);
        vm.prank(funder);
        assertTrue(token.transfer(address(book), 2));
        book.makeRedeemable();
    }
}

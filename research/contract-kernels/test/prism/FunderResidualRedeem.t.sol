// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice After the holder redeem, the funder calls the existing redeem.
/// @dev No sweep, withdraw, or new payout. Redeem is not edited.
contract FunderResidualRedeemTest is Test {
    address internal holder = address(0xA11CE);
    address internal funder = address(0xB0B);

    function test_funder_redeem_of_one_leaves_the_residual() public {
        MockCollateral token = new MockCollateral(18);
        CandidateCumulativeSettlement book = _opened(token);

        vm.prank(holder);
        assertEq(book.redeem(2), 1);
        assertEq(token.balanceOf(funder), 0);
        assertEq(token.balanceOf(holder), 1);
        assertEq(token.balanceOf(address(book)), 1);
        assertEq(book.paidRaw(), 1);

        vm.expectRevert(abi.encodeWithSelector(CandidateCumulativeSettlement.InvalidQuantity.selector, 1, 0));
        vm.prank(funder);
        book.redeem(1);

        assertEq(token.balanceOf(funder), 0);
        assertEq(token.balanceOf(holder), 1);
        assertEq(token.balanceOf(address(book)), 1);
        assertEq(book.paidRaw(), 1);

        emit log_string("classification: existing_rule");
        emit log_string("error: InvalidQuantity(1, 0)");
        emit log_string("funder_after: 0");
        emit log_string("holder_after: 1");
        emit log_string("kernel_after: 1");
        emit log_string("paid_raw_after: 1");
        emit log_string("residual_stays_in_kernel: true");
        emit log_string("sweep_added: false");
    }

    function _opened(MockCollateral token) internal returns (CandidateCumulativeSettlement book) {
        address[] memory holders = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        holders[0] = holder;
        amounts[0] = 2;
        book = new CandidateCumulativeSettlement(address(token), 10 ** 18 - 1, 18, holders, amounts);
        token.mint(funder, 2);
        vm.prank(funder);
        assertTrue(token.transfer(address(book), 2));
        book.makeRedeemable();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice A settlement token that reenters redeem during an outgoing transfer.
///         It is also a holder so the nested call reaches the reentrancy guard.
contract ReenteringSettlementToken {
    mapping(address => uint256) public balanceOf;
    CandidateCumulativeSettlement public book;
    bool public attack;

    function setBook(CandidateCumulativeSettlement book_) external {
        book = book_;
    }

    function setAttack(bool value) external {
        attack = value;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        if (attack && msg.sender == address(book)) book.redeem(1);
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract CandidateSettlementReentrancyTest is Test {
    function test_callback_reverts_outer_redemption_without_cursor_or_balance_change() public {
        ReenteringSettlementToken token = new ReenteringSettlementToken();
        address holder = address(0xA0);
        address[] memory holders = new address[](2);
        holders[0] = holder;
        holders[1] = address(token);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        CandidateCumulativeSettlement book =
            new CandidateCumulativeSettlement(address(token), 10 ** 18, 18, holders, amounts);
        token.setBook(book);
        token.mint(address(book), 2);
        book.makeRedeemable();

        token.setAttack(true);
        vm.prank(holder);
        vm.expectRevert(ReentrancyGuard.ReentrancyGuardReentrantCall.selector);
        book.redeem(1);
        assertEq(book.balances(holder), 1);
        assertEq(book.balances(address(token)), 1);
        assertEq(book.supplyUnits(), 2);
        assertEq(book.redeemedUnits(), 0);
        assertEq(book.paidRaw(), 0);
        assertEq(token.balanceOf(address(book)), 2);
        assertEq(token.balanceOf(holder), 0);

        token.setAttack(false);
        vm.prank(holder);
        assertEq(book.redeem(1), 1);
        assertEq(book.redeemedUnits(), 1);
        assertEq(token.balanceOf(holder), 1);
    }
}

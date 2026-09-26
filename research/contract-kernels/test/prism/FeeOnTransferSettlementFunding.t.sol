// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice Test settlement token. `transfer` returns true and delivers one token less.
contract FeeOnTransferSettlementToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _move(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
        _move(from, to, amount);
        return true;
    }

    function _move(address from, address to, uint256 amount) private {
        balanceOf[from] -= amount;
        balanceOf[to] += amount - 1;
    }
}

contract FeeOnTransferSettlementFundingTest is Test {
    function test_short_transfer_does_not_open_redemption() public {
        FeeOnTransferSettlementToken token = new FeeOnTransferSettlementToken();
        address[] memory holders = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        holders[0] = address(0xA0);
        holders[1] = address(0xA1);
        amounts[0] = 1;
        amounts[1] = 1;
        CandidateCumulativeSettlement book =
            new CandidateCumulativeSettlement(address(token), 10 ** 18 - 1, 18, holders, amounts);

        assertEq(book.supplyUnits(), 2);
        assertEq(book.ceilFunding(), 2);
        assertFalse(book.redeemable());

        token.mint(address(this), 2);
        bool transferred = token.transfer(address(book), 2);
        assertTrue(transferred);
        assertEq(token.balanceOf(address(book)), 1);
        assertEq(book.paidRaw(), 0);

        vm.expectRevert(abi.encodeWithSelector(CandidateCumulativeSettlement.Underfunded.selector, 1, 2));
        book.makeRedeemable();
        assertFalse(book.redeemable());
        assertEq(token.balanceOf(address(book)), 1);
        assertEq(book.paidRaw(), 0);

        vm.prank(holders[0]);
        vm.expectRevert(CandidateCumulativeSettlement.NotRedeemable.selector);
        book.redeem(1);
        assertEq(token.balanceOf(address(book)), 1);
        assertEq(book.paidRaw(), 0);
        assertFalse(book.redeemable());
    }
}

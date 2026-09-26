// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidateCumulativeSettlement} from "../../src/prism/CandidateCumulativeSettlement.sol";

/// @notice Test settlement token. `transfer` moves the full amount. `rebaseDown` does not.
contract RebaseSettlementToken {
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

    function rebaseDown(address holder, uint256 amount) external {
        balanceOf[holder] -= amount;
    }

    function _move(address from, address to, uint256 amount) private {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }
}

contract RebasingSettlementFundingTest is Test {
    function test_rebase_after_redeemable_then_redeem() public {
        RebaseSettlementToken token = new RebaseSettlementToken();
        address holder = address(0xA0);
        address[] memory holders = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        holders[0] = holder;
        amounts[0] = 2;
        CandidateCumulativeSettlement book =
            new CandidateCumulativeSettlement(address(token), 10 ** 18 - 1, 18, holders, amounts);

        assertEq(book.supplyUnits(), 2);
        assertEq(book.ceilFunding(), 2);
        token.mint(address(this), 2);
        assertTrue(token.transfer(address(book), 2));
        assertEq(token.balanceOf(address(book)), 2);
        book.makeRedeemable();
        assertTrue(book.redeemable());
        assertEq(book.paidRaw(), 0);

        token.rebaseDown(address(book), 1);
        assertEq(token.balanceOf(address(book)), 1);
        assertTrue(book.redeemable());
        assertEq(book.paidRaw(), 0);

        vm.prank(holder);
        uint256 payout = book.redeem(2);
        assertEq(payout, 1);
        assertEq(book.paidRaw(), 1);
        assertEq(token.balanceOf(address(book)), 0);
        assertEq(token.balanceOf(holder), 1);
        assertTrue(book.redeemable());
    }
}

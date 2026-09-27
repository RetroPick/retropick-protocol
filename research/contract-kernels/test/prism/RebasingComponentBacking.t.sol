// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Test component. `rebaseDown` changes a balance without transfer or transferFrom.
contract RebaseComponentToken {
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

contract RebasingComponentBackingTest is Test {
    function test_rebase_drops_balance_below_recorded_backing() public {
        RebaseComponentToken token = new RebaseComponentToken();
        address[] memory tokens = new address[](1);
        uint256[] memory weights = new uint256[](1);
        uint8[] memory decimals_ = new uint8[](1);
        tokens[0] = address(token);
        weights[0] = 10 ** 18;
        decimals_[0] = 18;
        CandidateComponentBacking book = new CandidateComponentBacking(tokens, weights, decimals_);

        token.mint(address(this), 100);
        token.approve(address(book), 100);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;
        book.deposit(amounts);
        book.mint(100);

        assertEq(token.balanceOf(address(book)), 100);
        assertEq(book.backingRaw(0), 100);
        assertEq(book.supplyUnits(), 100);
        assertEq(book.requiredRaw(100)[0], 100);

        token.rebaseDown(address(book), 1);

        uint256 balance = token.balanceOf(address(book));
        uint256 recorded = book.backingRaw(0);
        uint256 required = book.requiredRaw(book.supplyUnits())[0];
        assertEq(balance, 99);
        assertEq(recorded, 100);
        assertEq(book.supplyUnits(), 100);
        assertEq(required, 100);
        assertLt(balance, recorded);
        assertLt(balance, required);
    }
}

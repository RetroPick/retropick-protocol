// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Test component. `transfer` and `transferFrom` return true and deliver one token less.
contract FeeOnTransferComponentToken {
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

contract FeeOnTransferComponentBackingTest is Test {
    function test_short_deposit_does_not_credit_backing() public {
        FeeOnTransferComponentToken token = new FeeOnTransferComponentToken();
        address[] memory tokens = new address[](1);
        uint256[] memory weights = new uint256[](1);
        uint8[] memory decimals_ = new uint8[](1);
        tokens[0] = address(token);
        weights[0] = 10 ** 18;
        decimals_[0] = 18;
        CandidateComponentBacking book = new CandidateComponentBacking(tokens, weights, decimals_);

        token.mint(address(this), 10);
        token.approve(address(book), 10);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10;

        vm.expectRevert(abi.encodeWithSelector(CandidateComponentBacking.Shortfall.selector, 0, 9, 10));
        book.deposit(amounts);

        assertEq(token.balanceOf(address(book)), 0);
        assertEq(token.balanceOf(address(this)), 10);
        assertEq(book.backingRaw(0), 0);
        assertEq(book.supplyUnits(), 0);
        assertEq(book.requiredRaw(0)[0], 0);

        vm.expectRevert(abi.encodeWithSelector(CandidateComponentBacking.InsufficientBacking.selector, 0, 0, 10));
        book.mint(10);

        assertEq(token.balanceOf(address(book)), 0);
        assertEq(book.backingRaw(0), 0);
        assertEq(book.supplyUnits(), 0);
        assertEq(book.requiredRaw(book.supplyUnits())[0], 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice One ERC-20 used as both component slots.
contract DuplicateComponentToken {
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
        balanceOf[to] += amount;
    }
}

contract DuplicateComponentBackingTest is Test {
    function test_same_token_in_two_slots_does_not_double_count() public {
        DuplicateComponentToken token = new DuplicateComponentToken();
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        uint8[] memory decimals_ = new uint8[](2);
        tokens[0] = address(token);
        tokens[1] = address(token);
        weights[0] = 10 ** 18;
        weights[1] = 10 ** 18;
        decimals_[0] = 18;
        decimals_[1] = 18;
        CandidateComponentBacking book = new CandidateComponentBacking(tokens, weights, decimals_);
        assertEq(book.componentToken(0), book.componentToken(1));

        token.mint(address(this), 20);
        token.approve(address(book), 20);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10;
        amounts[1] = 10;
        book.deposit(amounts);

        assertEq(book.backingRaw(0), 10);
        assertEq(book.backingRaw(1), 10);
        assertEq(token.balanceOf(address(book)), 20);
        uint256[] memory requiredEleven = book.requiredRaw(11);
        assertEq(requiredEleven[0], 11);
        assertEq(requiredEleven[1], 11);
        vm.expectRevert(abi.encodeWithSelector(CandidateComponentBacking.InsufficientBacking.selector, 0, 10, 11));
        book.mint(11);
        assertEq(book.supplyUnits(), 0);
        assertEq(book.backingRaw(0), 10);
        assertEq(book.backingRaw(1), 10);
        assertEq(token.balanceOf(address(book)), 20);

        uint256[] memory requiredTen = book.requiredRaw(10);
        assertEq(requiredTen[0], 10);
        assertEq(requiredTen[1], 10);
        book.mint(10);
        assertEq(book.supplyUnits(), 10);
        assertEq(book.backingRaw(0), 10);
        assertEq(book.backingRaw(1), 10);
        assertEq(token.balanceOf(address(book)), 20);
    }
}

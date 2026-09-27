// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {CandidateComponentBacking} from "../../src/prism/CandidateComponentBacking.sol";

/// @notice Plain component token. Transfers move the full amount.
contract ZeroWeightComponentToken {
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

contract ZeroWeightComponentBackingTest is Test {
    function test_zero_weight_requires_zero_and_positive_slot_stays_backed() public {
        ZeroWeightComponentToken zeroToken = new ZeroWeightComponentToken();
        ZeroWeightComponentToken paidToken = new ZeroWeightComponentToken();
        address[] memory tokens = new address[](2);
        uint256[] memory weights = new uint256[](2);
        uint8[] memory decimals_ = new uint8[](2);
        tokens[0] = address(zeroToken);
        tokens[1] = address(paidToken);
        weights[0] = 0;
        weights[1] = 10 ** 18;
        decimals_[0] = 18;
        decimals_[1] = 18;
        CandidateComponentBacking book = new CandidateComponentBacking(tokens, weights, decimals_);
        assertEq(book.weightWad(0), 0);
        assertEq(book.weightWad(1), 10 ** 18);

        paidToken.mint(address(this), 4);
        paidToken.approve(address(book), 4);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 0;
        amounts[1] = 4;
        book.deposit(amounts);
        book.mint(4);

        assertEq(book.backingRaw(0), 0);
        assertEq(book.backingRaw(1), 4);
        uint256[] memory required = book.requiredRaw(book.supplyUnits());
        assertEq(required[0], 0);
        assertEq(required[1], 4);
        assertEq(zeroToken.balanceOf(address(book)), 0);
        assertEq(paidToken.balanceOf(address(book)), 4);
        assertEq(book.supplyUnits(), 4);
    }
}

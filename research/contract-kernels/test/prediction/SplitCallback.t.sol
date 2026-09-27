// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Test collateral. transferFrom calls back into split and does not catch the revert.
contract CallbackCollateral {
    uint8 private immutable _decimals;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

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
        PredictionMarket(msg.sender).split(1);
        return true;
    }

    function _move(address from, address to, uint256 amount) private {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }
}

contract SplitCallbackTest is Test {
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function test_callback_split_reverts_and_credits_nothing() public {
        CallbackCollateral token = new CallbackCollateral(6);
        PredictionMarket market = new PredictionMarket(
            address(token), resolver, dustSink, bytes32("callback"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        token.mint(alice, 100);
        vm.prank(alice);
        token.approve(address(market), 100);

        vm.prank(alice);
        vm.expectRevert(ReentrancyGuard.ReentrancyGuardReentrantCall.selector);
        market.split(100);

        assertEq(token.balanceOf(address(market)), 0);
        assertEq(token.balanceOf(alice), 100);
        assertEq(market.collateralLocked(), 0);
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 0);
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));
    }
}

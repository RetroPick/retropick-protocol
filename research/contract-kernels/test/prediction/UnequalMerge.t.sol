// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20Errors} from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Merge of unequal YES and NO balances while the market is still OPEN.
contract UnequalMergeTest is Test {
    uint256 internal constant QUANTITY = 4;
    uint256 internal constant MOVED_YES = 3;

    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("unequal-merge"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_merge_of_unequal_yes_and_no_leaves_books_unchanged() public {
        vm.startPrank(alice);
        market.split(QUANTITY);
        market.yesToken().transfer(bob, MOVED_YES);
        vm.stopPrank();

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));
        assertEq(market.yesToken().balanceOf(alice), 1);
        assertEq(market.noToken().balanceOf(alice), QUANTITY);
        assertEq(market.yesToken().balanceOf(bob), MOVED_YES);
        assertEq(market.noToken().balanceOf(bob), 0);
        _assertBooks(QUANTITY, QUANTITY, QUANTITY, QUANTITY);

        uint256 marketBalance = collateral.balanceOf(address(market));
        uint256 locked = market.collateralLocked();
        uint256 yesSupply = market.yesSupply();
        uint256 noSupply = market.noSupply();
        uint256 aliceYes = market.yesToken().balanceOf(alice);
        uint256 aliceNo = market.noToken().balanceOf(alice);
        uint256 bobYes = market.yesToken().balanceOf(bob);
        uint256 bobNo = market.noToken().balanceOf(bob);
        uint256 aliceCollateral = collateral.balanceOf(alice);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 1, QUANTITY)
        );
        market.merge(QUANTITY);

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));
        assertEq(collateral.balanceOf(address(market)), marketBalance);
        assertEq(market.collateralLocked(), locked);
        assertEq(market.yesSupply(), yesSupply);
        assertEq(market.noSupply(), noSupply);
        assertEq(market.yesToken().balanceOf(alice), aliceYes);
        assertEq(market.noToken().balanceOf(alice), aliceNo);
        assertEq(market.yesToken().balanceOf(bob), bobYes);
        assertEq(market.noToken().balanceOf(bob), bobNo);
        assertEq(collateral.balanceOf(alice), aliceCollateral);
        _assertBooks(QUANTITY, QUANTITY, QUANTITY, QUANTITY);
    }

    function _assertBooks(uint256 balance, uint256 locked, uint256 yesSupply, uint256 noSupply) internal view {
        assertEq(collateral.balanceOf(address(market)), balance);
        assertEq(market.collateralLocked(), locked);
        assertEq(market.yesSupply(), yesSupply);
        assertEq(market.noSupply(), noSupply);
    }
}

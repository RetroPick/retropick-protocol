// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Split of 1 while the market is still DRAFT.
contract DraftSplitTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("draft-split"), "Yes", "YES", "No", "NO"
        );
        collateral.mint(alice, 1);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_split_while_draft_leaves_books_at_zero() public {
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.DRAFT));
        _assertBooks(0, 0, 0, 0);
        assertEq(market.yesToken().balanceOf(alice), 0);
        assertEq(market.noToken().balanceOf(alice), 0);

        vm.prank(alice);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.split(1);

        _assertBooks(0, 0, 0, 0);
        assertEq(market.yesToken().balanceOf(alice), 0);
        assertEq(market.noToken().balanceOf(alice), 0);
        assertEq(collateral.balanceOf(alice), 1);
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.DRAFT));
    }

    function _assertBooks(uint256 balance, uint256 locked, uint256 yesSupply, uint256 noSupply) internal view {
        assertEq(collateral.balanceOf(address(market)), balance);
        assertEq(market.collateralLocked(), locked);
        assertEq(market.yesSupply(), yesSupply);
        assertEq(market.noSupply(), noSupply);
    }
}

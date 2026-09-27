// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice A second result after the first YES_WIN resolution.
contract SecondYesResolutionTest is Test {
    uint256 internal constant QUANTITY = 4;

    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("second-yes-resolution"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_second_result_leaves_the_yes_payout_vector() public {
        vm.prank(alice);
        market.split(QUANTITY);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();

        _assertVector();
        _assertBooks(QUANTITY, QUANTITY, QUANTITY, QUANTITY);

        vm.prank(resolver);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.resolve(PredictionMarket.Result.NO_WIN);

        _assertVector();
        _assertBooks(QUANTITY, QUANTITY, QUANTITY, QUANTITY);
    }

    function _assertVector() internal view {
        assertEq(uint256(market.result()), uint256(PredictionMarket.Result.YES_WIN));
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.RESOLVED));
        assertEq(market.yesNumerator(), 2);
        assertEq(market.noNumerator(), 0);
    }

    function _assertBooks(uint256 balance, uint256 locked, uint256 yesSupply, uint256 noSupply) internal view {
        assertEq(collateral.balanceOf(address(market)), balance);
        assertEq(market.collateralLocked(), locked);
        assertEq(market.yesSupply(), yesSupply);
        assertEq(market.noSupply(), noSupply);
    }
}

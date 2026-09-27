// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Burn of NO 1 after five one-unit YES redemptions on INVALID.
contract InvalidBurnRejectedTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("invalid-burn-rejected"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 5);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_burn_no_after_invalid_yes_dust_is_rejected() public {
        vm.prank(alice);
        market.split(5);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.INVALID);
        vm.stopPrank();
        market.openRedemption();

        vm.startPrank(alice);
        assertEq(market.redeemYes(1), 0);
        assertEq(market.redeemYes(1), 1);
        assertEq(market.redeemYes(1), 0);
        assertEq(market.redeemYes(1), 1);
        assertEq(market.redeemYes(1), 0);
        vm.stopPrank();
        _assertBooks(3, 3, 0, 5);
        assertEq(market.yesToken().balanceOf(alice), 0);
        assertEq(market.noToken().balanceOf(alice), 5);

        vm.prank(alice);
        vm.expectRevert(PredictionMarket.NotWorthless.selector);
        market.burnWorthless(false, 1);

        _assertBooks(3, 3, 0, 5);
        assertEq(market.yesToken().balanceOf(alice), 0);
        assertEq(market.noToken().balanceOf(alice), 5);
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.REDEEMABLE));
    }

    function _assertBooks(uint256 balance, uint256 locked, uint256 yesSupply, uint256 noSupply) internal view {
        assertEq(collateral.balanceOf(address(market)), balance);
        assertEq(market.collateralLocked(), locked);
        assertEq(market.yesSupply(), yesSupply);
        assertEq(market.noSupply(), noSupply);
    }
}

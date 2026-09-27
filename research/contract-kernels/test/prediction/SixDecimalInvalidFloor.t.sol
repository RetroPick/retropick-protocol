// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Supply 2, parts 1 and 1, INVALID cumulative floor, collateral decimals 6.
/// @dev Replays test_supplyTwoPartsPayCumulativeFloor. The payout formula is not edited.
contract SixDecimalInvalidFloorTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("invalid-six"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1);
        collateral.mint(bob, 1);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
        vm.prank(bob);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_supply_two_invalid_floor_at_six_decimals() public {
        uint8 collateralDecimals = collateral.decimals();
        uint8 yesDecimals = market.yesToken().decimals();
        uint8 noDecimals = market.noToken().decimals();
        assertEq(collateralDecimals, 6);
        assertEq(market.collateralDecimals(), 6);
        assertEq(yesDecimals, 6);
        assertEq(noDecimals, 6);

        vm.prank(alice);
        market.split(1);
        vm.prank(bob);
        market.split(1);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.INVALID);
        vm.stopPrank();
        market.openRedemption();

        uint256 yesFirst = _redeemYes(alice, 0, 2, 2);
        assertEq(market.liability(), 2);
        assertEq(market.collateralLocked(), 2);
        uint256 yesSecond = _redeemYes(bob, 1, 2, 2);
        assertEq(market.liability(), 1);
        assertEq(market.collateralLocked(), 1);
        uint256 noFirst = _redeemNo(alice, 0, 1, 1);
        assertEq(market.liability(), 1);
        assertEq(market.collateralLocked(), 1);
        uint256 noSecond = _redeemNo(bob, 1, 1, 1);

        assertEq(yesFirst, 0);
        assertEq(yesSecond, 1);
        assertEq(noFirst, 0);
        assertEq(noSecond, 1);
        assertEq(market.collateralLocked(), 0);
        assertEq(market.liability(), 0);
        assertEq(market.yesToken().decimals(), 6);
        assertEq(market.noToken().decimals(), 6);

        emit log_string("classification: existing_rule");
        emit log_string("composition: supply 2 parts 1,1");
        emit log_named_uint("collateral_decimals", collateralDecimals);
        emit log_named_uint("yes_decimals", yesDecimals);
        emit log_named_uint("no_decimals", noDecimals);
        emit log_named_uint("yes_payout_0", yesFirst);
        emit log_named_uint("yes_payout_1", yesSecond);
        emit log_named_uint("no_payout_0", noFirst);
        emit log_named_uint("no_payout_1", noSecond);
        emit log_named_uint("collateral_left", market.collateralLocked());
        emit log_string("recorded_cumulative_floor: 0,1");
        emit log_string("per_call_floor: not_paid");
        emit log_string("kuru_decimals_18: not_established");
    }

    function _redeemYes(address holder, uint256 expected, uint256 liabilityBefore, uint256 lockedBefore)
        internal
        returns (uint256 payout)
    {
        assertEq(market.liability(), liabilityBefore);
        assertEq(market.collateralLocked(), lockedBefore);
        vm.prank(holder);
        payout = market.redeemYes(1);
        assertEq(payout, expected);
    }

    function _redeemNo(address holder, uint256 expected, uint256 liabilityBefore, uint256 lockedBefore)
        internal
        returns (uint256 payout)
    {
        assertEq(market.liability(), liabilityBefore);
        assertEq(market.collateralLocked(), lockedBefore);
        vm.prank(holder);
        payout = market.redeemNo(1);
        assertEq(payout, expected);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Split 4, YES_WIN, open redemption once, then openRedemption again.
/// @dev No redeem between the two open calls. openRedemption is not edited.
contract SecondOpenRedemptionTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("second-open-redemption"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_second_open_redemption_while_redeemable() public {
        vm.prank(alice);
        market.split(4);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
        market.openRedemption();

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.REDEEMABLE));
        uint256 liabilityBefore = market.liability();
        uint256 lockedBefore = market.collateralLocked();
        emit log_string("state_before: REDEEMABLE");
        emit log_named_uint("liability_before", liabilityBefore);
        emit log_named_uint("collateral_before", lockedBefore);

        vm.expectRevert(PredictionMarket.BadState.selector);
        market.openRedemption();

        emit log_string("solidity_accepted: false");
        emit log_string("error: BadState");
        emit log_string("state_after: REDEEMABLE");
        emit log_named_uint("liability_after", market.liability());
        emit log_named_uint("collateral_after", market.collateralLocked());
        emit log_string("classification: existing_rule");

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.REDEEMABLE));
        assertEq(liabilityBefore, 4);
        assertEq(lockedBefore, 4);
        assertEq(market.liability(), 4);
        assertEq(market.collateralLocked(), 4);
        assertEq(market.yesSupply(), 4);
        assertEq(market.yesRedeemed(), 0);
    }
}

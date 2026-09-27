// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Split 4, commit YES_WIN, open redemption, then redeem 1 YES.
/// @dev openRedemption, redeemYes, and the payout formula are not edited.
contract OpenRedemptionYesRedeemTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("open-redemption-yes"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_open_redemption_then_redeem_one_yes() public {
        vm.prank(alice);
        market.split(4);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.RESOLVED));
        uint256 liabilityBeforeOpen = market.liability();
        uint256 lockedBeforeOpen = market.collateralLocked();
        emit log_string("state_before_open: RESOLVED");
        emit log_named_uint("liability_before_open", liabilityBeforeOpen);
        emit log_named_uint("collateral_before_open", lockedBeforeOpen);

        market.openRedemption();

        uint256 liabilityAfterOpen = market.liability();
        uint256 lockedAfterOpen = market.collateralLocked();
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.REDEEMABLE));
        emit log_string("open_function: openRedemption");
        emit log_string("state_after_open: REDEEMABLE");
        emit log_named_uint("liability_after_open", liabilityAfterOpen);
        emit log_named_uint("collateral_after_open", lockedAfterOpen);

        vm.prank(alice);
        uint256 payout = market.redeemYes(1);

        emit log_named_uint("payout", payout);
        emit log_named_uint("liability_after_redeem", market.liability());
        emit log_named_uint("collateral_after_redeem", market.collateralLocked());
        emit log_string("state_after_redeem: REDEEMABLE");
        emit log_string("classification: existing_rule");

        assertEq(liabilityBeforeOpen, 4);
        assertEq(lockedBeforeOpen, 4);
        assertEq(liabilityAfterOpen, 4);
        assertEq(lockedAfterOpen, 4);
        assertEq(market.liability(), 3);
        assertEq(market.collateralLocked(), 3);
        assertEq(payout, 1);
        assertEq(market.yesSupply(), 3);
        assertEq(market.yesRedeemed(), 1);
        assertEq(market.noSupply(), 4);
        assertEq(market.noRedeemed(), 0);
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.REDEEMABLE));
        assertEq(market.liability(), market.collateralLocked());
    }
}

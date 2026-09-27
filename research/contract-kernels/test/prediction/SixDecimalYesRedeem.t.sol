// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Collateral with 6 decimals. Split 1, resolve YES_WIN, redeem 1 YES.
/// @dev Decimals, split, redeem, and the payout formula are not edited.
contract SixDecimalYesRedeemTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("six-dec"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_split_one_yes_win_redeem_one() public {
        uint8 collateralDecimals = collateral.decimals();
        uint8 yesDecimals = market.yesToken().decimals();
        uint8 noDecimals = market.noToken().decimals();
        assertEq(collateralDecimals, 6);
        assertEq(market.collateralDecimals(), 6);
        assertEq(yesDecimals, 6);
        assertEq(noDecimals, 6);

        vm.prank(alice);
        market.split(1);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
        market.openRedemption();

        uint256 liabilityBefore = market.liability();
        uint256 lockedBefore = market.collateralLocked();
        assertEq(liabilityBefore, 1);
        assertEq(lockedBefore, 1);
        assertEq(market.yesSupply(), 1);
        assertEq(market.noSupply(), 1);
        assertEq(market.yesRedeemed(), 0);
        assertEq(market.noRedeemed(), 0);

        vm.prank(alice);
        uint256 payout = market.redeemYes(1);

        uint256 liabilityAfter = market.liability();
        uint256 lockedAfter = market.collateralLocked();
        assertEq(payout, 1);
        assertEq(liabilityAfter, 0);
        assertEq(lockedAfter, 0);
        assertEq(liabilityAfter, lockedAfter);
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 1);
        assertEq(market.yesRedeemed(), 1);
        assertEq(market.noRedeemed(), 0);
        assertEq(market.yesToken().decimals(), 6);
        assertEq(market.noToken().decimals(), 6);

        emit log_string("classification: existing_rule");
        emit log_named_uint("collateral_decimals", collateralDecimals);
        emit log_named_uint("yes_decimals", yesDecimals);
        emit log_named_uint("no_decimals", noDecimals);
        emit log_named_uint("payout", payout);
        emit log_named_uint("liability_before", liabilityBefore);
        emit log_named_uint("collateral_before", lockedBefore);
        emit log_named_uint("liability_after", liabilityAfter);
        emit log_named_uint("collateral_after", lockedAfter);
        emit log_string("kuru_decimals_18: not_established");
    }
}

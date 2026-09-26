// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Split 4, resolve YES_WIN, redeemYes(1), then attempt merge(1).
/// @dev merge, redeemYes, liability, and the payout formula are not edited.
contract MergeAfterYesRedeemTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("merge-after-yes"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_merge_after_partial_yes_redeem_reverts() public {
        vm.prank(alice);
        market.split(4);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
        market.openRedemption();

        vm.prank(alice);
        uint256 redeemPayout = market.redeemYes(1);
        assertEq(redeemPayout, 1);

        uint256 liabilityBefore = market.liability();
        uint256 lockedBefore = market.collateralLocked();
        uint256 yesSupplyBefore = market.yesSupply();
        uint256 noSupplyBefore = market.noSupply();
        uint256 yesRedeemedBefore = market.yesRedeemed();
        uint256 noRedeemedBefore = market.noRedeemed();

        assertEq(liabilityBefore, 3);
        assertEq(lockedBefore, 3);
        assertEq(yesSupplyBefore, 3);
        assertEq(noSupplyBefore, 4);
        assertEq(yesRedeemedBefore, 1);
        assertEq(noRedeemedBefore, 0);
        assertEq(market.yesToken().balanceOf(alice), 3);
        assertEq(market.noToken().balanceOf(alice), 4);

        vm.expectRevert(PredictionMarket.BadState.selector);
        vm.prank(alice);
        market.merge(1);

        assertEq(market.liability(), liabilityBefore);
        assertEq(market.collateralLocked(), lockedBefore);
        assertEq(market.yesSupply(), yesSupplyBefore);
        assertEq(market.noSupply(), noSupplyBefore);
        assertEq(market.yesRedeemed(), yesRedeemedBefore);
        assertEq(market.noRedeemed(), noRedeemedBefore);
        assertEq(market.liability(), market.collateralLocked());

        emit log_string("classification: existing_rule");
        emit log_string("solidity_rejected: true");
        emit log_string("solidity_error: BadState");
        emit log_string("merge_returned: none");
        emit log_named_uint("redeem_payout", redeemPayout);
        emit log_named_uint("liability_before", liabilityBefore);
        emit log_named_uint("collateral_before", lockedBefore);
        emit log_named_uint("liability_after", market.liability());
        emit log_named_uint("collateral_after", market.collateralLocked());
        emit log_named_uint("yes_supply_after", market.yesSupply());
        emit log_named_uint("no_supply_after", market.noSupply());
        emit log_named_uint("yes_redeemed_after", market.yesRedeemed());
        emit log_named_uint("no_redeemed_after", market.noRedeemed());
    }
}

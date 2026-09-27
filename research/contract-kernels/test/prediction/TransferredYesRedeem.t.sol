// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice A splits 4, transfers 1 YES to B, the market resolves YES_WIN, and B redeems 1 YES.
/// @dev transfer, redeemYes, liability, and the payout formula are not edited.
contract TransferredYesRedeemTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("transferred-yes"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_redeem_transferred_yes_pays_the_holder() public {
        vm.startPrank(alice);
        market.split(4);
        market.yesToken().transfer(bob, 1);
        vm.stopPrank();
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
        market.openRedemption();

        uint256 aliceCollateralBefore = collateral.balanceOf(alice);
        uint256 bobCollateralBefore = collateral.balanceOf(bob);
        uint256 liabilityBefore = market.liability();
        uint256 lockedBefore = market.collateralLocked();
        uint256 yesSupplyBefore = market.yesSupply();
        uint256 noSupplyBefore = market.noSupply();
        uint256 yesRedeemedBefore = market.yesRedeemed();
        uint256 noRedeemedBefore = market.noRedeemed();

        assertEq(market.yesToken().balanceOf(alice), 3);
        assertEq(market.yesToken().balanceOf(bob), 1);
        assertEq(liabilityBefore, 4);
        assertEq(lockedBefore, 4);
        assertEq(yesSupplyBefore, 4);
        assertEq(noSupplyBefore, 4);
        assertEq(yesRedeemedBefore, 0);
        assertEq(noRedeemedBefore, 0);
        assertEq(aliceCollateralBefore, 999_996);
        assertEq(bobCollateralBefore, 0);

        vm.expectEmit(true, false, false, true, address(market));
        emit PredictionMarket.Redeemed(bob, 0, 1, 1);
        vm.prank(bob);
        uint256 payout = market.redeemYes(1);

        uint256 aliceCollateralAfter = collateral.balanceOf(alice);
        uint256 bobCollateralAfter = collateral.balanceOf(bob);
        uint256 liabilityAfter = market.liability();
        uint256 lockedAfter = market.collateralLocked();

        assertEq(payout, 1);
        assertEq(aliceCollateralAfter, aliceCollateralBefore);
        assertEq(bobCollateralAfter, bobCollateralBefore + payout);
        assertEq(liabilityAfter, liabilityBefore - 1);
        assertEq(lockedAfter, lockedBefore - 1);
        assertEq(market.yesSupply(), 3);
        assertEq(market.noSupply(), 4);
        assertEq(market.yesRedeemed(), 1);
        assertEq(market.noRedeemed(), 0);
        assertEq(liabilityAfter, lockedAfter);
        assertEq(market.yesToken().balanceOf(bob), 0);

        emit log_string("classification: existing_rule");
        emit log_string("payout_recipient: bob");
        emit log_named_uint("payout", payout);
        emit log_named_uint("alice_collateral_before", aliceCollateralBefore);
        emit log_named_uint("bob_collateral_before", bobCollateralBefore);
        emit log_named_uint("alice_collateral_after", aliceCollateralAfter);
        emit log_named_uint("bob_collateral_after", bobCollateralAfter);
        emit log_named_uint("liability_before", liabilityBefore);
        emit log_named_uint("collateral_before", lockedBefore);
        emit log_named_uint("liability_after", liabilityAfter);
        emit log_named_uint("collateral_after", lockedAfter);
        emit log_named_uint("yes_supply_after", market.yesSupply());
        emit log_named_uint("no_supply_after", market.noSupply());
        emit log_named_uint("yes_redeemed_after", market.yesRedeemed());
        emit log_named_uint("no_redeemed_after", market.noRedeemed());
    }
}

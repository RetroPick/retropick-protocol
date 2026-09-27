// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Split 4 while OPEN, then redeemYes(1) before close or resolution.
/// @dev redeem, liability, and the payout formula are not edited.
contract OpenYesRedeemTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("open-yes-redeem"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_redeem_one_yes_while_open() public {
        vm.prank(alice);
        market.split(4);
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));

        uint256 liabilityBefore = market.liability();
        uint256 lockedBefore = market.collateralLocked();
        uint256 yesBefore = market.yesSupply();
        uint256 noBefore = market.noSupply();
        uint256 yesRedeemedBefore = market.yesRedeemed();
        uint256 noRedeemedBefore = market.noRedeemed();

        emit log_named_uint("liability_before", liabilityBefore);
        emit log_named_uint("collateral_before", lockedBefore);
        emit log_named_uint("yes_supply_before", yesBefore);
        emit log_named_uint("no_supply_before", noBefore);
        emit log_named_uint("yes_redeemed_before", yesRedeemedBefore);
        emit log_named_uint("no_redeemed_before", noRedeemedBefore);

        vm.prank(alice);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.redeemYes(1);

        emit log_string("solidity_accepted: false");
        emit log_string("error: BadState");
        emit log_string("payout: none");
        emit log_named_uint("liability_after", market.liability());
        emit log_named_uint("collateral_after", market.collateralLocked());
        emit log_named_uint("yes_supply_after", market.yesSupply());
        emit log_named_uint("no_supply_after", market.noSupply());
        emit log_named_uint("yes_redeemed_after", market.yesRedeemed());
        emit log_named_uint("no_redeemed_after", market.noRedeemed());
        emit log_string("classification: existing_rule");

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));
        assertEq(liabilityBefore, 4);
        assertEq(lockedBefore, 4);
        assertEq(yesBefore, 4);
        assertEq(noBefore, 4);
        assertEq(yesRedeemedBefore, 0);
        assertEq(noRedeemedBefore, 0);
        assertEq(market.liability(), 4);
        assertEq(market.collateralLocked(), 4);
        assertEq(market.yesSupply(), 4);
        assertEq(market.noSupply(), 4);
        assertEq(market.yesRedeemed(), 0);
        assertEq(market.noRedeemed(), 0);
        assertEq(market.liability(), market.collateralLocked());
    }
}

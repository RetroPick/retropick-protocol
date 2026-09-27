// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Split 4, commit YES_WIN, redeem 1 YES before openRedemption.
/// @dev resolve, redeem, and the payout formula are not edited.
contract ResolvedYesRedeemTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("resolved-yes-redeem"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_redeem_one_yes_while_resolved() public {
        vm.prank(alice);
        market.split(4);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.RESOLVED));
        assertEq(uint256(market.result()), uint256(PredictionMarket.Result.YES_WIN));

        uint256 liabilityBefore = market.liability();
        uint256 lockedBefore = market.collateralLocked();

        emit log_string("state_before: RESOLVED");
        emit log_string("open_redemption_called: false");
        emit log_named_uint("liability_before", liabilityBefore);
        emit log_named_uint("collateral_before", lockedBefore);
        emit log_named_uint("yes_supply_before", market.yesSupply());
        emit log_named_uint("no_supply_before", market.noSupply());
        emit log_named_uint("yes_redeemed_before", market.yesRedeemed());
        emit log_named_uint("no_redeemed_before", market.noRedeemed());

        vm.prank(alice);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.redeemYes(1);

        emit log_string("solidity_accepted: false");
        emit log_string("error: BadState");
        emit log_string("payout: none");
        emit log_string("state_after: RESOLVED");
        emit log_named_uint("liability_after", market.liability());
        emit log_named_uint("collateral_after", market.collateralLocked());
        emit log_string("classification: existing_rule");

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.RESOLVED));
        assertEq(liabilityBefore, 4);
        assertEq(lockedBefore, 4);
        assertEq(market.liability(), 4);
        assertEq(market.collateralLocked(), 4);
        assertEq(market.yesSupply(), 4);
        assertEq(market.noSupply(), 4);
        assertEq(market.yesRedeemed(), 0);
        assertEq(market.noRedeemed(), 0);
        assertEq(market.liability(), market.collateralLocked());
    }
}

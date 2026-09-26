// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Split 4, resolve NO_WIN, redeem 1 YES.
/// @dev redeemYes and the payout formula are not edited. burnWorthless is not called.
contract LosingYesRedeemTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("losing-yes"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_redeem_one_yes_after_no_win() public {
        vm.prank(alice);
        market.split(4);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.NO_WIN);
        vm.stopPrank();
        market.openRedemption();

        assertEq(market.collateralLocked(), 4);
        assertEq(market.yesSupply(), 4);
        assertEq(market.noSupply(), 4);
        assertEq(market.yesRedeemed(), 0);
        assertEq(market.noRedeemed(), 0);

        vm.prank(alice);
        uint256 payout = market.redeemYes(1);

        assertEq(payout, 0);
        assertEq(market.collateralLocked(), 4);
        assertEq(market.yesSupply(), 3);
        assertEq(market.noSupply(), 4);
        assertEq(market.yesRedeemed(), 1);
        assertEq(market.noRedeemed(), 0);

        emit log_string("classification: existing_rule");
        emit log_string("payout: 0");
        emit log_string("collateral_after: 4");
        emit log_string("yes_supply_after: 3");
        emit log_string("no_supply_after: 4");
        emit log_string("yes_redeemed_after: 1");
        emit log_string("no_redeemed_after: 0");
    }
}

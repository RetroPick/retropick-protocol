// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Redeemed cursors and liability before any redeem, then after redeemYes(1).
/// @dev Liability and redeem are not edited.
contract UnredeemedLiabilityTest is Test {
    uint256 internal constant SPLIT_AMOUNT = 4;

    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("unredeemed-liability"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, SPLIT_AMOUNT);
        vm.prank(alice);
        collateral.approve(address(market), SPLIT_AMOUNT);
    }

    function test_cursors_stay_zero_until_redeem_yes_one() public {
        vm.prank(alice);
        market.split(SPLIT_AMOUNT);

        assertEq(market.yesRedeemed(), 0);
        assertEq(market.noRedeemed(), 0);
        assertEq(market.collateralLocked(), SPLIT_AMOUNT);
        assertEq(market.liability(), SPLIT_AMOUNT);

        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
        market.openRedemption();

        vm.prank(alice);
        uint256 payout = market.redeemYes(1);
        assertEq(payout, 1);
        assertEq(market.yesRedeemed(), 1);
        assertEq(market.noRedeemed(), 0);
        assertEq(market.collateralLocked(), 3);
        assertEq(market.liability(), 3);

        emit log_string("classification: existing_rule");
        emit log_named_uint("yes_redeemed_after", market.yesRedeemed());
        emit log_named_uint("no_redeemed_after", market.noRedeemed());
        emit log_named_uint("collateral_locked_after", market.collateralLocked());
        emit log_named_uint("liability_after", market.liability());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Split 4, resolve YES_WIN, redeem all 4 YES from the splitter.
/// @dev liability, redeemYes, and the payout formula are not edited.
contract FullYesRedeemTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("full-yes"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_redeem_all_yes_after_yes_win() public {
        vm.prank(alice);
        market.split(4);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
        market.openRedemption();

        uint256 liabilityBefore = market.liability();
        uint256 lockedBefore = market.collateralLocked();
        uint256 yesSupplyBefore = market.yesSupply();
        uint256 noSupplyBefore = market.noSupply();
        uint256 yesRedeemedBefore = market.yesRedeemed();
        uint256 noRedeemedBefore = market.noRedeemed();

        assertEq(liabilityBefore, 4);
        assertEq(lockedBefore, 4);
        assertEq(yesSupplyBefore, 4);
        assertEq(noSupplyBefore, 4);
        assertEq(yesRedeemedBefore, 0);
        assertEq(noRedeemedBefore, 0);

        vm.prank(alice);
        uint256 payout = market.redeemYes(4);

        uint256 liabilityAfter = market.liability();
        uint256 lockedAfter = market.collateralLocked();

        assertEq(payout, 4);
        assertEq(liabilityAfter, 0);
        assertEq(lockedAfter, 0);
        assertEq(liabilityAfter, lockedAfter);
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 4);
        assertEq(market.yesRedeemed(), 4);
        assertEq(market.noRedeemed(), 0);

        emit log_string("classification: existing_rule");
        emit log_named_uint("payout", payout);
        emit log_named_uint("liability_before", liabilityBefore);
        emit log_named_uint("collateral_before", lockedBefore);
        emit log_named_uint("liability_after", liabilityAfter);
        emit log_named_uint("collateral_after", lockedAfter);
        emit log_named_uint("yes_supply_before", yesSupplyBefore);
        emit log_named_uint("no_supply_before", noSupplyBefore);
        emit log_named_uint("yes_supply_after", market.yesSupply());
        emit log_named_uint("no_supply_after", market.noSupply());
        emit log_named_uint("yes_redeemed_before", yesRedeemedBefore);
        emit log_named_uint("no_redeemed_before", noRedeemedBefore);
        emit log_named_uint("yes_redeemed_after", market.yesRedeemed());
        emit log_named_uint("no_redeemed_after", market.noRedeemed());
    }
}

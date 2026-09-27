// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Move an unsplit market to LOCKED, then attempt split(1).
/// @dev split, closeMint, liability, and the payout formula are not edited.
contract LockedSplitTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("locked-split"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_split_while_locked_reverts() public {
        vm.prank(resolver);
        market.closeMint();
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.LOCKED));
        assertEq(market.collateralLocked(), 0);
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 0);

        uint256 liabilityBefore = market.liability();
        uint256 lockedBefore = market.collateralLocked();
        uint256 yesBefore = market.yesSupply();
        uint256 noBefore = market.noSupply();
        uint256 aliceBefore = collateral.balanceOf(alice);

        assertEq(liabilityBefore, 0);
        assertEq(lockedBefore, 0);
        assertEq(yesBefore, 0);
        assertEq(noBefore, 0);
        assertEq(aliceBefore, 1_000_000);

        vm.expectRevert(PredictionMarket.BadState.selector);
        vm.prank(alice);
        market.split(1);

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.LOCKED));
        assertEq(market.liability(), liabilityBefore);
        assertEq(market.collateralLocked(), lockedBefore);
        assertEq(market.yesSupply(), yesBefore);
        assertEq(market.noSupply(), noBefore);
        assertEq(collateral.balanceOf(alice), aliceBefore);
        assertEq(market.liability(), market.collateralLocked());

        emit log_string("classification: existing_rule");
        emit log_string("solidity_rejected: true");
        emit log_string("solidity_error: BadState");
        emit log_string("collateral_pulled: 0");
        emit log_named_uint("alice_collateral_before", aliceBefore);
        emit log_named_uint("alice_collateral_after", collateral.balanceOf(alice));
        emit log_named_uint("liability_before", liabilityBefore);
        emit log_named_uint("collateral_before", lockedBefore);
        emit log_named_uint("liability_after", market.liability());
        emit log_named_uint("collateral_after", market.collateralLocked());
        emit log_named_uint("yes_supply_after", market.yesSupply());
        emit log_named_uint("no_supply_after", market.noSupply());
    }
}

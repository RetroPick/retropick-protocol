// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Leave the market in DRAFT, then resolve YES_WIN before activation.
/// @dev resolve is not edited. The market is not activated, split, or closed.
contract DraftYesResolutionTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("draft-yes-resolution"), "Yes", "YES", "No", "NO"
        );
    }

    function test_resolve_yes_win_while_draft() public {
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.DRAFT));

        uint256 liabilityBefore = market.liability();
        uint256 lockedBefore = market.collateralLocked();
        emit log_string("state_before: DRAFT");
        emit log_string("result_before: NONE");
        emit log_named_uint("liability_before", liabilityBefore);
        emit log_named_uint("collateral_before", lockedBefore);

        vm.prank(resolver);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.resolve(PredictionMarket.Result.YES_WIN);

        emit log_string("solidity_accepted: false");
        emit log_string("error: BadState");
        emit log_string("state_after: DRAFT");
        emit log_string("result_after: NONE");
        emit log_named_uint("liability_after", market.liability());
        emit log_named_uint("collateral_after", market.collateralLocked());
        emit log_string("classification: existing_rule");

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.DRAFT));
        assertEq(uint256(market.result()), uint256(PredictionMarket.Result.NONE));
        assertEq(liabilityBefore, 0);
        assertEq(lockedBefore, 0);
        assertEq(market.liability(), 0);
        assertEq(market.collateralLocked(), 0);
    }
}

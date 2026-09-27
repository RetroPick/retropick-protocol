// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Split 4 while OPEN, then resolve YES_WIN before close.
/// @dev resolve is not edited.
contract OpenYesResolutionTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("open-yes-resolution"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_resolve_yes_win_while_open() public {
        vm.prank(alice);
        market.split(4);
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));

        uint256 liabilityBefore = market.liability();
        uint256 lockedBefore = market.collateralLocked();
        emit log_string("state_before: OPEN");
        emit log_string("result_before: NONE");
        emit log_named_uint("liability_before", liabilityBefore);
        emit log_named_uint("collateral_before", lockedBefore);

        vm.prank(resolver);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.resolve(PredictionMarket.Result.YES_WIN);

        emit log_string("solidity_accepted: false");
        emit log_string("error: BadState");
        emit log_string("state_after: OPEN");
        emit log_string("result_after: NONE");
        emit log_named_uint("liability_after", market.liability());
        emit log_named_uint("collateral_after", market.collateralLocked());
        emit log_string("classification: existing_rule");

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));
        assertEq(uint256(market.result()), uint256(PredictionMarket.Result.NONE));
        assertEq(liabilityBefore, 4);
        assertEq(lockedBefore, 4);
        assertEq(market.liability(), 4);
        assertEq(market.collateralLocked(), 4);
    }
}

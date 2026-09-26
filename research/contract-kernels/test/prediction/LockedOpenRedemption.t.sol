// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Split 4, close to LOCKED, then openRedemption with no resolve.
/// @dev openRedemption and resolve are not edited.
contract LockedOpenRedemptionTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("locked-open-redemption"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_open_redemption_while_locked() public {
        vm.prank(alice);
        market.split(4);
        vm.prank(resolver);
        market.closeMint();

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.LOCKED));
        uint256 liabilityBefore = market.liability();
        uint256 lockedBefore = market.collateralLocked();
        emit log_string("state_before: LOCKED");
        emit log_named_uint("liability_before", liabilityBefore);
        emit log_named_uint("collateral_before", lockedBefore);

        vm.expectRevert(PredictionMarket.BadState.selector);
        market.openRedemption();

        emit log_string("solidity_accepted: false");
        emit log_string("error: BadState");
        emit log_string("state_after: LOCKED");
        emit log_named_uint("liability_after", market.liability());
        emit log_named_uint("collateral_after", market.collateralLocked());
        emit log_string("classification: existing_rule");

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.LOCKED));
        assertEq(uint256(market.result()), uint256(PredictionMarket.Result.NONE));
        assertEq(liabilityBefore, 4);
        assertEq(lockedBefore, 4);
        assertEq(market.liability(), 4);
        assertEq(market.collateralLocked(), 4);
    }
}

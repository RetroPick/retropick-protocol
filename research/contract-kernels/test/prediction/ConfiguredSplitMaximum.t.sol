// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice split(1000000001), one unit past the Python configured maximum.
contract ConfiguredSplitMaximumTest is Test {
    uint256 internal constant ATTEMPTED = 1_000_000_001;

    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("configured-split-maximum"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, ATTEMPTED);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_split_one_past_the_configured_maximum_mints() public {
        _assertBooks(0, 0, 0, 0);
        vm.prank(alice);
        market.split(ATTEMPTED);
        _assertBooks(ATTEMPTED, ATTEMPTED, ATTEMPTED, ATTEMPTED);
    }

    function _assertBooks(uint256 balance, uint256 locked, uint256 yesSupply, uint256 noSupply) internal view {
        assertEq(collateral.balanceOf(address(market)), balance);
        assertEq(market.collateralLocked(), locked);
        assertEq(market.yesSupply(), yesSupply);
        assertEq(market.noSupply(), noSupply);
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));
    }
}

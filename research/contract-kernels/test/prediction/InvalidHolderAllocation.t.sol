// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Negative control: aggregate INVALID conservation does not imply holder-level fairness.
contract InvalidHolderAllocationTest is Test {
    uint256 internal constant UNITS_PER_HOLDER = 10;
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);
    address internal constant RESOLVER = address(0xBEEF);

    function test_alternating_invalid_redemption_allocates_all_value_to_second_holder() public {
        MockCollateral collateral = new MockCollateral(6);
        PredictionMarket market = new PredictionMarket(
            address(collateral), RESOLVER, address(0xD057), bytes32("invalid-holder"), "Yes", "YES", "No", "NO"
        );
        market.activate();

        collateral.mint(ALICE, UNITS_PER_HOLDER);
        collateral.mint(BOB, UNITS_PER_HOLDER);
        vm.startPrank(ALICE);
        collateral.approve(address(market), UNITS_PER_HOLDER);
        market.split(UNITS_PER_HOLDER);
        vm.stopPrank();
        vm.startPrank(BOB);
        collateral.approve(address(market), UNITS_PER_HOLDER);
        market.split(UNITS_PER_HOLDER);
        vm.stopPrank();

        assertEq(collateral.balanceOf(address(market)), 2 * UNITS_PER_HOLDER);
        vm.startPrank(RESOLVER);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.INVALID);
        vm.stopPrank();
        market.openRedemption();

        uint256 alicePaid;
        uint256 bobPaid;
        for (uint256 i = 0; i < UNITS_PER_HOLDER; i++) {
            vm.prank(ALICE);
            alicePaid += market.redeemYes(1);
            vm.prank(BOB);
            bobPaid += market.redeemYes(1);
        }
        for (uint256 i = 0; i < UNITS_PER_HOLDER; i++) {
            vm.prank(ALICE);
            alicePaid += market.redeemNo(1);
            vm.prank(BOB);
            bobPaid += market.redeemNo(1);
        }

        assertEq(alicePaid, 0);
        assertEq(bobPaid, 2 * UNITS_PER_HOLDER);
        assertEq(collateral.balanceOf(ALICE), 0);
        assertEq(collateral.balanceOf(BOB), 2 * UNITS_PER_HOLDER);
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 0);
        assertEq(market.liability(), 0);
        assertEq(market.collateralLocked(), 0);
        assertEq(collateral.balanceOf(address(market)), 0);
    }
}

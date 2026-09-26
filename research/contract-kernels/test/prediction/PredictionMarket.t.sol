// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {OutcomeToken} from "../../src/prediction/OutcomeToken.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

contract PredictionMarketTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("fixture-hash"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_split_matches_fixture() public {
        vm.prank(alice);
        market.split(100);
        assertEq(market.collateralLocked(), 100);
        assertEq(market.yesSupply(), 100);
        assertEq(market.noSupply(), 100);
        assertEq(market.yesToken().balanceOf(alice), 100);
        assertEq(market.noToken().balanceOf(alice), 100);
        assertEq(uint8(market.yesToken().outcomeIndex()), 0);
        assertEq(market.yesToken().market(), address(market));
        assertEq(market.yesToken().decimals(), 6);
    }

    function test_merge_matches_fixture() public {
        vm.startPrank(alice);
        market.split(100);
        market.merge(40);
        vm.stopPrank();
        assertEq(market.collateralLocked(), 60);
        assertEq(collateral.balanceOf(alice), 1_000_000 - 60);
    }

    function test_yes_redemption_matches_fixture() public {
        vm.prank(alice);
        market.split(100);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.RESOLVED));
        vm.expectRevert(PredictionMarket.BadState.selector);
        vm.prank(alice);
        market.redeemYes(1);
        market.openRedemption();
        vm.startPrank(alice);
        uint256 yesPayout = market.redeemYes(25);
        uint256 noPayout = market.redeemNo(10);
        vm.stopPrank();
        assertEq(yesPayout, 25);
        assertEq(noPayout, 0);
        assertEq(market.collateralLocked(), 75);
        assertEq(market.yesSupply(), 75);
        assertEq(market.noSupply(), 90);
    }

    function test_invalid_cumulative_floor_matches_fixture() public {
        vm.prank(alice);
        market.split(5);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.INVALID);
        vm.stopPrank();
        market.openRedemption();
        uint256[5] memory expected = [uint256(0), 1, 0, 1, 0];
        vm.startPrank(alice);
        for (uint256 i = 0; i < 5; i++) {
            assertEq(market.redeemYes(1), expected[i]);
        }
        for (uint256 i = 0; i < 5; i++) {
            assertEq(market.redeemNo(1), expected[i]);
        }
        vm.stopPrank();
        assertEq(market.liability(), 0);
        assertEq(market.collateralLocked(), 1);
        uint256 residual = market.archive();
        assertEq(residual, 1);
        assertEq(collateral.balanceOf(dustSink), 1);
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.ARCHIVED));
    }

    function test_fee_on_transfer_split_reverts() public {
        collateral.setFeeOnTransfer(true);
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.Shortfall.selector);
        market.split(100);
        assertEq(market.yesSupply(), 0);
        assertEq(market.collateralLocked(), 0);
    }

    function test_user_cannot_mint_outcome() public {
        OutcomeToken yes = market.yesToken();
        vm.expectRevert(OutcomeToken.NotMarket.selector);
        vm.prank(alice);
        yes.mint(alice, 1);
    }

    function test_double_resolve_reverts() public {
        vm.prank(alice);
        market.split(4);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.NO_WIN);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
    }

    function testFuzz_split_merge_conserves(uint96 amount) public {
        amount = uint96(bound(amount, 1, 100_000));
        collateral.mint(alice, amount);
        vm.startPrank(alice);
        collateral.approve(address(market), amount);
        market.split(amount);
        market.merge(amount);
        vm.stopPrank();
        assertEq(market.collateralLocked(), 0);
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 0);
    }

    function testFuzz_invalid_dust_bound(uint32 amount) public {
        amount = uint32(bound(amount, 1, 500));
        collateral.mint(alice, amount);
        vm.startPrank(alice);
        collateral.approve(address(market), amount);
        market.split(amount);
        vm.stopPrank();
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.INVALID);
        vm.stopPrank();
        market.openRedemption();
        vm.startPrank(alice);
        market.redeemYes(amount);
        market.redeemNo(amount);
        vm.stopPrank();
        assertEq(market.collateralLocked(), amount % 2);
        assertEq(market.liability(), 0);
    }
}

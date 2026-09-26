// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {OutcomeToken} from "../../src/prediction/OutcomeToken.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice One executable case for each prediction invariant the kernel can perform.
/// @dev P-I05's cancelled-draft branch is not here. The kernel has no cancelDraft.
contract PredictionInvariantIdsTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);
    bytes32 internal specHash = bytes32("fixture-hash");

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(address(collateral), resolver, dustSink, specHash, "Yes", "YES", "No", "NO");
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_P_I01_supplies_match_balances() public {
        vm.prank(alice);
        market.split(40);
        assertEq(market.yesSupply(), 40);
        assertEq(market.noSupply(), 40);
        assertEq(market.yesToken().totalSupply(), 40);
        assertEq(market.noToken().totalSupply(), 40);
        assertEq(market.yesToken().balanceOf(alice), 40);
        assertEq(market.noToken().balanceOf(alice), 40);
    }

    function test_P_I02_conservation_through_resolution_pending() public {
        vm.prank(alice);
        market.split(40);
        vm.startPrank(resolver);
        market.closeMint();
        assertEq(market.yesSupply(), market.collateralLocked());
        market.beginResolution();
        vm.stopPrank();
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.RESOLUTION_PENDING));
        assertEq(market.yesSupply(), market.noSupply());
        assertEq(market.noSupply(), market.collateralLocked());
    }

    function test_P_I03_split_only_while_open_and_equal() public {
        vm.prank(alice);
        market.split(7);
        assertEq(market.yesToken().balanceOf(alice), market.noToken().balanceOf(alice));
        vm.prank(resolver);
        market.closeMint();
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.split(1);
        assertEq(market.collateralLocked(), 7);
    }

    function test_P_I04_merge_while_locked_releases_equal_collateral() public {
        vm.prank(alice);
        market.split(9);
        vm.prank(resolver);
        market.closeMint();
        uint256 beforeBalance = collateral.balanceOf(alice);
        vm.prank(alice);
        market.merge(4);
        assertEq(collateral.balanceOf(alice) - beforeBalance, 4);
        assertEq(market.yesSupply(), 5);
        assertEq(market.noSupply(), 5);
        vm.prank(resolver);
        market.beginResolution();
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.merge(1);
    }

    function test_P_I05_spec_hash_is_immutable() public {
        assertEq(market.resolutionSpecHash(), specHash);
        vm.prank(alice);
        market.split(1);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
        assertEq(market.resolutionSpecHash(), specHash);
    }

    function test_P_I06_one_result_from_pending_by_resolver() public {
        vm.prank(alice);
        market.split(3);
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.NotResolver.selector);
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.prank(resolver);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.NO_WIN);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
        assertEq(uint256(market.result()), uint256(PredictionMarket.Result.NO_WIN));
    }

    function test_P_I07_redeem_only_redeemable_balance() public {
        vm.prank(alice);
        market.split(6);
        _yesWin();
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.redeemYes(1);
        market.openRedemption();
        vm.prank(alice);
        vm.expectRevert();
        market.redeemYes(7);
        vm.prank(alice);
        assertEq(market.redeemYes(6), 6);
    }

    function test_P_I08_collateral_covers_liability() public {
        vm.prank(alice);
        market.split(8);
        assertGe(market.collateralLocked(), market.liability());
        _yesWin();
        market.openRedemption();
        vm.prank(alice);
        market.redeemYes(3);
        assertGe(market.collateralLocked(), market.liability());
    }

    function test_P_I09_no_admin_mint() public {
        OutcomeToken yes = market.yesToken();
        vm.expectRevert(OutcomeToken.NotMarket.selector);
        vm.prank(alice);
        yes.mint(alice, 1);
        vm.expectRevert(OutcomeToken.NotMarket.selector);
        vm.prank(resolver);
        yes.mint(resolver, 1);
        assertEq(yes.totalSupply(), 0);
    }

    function test_P_I10_archive_only_at_zero_supply() public {
        vm.prank(alice);
        market.split(2);
        _yesWin();
        market.openRedemption();
        vm.expectRevert(PredictionMarket.LiveSupply.selector);
        market.archive();
        vm.startPrank(alice);
        market.redeemYes(2);
        market.burnWorthless(false, 2);
        vm.stopPrank();
        uint256 residual = market.archive();
        assertEq(residual, 0);
        assertEq(market.collateralLocked(), 0);
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.ARCHIVED));
    }

    function _yesWin() internal {
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {OutcomeToken} from "../../src/prediction/OutcomeToken.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Reject and access-control paths that already exist on PredictionMarket.
/// @dev No new market behavior. `Underfunded` and `LiveLiability` are not forced:
///      the current formulas keep collateral and liability together, and a zero
///      supply implies zero liability. There is no pause and no cancelDraft.
contract PredictionBranchCoverageTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("branch-coverage"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_constructor_rejects_zero_collateral() public {
        vm.expectRevert(PredictionMarket.ZeroAddress.selector);
        new PredictionMarket(address(0), resolver, dustSink, bytes32(0), "Yes", "YES", "No", "NO");
    }

    function test_constructor_rejects_zero_resolver() public {
        vm.expectRevert(PredictionMarket.ZeroAddress.selector);
        new PredictionMarket(address(collateral), address(0), dustSink, bytes32(0), "Yes", "YES", "No", "NO");
    }

    function test_constructor_rejects_zero_dust_sink() public {
        vm.expectRevert(PredictionMarket.ZeroAddress.selector);
        new PredictionMarket(address(collateral), resolver, address(0), bytes32(0), "Yes", "YES", "No", "NO");
    }

    function test_activate_rejects_non_factory_and_repeat() public {
        PredictionMarket draft = _draft();
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.NotFactory.selector);
        draft.activate();
        assertEq(uint256(draft.state()), uint256(PredictionMarket.State.DRAFT));
        draft.activate();
        vm.expectRevert(PredictionMarket.BadState.selector);
        draft.activate();
        assertEq(uint256(draft.state()), uint256(PredictionMarket.State.OPEN));
    }

    function test_draft_rejects_split_and_merge() public {
        PredictionMarket draft = _draft();
        vm.expectRevert(PredictionMarket.BadState.selector);
        draft.split(1);
        vm.expectRevert(PredictionMarket.BadState.selector);
        draft.merge(1);
        assertEq(uint256(draft.state()), uint256(PredictionMarket.State.DRAFT));
        assertEq(draft.collateralLocked(), 0);
    }

    function test_merge_zero_rejected() public {
        vm.startPrank(alice);
        market.split(5);
        vm.expectRevert(PredictionMarket.ZeroAmount.selector);
        market.merge(0);
        vm.stopPrank();
        assertEq(market.collateralLocked(), 5);
        assertEq(market.yesSupply(), 5);
        assertEq(market.noSupply(), 5);
    }

    function test_close_mint_access_and_repeat() public {
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.NotResolver.selector);
        market.closeMint();
        vm.prank(resolver);
        market.closeMint();
        vm.prank(resolver);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.closeMint();
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.LOCKED));
    }

    function test_begin_resolution_access_and_open_state() public {
        vm.prank(resolver);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.beginResolution();
        vm.prank(resolver);
        market.closeMint();
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.NotResolver.selector);
        market.beginResolution();
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.LOCKED));
    }

    function test_resolve_none_rejected() public {
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.resolve(PredictionMarket.Result.NONE);
        vm.stopPrank();
        assertEq(uint256(market.result()), uint256(PredictionMarket.Result.NONE));
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.RESOLUTION_PENDING));
    }

    function test_open_redemption_rejects_unresolved_and_repeat() public {
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.openRedemption();
        vm.prank(alice);
        market.split(1);
        _resolve(PredictionMarket.Result.YES_WIN);
        market.openRedemption();
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.openRedemption();
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.REDEEMABLE));
    }

    function test_zero_redeem_rejected() public {
        vm.prank(alice);
        market.split(3);
        _resolve(PredictionMarket.Result.YES_WIN);
        market.openRedemption();
        vm.startPrank(alice);
        vm.expectRevert(PredictionMarket.ZeroAmount.selector);
        market.redeemYes(0);
        vm.expectRevert(PredictionMarket.ZeroAmount.selector);
        market.redeemNo(0);
        vm.stopPrank();
        assertEq(market.yesSupply(), 3);
        assertEq(market.noSupply(), 3);
        assertEq(market.collateralLocked(), 3);
    }

    function test_no_win_burns_worthless_yes_and_rejects_paying_side() public {
        vm.prank(alice);
        market.split(4);
        _resolve(PredictionMarket.Result.NO_WIN);
        vm.prank(alice);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.burnWorthless(true, 4);
        market.openRedemption();
        vm.startPrank(alice);
        vm.expectRevert(PredictionMarket.ZeroAmount.selector);
        market.burnWorthless(true, 0);
        vm.expectRevert(PredictionMarket.NotWorthless.selector);
        market.burnWorthless(false, 4);
        market.burnWorthless(true, 4);
        vm.stopPrank();
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 4);
        assertEq(market.yesNumerator(), 0);
        assertEq(market.noNumerator(), 2);
        assertEq(market.collateralLocked(), 4);
    }

    function test_archive_before_redeemable_reverts() public {
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.archive();
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));
    }

    function test_user_cannot_burn_outcome() public {
        OutcomeToken yes = market.yesToken();
        OutcomeToken no = market.noToken();
        vm.expectRevert(OutcomeToken.NotMarket.selector);
        vm.prank(alice);
        yes.burn(alice, 1);
        vm.expectRevert(OutcomeToken.NotMarket.selector);
        vm.prank(alice);
        no.burn(alice, 1);
        assertEq(yes.totalSupply(), 0);
        assertEq(no.totalSupply(), 0);
    }

    function _draft() internal returns (PredictionMarket draft) {
        MockCollateral fresh = new MockCollateral(6);
        draft = new PredictionMarket(address(fresh), resolver, dustSink, bytes32(0), "Yes", "YES", "No", "NO");
    }

    function _resolve(PredictionMarket.Result nextResult) internal {
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(nextResult);
        vm.stopPrank();
    }
}

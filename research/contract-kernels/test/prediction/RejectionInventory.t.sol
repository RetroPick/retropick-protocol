// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice One table of prediction calls that are expected to reject.
contract RejectionInventoryTest is Test {
    enum Act {
        Activate,
        Cancel,
        Split0,
        Split1,
        Merge0,
        Merge1,
        Close,
        Begin,
        Resolve,
        Open,
        RedeemYes1,
        RedeemNo1,
        RedeemYes0,
        RedeemNo0,
        BurnYes,
        BurnNo,
        Archive
    }

    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);
    uint256 internal rows;

    function setUp() public {
        collateral = new MockCollateral(6);
        collateral.mint(alice, 1_000_000);
    }

    function test_rejection_inventory() public {
        market = _deploy();
        _reject(Act.Merge1, alice, PredictionMarket.BadState.selector);
        _reject(Act.Close, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Begin, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Resolve, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Open, address(0), PredictionMarket.BadState.selector);
        _reject(Act.RedeemYes1, alice, PredictionMarket.BadState.selector);
        _reject(Act.RedeemNo1, alice, PredictionMarket.BadState.selector);
        _reject(Act.BurnYes, alice, PredictionMarket.BadState.selector);
        _reject(Act.BurnNo, alice, PredictionMarket.BadState.selector);

        PredictionMarket draft = _deploy();
        assertEq(uint256(draft.state()), uint256(PredictionMarket.State.DRAFT));
        assertEq(draft.collateralLocked(), 0);
        vm.expectRevert(PredictionMarket.BadState.selector);
        draft.archive();
        assertEq(uint256(draft.state()), uint256(PredictionMarket.State.DRAFT));
        assertEq(draft.collateralLocked(), 0);
        assertEq(draft.yesSupply(), 0);
        assertEq(draft.noSupply(), 0);
        rows++;

        market = _deploy();
        market.activate();
        vm.prank(alice);
        market.split(4);
        _reject(Act.Split0, alice, PredictionMarket.ZeroAmount.selector);
        _reject(Act.Merge0, alice, PredictionMarket.ZeroAmount.selector);
        _reject(Act.Begin, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Resolve, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Open, address(0), PredictionMarket.BadState.selector);
        _reject(Act.BurnYes, alice, PredictionMarket.BadState.selector);
        _reject(Act.BurnNo, alice, PredictionMarket.BadState.selector);

        vm.prank(resolver);
        market.closeMint();
        _reject(Act.Activate, address(0), PredictionMarket.BadState.selector);
        _reject(Act.Cancel, address(0), PredictionMarket.BadState.selector);
        _reject(Act.Merge0, alice, PredictionMarket.ZeroAmount.selector);
        _reject(Act.Close, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Resolve, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Open, address(0), PredictionMarket.BadState.selector);
        _reject(Act.RedeemYes1, alice, PredictionMarket.BadState.selector);
        _reject(Act.RedeemNo1, alice, PredictionMarket.BadState.selector);
        _reject(Act.BurnYes, alice, PredictionMarket.BadState.selector);
        _reject(Act.BurnNo, alice, PredictionMarket.BadState.selector);
        _reject(Act.Archive, address(0), PredictionMarket.BadState.selector);

        vm.prank(resolver);
        market.beginResolution();
        _reject(Act.Activate, address(0), PredictionMarket.BadState.selector);
        _reject(Act.Cancel, address(0), PredictionMarket.BadState.selector);
        _reject(Act.Split1, alice, PredictionMarket.BadState.selector);
        _reject(Act.Merge1, alice, PredictionMarket.BadState.selector);
        _reject(Act.Close, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Begin, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Open, address(0), PredictionMarket.BadState.selector);
        _reject(Act.RedeemYes1, alice, PredictionMarket.BadState.selector);
        _reject(Act.RedeemNo1, alice, PredictionMarket.BadState.selector);
        _reject(Act.BurnYes, alice, PredictionMarket.BadState.selector);
        _reject(Act.BurnNo, alice, PredictionMarket.BadState.selector);
        _reject(Act.Archive, address(0), PredictionMarket.BadState.selector);

        vm.prank(resolver);
        market.resolve(PredictionMarket.Result.YES_WIN);
        _reject(Act.Activate, address(0), PredictionMarket.BadState.selector);
        _reject(Act.Cancel, address(0), PredictionMarket.BadState.selector);
        _reject(Act.Split1, alice, PredictionMarket.BadState.selector);
        _reject(Act.Close, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Begin, resolver, PredictionMarket.BadState.selector);
        _reject(Act.BurnYes, alice, PredictionMarket.BadState.selector);
        _reject(Act.BurnNo, alice, PredictionMarket.BadState.selector);
        _reject(Act.Archive, address(0), PredictionMarket.BadState.selector);

        market.openRedemption();
        _reject(Act.Activate, address(0), PredictionMarket.BadState.selector);
        _reject(Act.Split1, alice, PredictionMarket.BadState.selector);
        _reject(Act.Merge1, alice, PredictionMarket.BadState.selector);
        _reject(Act.Close, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Begin, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Resolve, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Open, address(0), PredictionMarket.BadState.selector);
        _reject(Act.RedeemYes0, alice, PredictionMarket.ZeroAmount.selector);
        _reject(Act.RedeemNo0, alice, PredictionMarket.ZeroAmount.selector);
        _reject(Act.BurnYes, alice, PredictionMarket.NotWorthless.selector);
        _reject(Act.Archive, address(0), PredictionMarket.LiveSupply.selector);

        market = _deploy();
        market.activate();
        vm.prank(alice);
        market.split(4);
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
        market.openRedemption();
        vm.startPrank(alice);
        market.redeemYes(4);
        market.burnWorthless(false, 4);
        vm.stopPrank();
        market.archive();
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.ARCHIVED));
        assertEq(market.collateralLocked(), 0);
        _reject(Act.Activate, address(0), PredictionMarket.BadState.selector);
        _reject(Act.Cancel, address(0), PredictionMarket.BadState.selector);
        _reject(Act.Split1, alice, PredictionMarket.BadState.selector);
        _reject(Act.Merge1, alice, PredictionMarket.BadState.selector);
        _reject(Act.Close, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Begin, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Resolve, resolver, PredictionMarket.BadState.selector);
        _reject(Act.Open, address(0), PredictionMarket.BadState.selector);
        _reject(Act.RedeemYes1, alice, PredictionMarket.BadState.selector);
        _reject(Act.RedeemNo1, alice, PredictionMarket.BadState.selector);
        _reject(Act.BurnYes, alice, PredictionMarket.BadState.selector);
        _reject(Act.BurnNo, alice, PredictionMarket.BadState.selector);
        _reject(Act.Archive, address(0), PredictionMarket.BadState.selector);

        assertEq(rows, 72);
        assertEq(market.collateralLocked(), 0);
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 0);
    }

    function _deploy() internal returns (PredictionMarket deployed) {
        deployed = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("rejection-inventory"), "Yes", "YES", "No", "NO"
        );
        vm.prank(alice);
        collateral.approve(address(deployed), type(uint256).max);
    }

    function _reject(Act act, address caller, bytes4 selector) internal {
        uint256 locked = market.collateralLocked();
        uint256 yesSupply = market.yesSupply();
        uint256 noSupply = market.noSupply();
        uint8 stateBefore = uint8(market.state());
        if (caller != address(0)) vm.prank(caller);
        vm.expectRevert(selector);
        _perform(act);
        assertEq(market.collateralLocked(), locked);
        assertEq(market.yesSupply(), yesSupply);
        assertEq(market.noSupply(), noSupply);
        assertEq(uint8(market.state()), stateBefore);
        rows++;
    }

    function _perform(Act act) internal {
        if (act == Act.Activate) market.activate();
        else if (act == Act.Cancel) market.cancelDraft();
        else if (act == Act.Split0) market.split(0);
        else if (act == Act.Split1) market.split(1);
        else if (act == Act.Merge0) market.merge(0);
        else if (act == Act.Merge1) market.merge(1);
        else if (act == Act.Close) market.closeMint();
        else if (act == Act.Begin) market.beginResolution();
        else if (act == Act.Resolve) market.resolve(PredictionMarket.Result.YES_WIN);
        else if (act == Act.Open) market.openRedemption();
        else if (act == Act.RedeemYes1) market.redeemYes(1);
        else if (act == Act.RedeemNo1) market.redeemNo(1);
        else if (act == Act.RedeemYes0) market.redeemYes(0);
        else if (act == Act.RedeemNo0) market.redeemNo(0);
        else if (act == Act.BurnYes) market.burnWorthless(true, 1);
        else if (act == Act.BurnNo) market.burnWorthless(false, 1);
        else if (act == Act.Archive) market.archive();
        else revert("unhandled act");
    }
}

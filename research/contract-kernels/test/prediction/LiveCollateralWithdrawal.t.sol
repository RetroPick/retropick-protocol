// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20Errors} from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

contract LiveCollateralWithdrawalTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("live-collateral"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_no_withdrawal_while_supply_is_outstanding() public {
        vm.prank(alice);
        market.split(4);
        _assertBooks(4, 4, 4, 4);

        address factory = address(this);
        address[3] memory callers = [factory, resolver, bob];
        for (uint256 i; i < callers.length; ++i) {
            _rejectCancel(callers[i]);
            _rejectArchiveOpen(callers[i]);
            _rejectRedeemOpen(callers[i]);
            _rejectMergeWithoutTokens(callers[i]);
            _assertBooks(4, 4, 4, 4);
        }

        vm.prank(alice);
        market.merge(1);
        _assertBooks(3, 3, 3, 3);

        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
        market.openRedemption();
        _assertBooks(3, 3, 3, 3);

        for (uint256 i; i < callers.length; ++i) {
            vm.prank(callers[i]);
            vm.expectRevert(PredictionMarket.LiveSupply.selector);
            market.archive();
            _rejectRedeemWithoutTokens(callers[i]);
            _assertBooks(3, 3, 3, 3);
        }

        vm.prank(alice);
        uint256 payout = market.redeemYes(1);
        assertEq(payout, 1);
        _assertBooks(2, 2, 2, 3);
    }

    function _rejectCancel(address caller) internal {
        vm.prank(caller);
        if (caller == address(this)) vm.expectRevert(PredictionMarket.BadState.selector);
        else vm.expectRevert(PredictionMarket.NotFactory.selector);
        market.cancelDraft();
    }

    function _rejectArchiveOpen(address caller) internal {
        vm.prank(caller);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.archive();
    }

    function _rejectRedeemOpen(address caller) internal {
        vm.prank(caller);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.redeemYes(1);
        vm.prank(caller);
        vm.expectRevert(PredictionMarket.BadState.selector);
        market.redeemNo(1);
    }

    function _rejectMergeWithoutTokens(address caller) internal {
        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, caller, 0, 1));
        market.merge(1);
    }

    function _rejectRedeemWithoutTokens(address caller) internal {
        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, caller, 0, 1));
        market.redeemYes(1);
    }

    function _assertBooks(uint256 balance, uint256 locked, uint256 yesSupply, uint256 noSupply) internal view {
        assertEq(collateral.balanceOf(address(market)), balance);
        assertEq(market.collateralLocked(), locked);
        assertEq(market.yesSupply(), yesSupply);
        assertEq(market.noSupply(), noSupply);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20Errors} from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Same YES quantity redeemed twice after YES_WIN and open redemption.
contract DoubleYesRedeemTest is Test {
    uint256 internal constant QUANTITY = 4;

    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("double-yes-redeem"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1_000_000);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_second_redeem_of_the_same_yes_balance_does_not_pay() public {
        vm.prank(alice);
        market.split(QUANTITY);
        _yesWin();
        market.openRedemption();

        uint256 holderCollateralBefore = collateral.balanceOf(alice);
        _assertBooks(QUANTITY, QUANTITY, QUANTITY, QUANTITY, QUANTITY, QUANTITY);

        vm.prank(alice);
        uint256 payout = market.redeemYes(QUANTITY);
        assertEq(payout, QUANTITY);
        assertEq(collateral.balanceOf(alice), holderCollateralBefore + QUANTITY);
        _assertBooks(0, 0, 0, QUANTITY, 0, QUANTITY);

        uint256 marketBalance = collateral.balanceOf(address(market));
        uint256 locked = market.collateralLocked();
        uint256 yesSupply = market.yesSupply();
        uint256 noSupply = market.noSupply();
        uint256 holderYes = market.yesToken().balanceOf(alice);
        uint256 holderNo = market.noToken().balanceOf(alice);
        uint256 holderCollateral = collateral.balanceOf(alice);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 0, QUANTITY));
        market.redeemYes(QUANTITY);

        assertEq(collateral.balanceOf(address(market)), marketBalance);
        assertEq(market.collateralLocked(), locked);
        assertEq(market.yesSupply(), yesSupply);
        assertEq(market.noSupply(), noSupply);
        assertEq(market.yesToken().balanceOf(alice), holderYes);
        assertEq(market.noToken().balanceOf(alice), holderNo);
        assertEq(collateral.balanceOf(alice), holderCollateral);
        assertEq(market.yesRedeemed(), QUANTITY);
        _assertBooks(0, 0, 0, QUANTITY, 0, QUANTITY);
    }

    function _yesWin() internal {
        vm.startPrank(resolver);
        market.closeMint();
        market.beginResolution();
        market.resolve(PredictionMarket.Result.YES_WIN);
        vm.stopPrank();
    }

    function _assertBooks(
        uint256 balance,
        uint256 locked,
        uint256 yesSupply,
        uint256 noSupply,
        uint256 holderYes,
        uint256 holderNo
    ) internal view {
        assertEq(collateral.balanceOf(address(market)), balance);
        assertEq(market.collateralLocked(), locked);
        assertEq(market.yesSupply(), yesSupply);
        assertEq(market.noSupply(), noSupply);
        assertEq(market.yesToken().balanceOf(alice), holderYes);
        assertEq(market.noToken().balanceOf(alice), holderNo);
    }
}

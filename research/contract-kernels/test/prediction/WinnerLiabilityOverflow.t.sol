// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice A fully backed winning market can become unable to enter REDEEMABLE.
/// @dev Preserve the failing kernel behavior until a uint256-safe liability rule is accepted.
contract WinnerLiabilityOverflowTest is Test {
    uint256 internal constant FIRST_OVERFLOWING_SUPPLY = 1 << 255;
    address internal constant ALICE = address(0xA11CE);
    address internal constant RESOLVER = address(0xBEEF);
    address internal constant DUST_SINK = address(0xD057);

    function test_yes_winner_first_overflowing_supply_is_funded_but_cannot_open() public {
        _assertOverflow(PredictionMarket.Result.YES_WIN);
    }

    function test_no_winner_first_overflowing_supply_is_funded_but_cannot_open() public {
        _assertOverflow(PredictionMarket.Result.NO_WIN);
    }

    function test_supply_one_below_boundary_can_open() public {
        (MockCollateral collateral, PredictionMarket market) =
            _resolved(FIRST_OVERFLOWING_SUPPLY - 1, PredictionMarket.Result.YES_WIN);
        assertEq(collateral.balanceOf(address(market)), FIRST_OVERFLOWING_SUPPLY - 1);
        assertEq(market.liability(), FIRST_OVERFLOWING_SUPPLY - 1);
        market.openRedemption();
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.REDEEMABLE));
    }

    function _assertOverflow(PredictionMarket.Result result_) internal {
        (MockCollateral collateral, PredictionMarket market) = _resolved(FIRST_OVERFLOWING_SUPPLY, result_);
        assertEq(collateral.balanceOf(address(market)), FIRST_OVERFLOWING_SUPPLY);
        assertEq(market.collateralLocked(), FIRST_OVERFLOWING_SUPPLY);
        assertEq(market.yesSupply(), FIRST_OVERFLOWING_SUPPLY);
        assertEq(market.noSupply(), FIRST_OVERFLOWING_SUPPLY);

        bytes memory arithmeticPanic = abi.encodeWithSignature("Panic(uint256)", 0x11);
        vm.expectRevert(arithmeticPanic);
        market.liability();
        vm.expectRevert(arithmeticPanic);
        market.openRedemption();

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.RESOLVED));
        vm.expectRevert(PredictionMarket.BadState.selector);
        vm.prank(ALICE);
        market.redeemYes(1);
        assertEq(collateral.balanceOf(address(market)), FIRST_OVERFLOWING_SUPPLY);
        assertEq(market.collateralLocked(), FIRST_OVERFLOWING_SUPPLY);
    }

    function _resolved(uint256 supply, PredictionMarket.Result result_)
        internal
        returns (MockCollateral collateral, PredictionMarket market)
    {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), RESOLVER, DUST_SINK, bytes32("winner-overflow"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(ALICE, supply);
        vm.startPrank(ALICE);
        collateral.approve(address(market), supply);
        market.split(supply);
        vm.stopPrank();
        vm.startPrank(RESOLVER);
        market.closeMint();
        market.beginResolution();
        market.resolve(result_);
        vm.stopPrank();
    }
}

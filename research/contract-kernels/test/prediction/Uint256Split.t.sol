// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Split of the maximum uint256, then one more unit.
contract Uint256SplitTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("uint256-split"), "Yes", "YES", "No", "NO"
        );
        market.activate();
    }

    function test_max_split_then_one_does_not_wrap_supply() public {
        collateral.mint(alice, type(uint256).max);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);

        vm.prank(alice);
        market.split(type(uint256).max);
        _assertAtMaximum();

        // The collateral mint cannot add another unit once total supply is the maximum.
        deal(address(collateral), alice, 1);
        vm.prank(alice);
        (bool ok, bytes memory reason) = address(market).call(abi.encodeCall(PredictionMarket.split, (1)));
        assertFalse(ok);
        assertEq(reason, abi.encodeWithSelector(bytes4(0x4e487b71), uint256(0x11)));
        _assertAtMaximum();
    }

    function _assertAtMaximum() internal view {
        assertEq(collateral.balanceOf(address(market)), type(uint256).max);
        assertEq(market.collateralLocked(), type(uint256).max);
        assertEq(market.yesSupply(), type(uint256).max);
        assertEq(market.noSupply(), type(uint256).max);
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));
    }
}

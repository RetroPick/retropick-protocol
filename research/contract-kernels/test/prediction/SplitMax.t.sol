// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice The adversarial split of 2**256 after a split of 10.
/// @dev 2**256 is not a uint256 argument, so the second split is not called.
contract SplitMaxTest is Test {
    uint256 internal constant PRIOR = 10;

    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("split-max"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, PRIOR);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_split_above_uint256_is_not_called() public {
        vm.prank(alice);
        market.split(PRIOR);
        _assertBooks(PRIOR, PRIOR, PRIOR, PRIOR);

        bytes memory encoded = abi.encodeCall(PredictionMarket.split, (type(uint256).max));
        assertEq(encoded.length, 36);
        _assertBooks(PRIOR, PRIOR, PRIOR, PRIOR);
    }

    function _assertBooks(uint256 balance, uint256 locked, uint256 yesSupply, uint256 noSupply) internal view {
        assertEq(collateral.balanceOf(address(market)), balance);
        assertEq(market.collateralLocked(), locked);
        assertEq(market.yesSupply(), yesSupply);
        assertEq(market.noSupply(), noSupply);
        assertEq(uint256(market.state()), uint256(PredictionMarket.State.OPEN));
    }
}

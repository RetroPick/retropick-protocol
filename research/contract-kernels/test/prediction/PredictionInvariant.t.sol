// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Stateful checks while issuance is open. Depth is intentionally small.
contract PredictionInvariantTest is Test {
    MockCollateral internal collateral;
    PredictionMarket internal market;

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), address(this), address(0xD057), bytes32("inv"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        targetContract(address(this));
    }

    function split(uint96 amount) external {
        amount = uint96(bound(amount, 1, 1_000_000));
        collateral.mint(address(this), amount);
        collateral.approve(address(market), amount);
        market.split(amount);
    }

    function merge(uint96 amount) external {
        uint256 balance = market.yesToken().balanceOf(address(this));
        if (balance == 0) return;
        amount = uint96(bound(amount, 1, balance));
        market.merge(amount);
    }

    function invariant_preResolutionConservation() public view {
        assertEq(market.yesSupply(), market.noSupply());
        assertEq(market.yesSupply(), market.collateralLocked());
        assertGe(market.collateralLocked(), market.liability());
    }
}

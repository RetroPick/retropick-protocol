// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice Unqualified collateral also acts as resolver and mutates lifecycle during transferFrom.
contract CallbackResolverCollateral is MockCollateral {
    PredictionMarket public market;
    bool public armed;

    constructor() MockCollateral(6) {}

    function arm(PredictionMarket market_) external {
        market = market_;
        armed = true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        bool success = super.transferFrom(from, to, amount);
        if (armed) {
            armed = false;
            market.closeMint();
            market.beginResolution();
            market.resolve(PredictionMarket.Result.YES_WIN);
        }
        return success;
    }
}

contract CallbackResolverLifecycleTest is Test {
    function test_callback_commits_result_before_split_credits_supply() public {
        address alice = address(0xA11CE);
        CallbackResolverCollateral collateral = new CallbackResolverCollateral();
        PredictionMarket market = new PredictionMarket(
            address(collateral), address(collateral), address(0xD057), bytes32("callback"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, 1);
        collateral.arm(market);
        vm.startPrank(alice);
        collateral.approve(address(market), 1);
        market.split(1);
        vm.stopPrank();

        assertEq(uint256(market.state()), uint256(PredictionMarket.State.RESOLVED));
        assertEq(uint256(market.result()), uint256(PredictionMarket.Result.YES_WIN));
        assertEq(market.collateralAtResolution(), 0);
        assertEq(market.collateralLocked(), 1);
        assertEq(market.yesSupply(), 1);
        assertEq(market.noSupply(), 1);
        assertEq(collateral.balanceOf(address(market)), 1);
        assertEq(market.yesToken().balanceOf(alice), 1);

        market.openRedemption();
        vm.prank(alice);
        assertEq(market.redeemYes(1), 1);
    }
}

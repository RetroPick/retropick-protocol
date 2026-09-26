// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {OutcomeToken} from "../../src/prediction/OutcomeToken.sol";
import {PredictionMarket} from "../../src/prediction/PredictionMarket.sol";

/// @notice A non-market caller burns 1 YES after a positive split.
/// @dev OutcomeToken.burn is not edited. Python has no OutcomeToken.
contract OutsiderBurnTest is Test {
    uint256 internal constant SPLIT_AMOUNT = 4;

    MockCollateral internal collateral;
    PredictionMarket internal market;
    address internal resolver = address(0xBEEF);
    address internal dustSink = address(0xD057);
    address internal alice = address(0xA11CE);
    address internal outsider = address(0xB0B);

    function setUp() public {
        collateral = new MockCollateral(6);
        market = new PredictionMarket(
            address(collateral), resolver, dustSink, bytes32("outsider-burn"), "Yes", "YES", "No", "NO"
        );
        market.activate();
        collateral.mint(alice, SPLIT_AMOUNT);
        vm.prank(alice);
        collateral.approve(address(market), SPLIT_AMOUNT);
    }

    function test_outsider_burn_of_one_yes_leaves_supply() public {
        vm.prank(alice);
        market.split(SPLIT_AMOUNT);

        OutcomeToken yes = market.yesToken();
        assertTrue(outsider != yes.market());

        uint256 supplyBefore = yes.totalSupply();
        uint256 holderBefore = yes.balanceOf(alice);
        assertEq(supplyBefore, SPLIT_AMOUNT);
        assertEq(holderBefore, SPLIT_AMOUNT);

        vm.expectRevert(OutcomeToken.NotMarket.selector);
        vm.prank(outsider);
        yes.burn(alice, 1);

        assertEq(yes.totalSupply(), supplyBefore);
        assertEq(yes.balanceOf(alice), holderBefore);

        emit log_string("classification: existing_rule");
        emit log_string("error: NotMarket");
        emit log_named_uint("total_supply_before", supplyBefore);
        emit log_named_uint("holder_balance_before", holderBefore);
        emit log_named_uint("total_supply_after", yes.totalSupply());
        emit log_named_uint("holder_balance_after", yes.balanceOf(alice));
    }
}

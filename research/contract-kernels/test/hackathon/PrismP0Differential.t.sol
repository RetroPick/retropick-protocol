// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionFactoryP0} from "../../src/hackathon/PredictionFactoryP0.sol";
import {PredictionMarketP0} from "../../src/hackathon/PredictionMarketP0.sol";
import {PrismFactoryP0} from "../../src/hackathon/PrismFactoryP0.sol";
import {PrismSeriesP0} from "../../src/hackathon/PrismSeriesP0.sol";

contract PrismP0DifferentialTest is Test {
    MockCollateral internal collateral;
    PredictionFactoryP0 internal factory;
    PrismFactoryP0 internal prismFactory;
    PredictionMarketP0 internal market;
    PrismSeriesP0 internal series;
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        factory = new PredictionFactoryP0(address(collateral));
        prismFactory = new PrismFactoryP0(address(factory));
        market = factory.createMarket(address(0xBEEF), bytes32("fixture"), "Yes", "YES", "No", "NO");
        factory.activate(market);
        address[] memory tokens = new address[](2);
        tokens[0] = address(market.yesToken());
        tokens[1] = address(market.noToken());
        uint128[] memory numerators = new uint128[](2);
        numerators[0] = 1;
        numerators[1] = 1;
        uint128[] memory denominators = new uint128[](2);
        denominators[0] = 2;
        denominators[1] = 2;
        series = prismFactory.createSeries(
            tokens, numerators, denominators, "PRISM P0", "pP0", bytes32("payoff"), bytes32("replication")
        );

        collateral.mint(alice, 10_000_000);
        vm.startPrank(alice);
        collateral.approve(address(market), 10_000_000);
        market.split(10_000_000);
        market.yesToken().approve(address(series), type(uint256).max);
        market.noToken().approve(address(series), type(uint256).max);
        vm.stopPrank();
    }

    function test_fixtureAmountsAndPostStateMatchSolidity() public {
        string memory fixture = vm.readFile("../hackathon-p0/fixtures/prism_p0_exact_lot.json");
        uint256 lot = vm.parseJsonUint(fixture, ".lot_size_raw");
        uint256 amount = vm.parseJsonUint(fixture, ".sample_mint.prism_amount_raw");
        uint256 yesAmount = vm.parseJsonUint(fixture, ".sample_mint.component_amounts_raw[0]");
        uint256 noAmount = vm.parseJsonUint(fixture, ".sample_mint.component_amounts_raw[1]");
        bool validLot = vm.parseJsonBool(fixture, ".sample_mint.valid_lot_multiple");

        assertTrue(validLot);
        assertEq(series.lotSizeRaw(), lot);
        assertEq(series.componentAmount(amount, 0), yesAmount);
        assertEq(series.componentAmount(amount, 1), noAmount);
        vm.prank(alice);
        series.mint(amount, alice);
        assertEq(series.totalSupply(), amount);
        assertEq(series.balanceOf(alice), amount);
        assertEq(market.yesToken().balanceOf(address(series)), yesAmount);
        assertEq(market.noToken().balanceOf(address(series)), noAmount);
        assertEq(series.requiredBacking(series.totalSupply(), 0), yesAmount);
        assertEq(series.requiredBacking(series.totalSupply(), 1), noAmount);
    }
}

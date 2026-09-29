// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {OutcomeTokenP0} from "../../src/hackathon/OutcomeTokenP0.sol";
import {PredictionFactoryP0} from "../../src/hackathon/PredictionFactoryP0.sol";
import {PredictionMarketP0} from "../../src/hackathon/PredictionMarketP0.sol";
import {PrismFactoryP0} from "../../src/hackathon/PrismFactoryP0.sol";
import {PrismSeriesP0} from "../../src/hackathon/PrismSeriesP0.sol";

/// @notice End-to-end local solvency witness independent of Kuru and indexer services.
contract CrossModuleP0Test is Test {
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);
    address internal constant RESOLVER = address(0xBEEF);

    struct World {
        MockCollateral collateral;
        PredictionFactoryP0 predictionFactory;
        PrismFactoryP0 prismFactory;
        PredictionMarketP0 market;
        OutcomeTokenP0 yes;
        OutcomeTokenP0 no;
        PrismSeriesP0 series;
    }

    function test_yesWinWorldPredictionToPrismAndBack() public {
        _runWorld(true);
    }

    function test_noWinWorldPredictionToPrismAndBack() public {
        _runWorld(false);
    }

    function _runWorld(bool yesWins) internal {
        string memory fixture = vm.readFile("../hackathon-p0/fixtures/cross_module_p0_lifecycle.json");
        World memory world = _newWorld(fixture);
        _mintAndTransfer(world, fixture);
        _redeemPrism(world, fixture);
        _resolveAndRedeem(world, fixture, yesWins);
    }

    function _newWorld(string memory fixture) internal returns (World memory world) {
        world.collateral = new MockCollateral(6);
        world.predictionFactory = new PredictionFactoryP0(address(world.collateral));
        world.prismFactory = new PrismFactoryP0(address(world.predictionFactory));
        world.market = world.predictionFactory.createMarket(
            RESOLVER, bytes32("cross-module-p0"), "YES", "YES", "NO", "NO"
        );
        world.predictionFactory.activate(world.market);
        world.yes = world.market.yesToken();
        world.no = world.market.noToken();

        uint256 splitAmount = vm.parseJsonUint(fixture, ".prediction.split_raw");
        world.collateral.mint(ALICE, splitAmount);
        vm.startPrank(ALICE);
        world.collateral.approve(address(world.market), splitAmount);
        world.market.split(splitAmount);
        vm.stopPrank();

        world.series = _createSeries(world);
        assertTrue(world.prismFactory.isSeries(address(world.series)));
        assertEq(world.series.decimals(), world.collateral.decimals());
        assertEq(world.series.collateral(), address(world.collateral));
        PrismSeriesP0.Component memory source = world.series.component(0);
        assertEq(source.token, address(world.yes));
        assertEq(source.market, address(world.market));
        assertEq(source.outcomeIndex, 0);
        assertEq(source.resolutionSpecHash, bytes32("cross-module-p0"));
    }

    function _createSeries(World memory world) internal returns (PrismSeriesP0) {
        address[] memory tokens = new address[](2);
        tokens[0] = address(world.yes);
        tokens[1] = address(world.no);
        uint128[] memory numerators = new uint128[](2);
        numerators[0] = 1;
        numerators[1] = 1;
        uint128[] memory denominators = new uint128[](2);
        denominators[0] = 2;
        denominators[1] = 2;
        return world.prismFactory.createSeries(
            tokens,
            numerators,
            denominators,
            "PRISM 50/50 outcomes",
            "pYESNO",
            keccak256("h=0.5*YES+0.5*NO"),
            keccak256("exact-rational-certificate-v1")
        );
    }

    function _mintAndTransfer(World memory world, string memory fixture) internal {
        uint256 prismMintAmount = vm.parseJsonUint(fixture, ".prism.mint_raw");
        vm.startPrank(ALICE);
        world.yes.approve(address(world.series), type(uint256).max);
        world.no.approve(address(world.series), type(uint256).max);
        world.series.mint(prismMintAmount, ALICE);
        world.series.transfer(BOB, vm.parseJsonUint(fixture, ".prism.transfer_to_bob_raw"));
        vm.stopPrank();
        assertEq(world.market.liability(), vm.parseJsonUint(fixture, ".prediction.liability_after_split_raw"));
        assertEq(
            world.collateral.balanceOf(address(world.market)),
            vm.parseJsonUint(fixture, ".prediction.physical_collateral_after_split_raw")
        );
        assertEq(world.market.yesSupply(), vm.parseJsonUint(fixture, ".prediction.yes_supply_before_prism"));
        assertEq(world.market.noSupply(), vm.parseJsonUint(fixture, ".prediction.no_supply_before_prism"));
        assertEq(
            world.yes.balanceOf(address(world.series)),
            vm.parseJsonUint(fixture, ".prism.component_amounts_raw[0]")
        );
        assertEq(
            world.no.balanceOf(address(world.series)),
            vm.parseJsonUint(fixture, ".prism.component_amounts_raw[1]")
        );
        assertEq(world.series.totalSupply(), prismMintAmount);
    }

    function _redeemPrism(World memory world, string memory fixture) internal {
        vm.prank(BOB);
        world.series.redeemInKind(vm.parseJsonUint(fixture, ".prism.bob_redeem_raw"), BOB);
        vm.prank(ALICE);
        world.series.redeemInKind(vm.parseJsonUint(fixture, ".prism.alice_redeem_raw"), ALICE);
        assertEq(world.series.totalSupply(), 0);
        assertEq(world.yes.balanceOf(address(world.series)), 0);
        assertEq(world.no.balanceOf(address(world.series)), 0);
        assertEq(world.yes.balanceOf(BOB), vm.parseJsonUint(fixture, ".prism.bob_received_components_raw[0]"));
        assertEq(world.no.balanceOf(BOB), vm.parseJsonUint(fixture, ".prism.bob_received_components_raw[1]"));
        assertEq(world.yes.balanceOf(ALICE), vm.parseJsonUint(fixture, ".after_prism_redemption.alice_yes_raw"));
        assertEq(world.no.balanceOf(ALICE), vm.parseJsonUint(fixture, ".after_prism_redemption.alice_no_raw"));
        assertEq(world.market.liability(), vm.parseJsonUint(fixture, ".after_prism_redemption.prediction_liability_raw"));
        assertEq(
            world.collateral.balanceOf(address(world.market)),
            vm.parseJsonUint(fixture, ".after_prism_redemption.prediction_collateral_raw")
        );
    }

    function _resolveAndRedeem(World memory world, string memory fixture, bool yesWins) internal {
        vm.startPrank(RESOLVER);
        world.market.closeMint();
        world.market.resolve(yesWins ? PredictionMarketP0.Result.YES_WIN : PredictionMarketP0.Result.NO_WIN);
        vm.stopPrank();
        world.market.openRedemption();

        string memory resultName = yesWins ? "YES_WIN" : "NO_WIN";
        string memory alicePath = string.concat(".resolution_worlds.", resultName, ".alice_winner_redeem_raw");
        string memory bobPath = string.concat(".resolution_worlds.", resultName, ".bob_winner_redeem_raw");
        uint256 aliceAmount = vm.parseJsonUint(fixture, alicePath);
        uint256 bobAmount = vm.parseJsonUint(fixture, bobPath);
        uint256 aliceBefore = world.collateral.balanceOf(ALICE);
        uint256 bobBefore = world.collateral.balanceOf(BOB);
        vm.prank(ALICE);
        uint256 alicePaid = yesWins ? world.market.redeemYes(aliceAmount) : world.market.redeemNo(aliceAmount);
        vm.prank(BOB);
        uint256 bobPaid = yesWins ? world.market.redeemYes(bobAmount) : world.market.redeemNo(bobAmount);

        assertEq(alicePaid, aliceAmount);
        assertEq(bobPaid, bobAmount);
        assertEq(world.collateral.balanceOf(ALICE) - aliceBefore, alicePaid);
        assertEq(world.collateral.balanceOf(BOB) - bobBefore, bobPaid);
        string memory remainingPath = string.concat(
            ".resolution_worlds.", resultName, ".remaining_prediction_liability_raw"
        );
        assertEq(world.market.liability(), vm.parseJsonUint(fixture, remainingPath));
        assertGe(world.collateral.balanceOf(address(world.market)), world.market.liability());
        assertEq(world.series.totalSupply(), 0);
    }
}

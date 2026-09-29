// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {OutcomeTokenP0} from "../../src/hackathon/OutcomeTokenP0.sol";
import {PredictionFactoryP0} from "../../src/hackathon/PredictionFactoryP0.sol";
import {PredictionMarketP0} from "../../src/hackathon/PredictionMarketP0.sol";
import {PrismFactoryP0} from "../../src/hackathon/PrismFactoryP0.sol";
import {PrismSeriesP0} from "../../src/hackathon/PrismSeriesP0.sol";

contract PrismP0Test is Test {
    MockCollateral internal collateral;
    PredictionFactoryP0 internal factory;
    PrismFactoryP0 internal prismFactory;
    PredictionMarketP0 internal market;
    OutcomeTokenP0 internal yes;
    OutcomeTokenP0 internal no;
    PrismSeriesP0 internal series;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal resolver = address(0xBEEF);

    function setUp() public {
        collateral = new MockCollateral(6);
        factory = new PredictionFactoryP0(address(collateral));
        prismFactory = new PrismFactoryP0(address(factory));
        market = factory.createMarket(resolver, bytes32("p0-source"), "Yes", "YES", "No", "NO");
        factory.activate(market);
        yes = market.yesToken();
        no = market.noToken();
        series = _series(address(yes), address(no), 1, 2, 1, 2);

        collateral.mint(alice, 100_000_000);
        vm.startPrank(alice);
        collateral.approve(address(market), type(uint256).max);
        market.split(20_000_000);
        yes.approve(address(series), type(uint256).max);
        no.approve(address(series), type(uint256).max);
        vm.stopPrank();
    }

    function _series(address first, address second, uint128 n0, uint128 d0, uint128 n1, uint128 d1)
        internal
        returns (PrismSeriesP0)
    {
        address[] memory tokens = new address[](2);
        tokens[0] = first;
        tokens[1] = second;
        uint128[] memory numerators = new uint128[](2);
        numerators[0] = n0;
        numerators[1] = n1;
        uint128[] memory denominators = new uint128[](2);
        denominators[0] = d0;
        denominators[1] = d1;
        return prismFactory.createSeries(
            tokens, numerators, denominators, "PRISM P0", "pP0", bytes32("payoff"), bytes32("replication")
        );
    }

    function test_exactLotMintTransferAndInKindRedemption() public {
        assertEq(series.decimals(), 6);
        assertEq(series.lotSizeRaw(), 2);
        assertEq(series.componentAmount(10_000_000, 0), 5_000_000);
        assertEq(series.componentAmount(10_000_000, 1), 5_000_000);

        vm.prank(alice);
        series.mint(10_000_000, alice);
        assertEq(series.totalSupply(), 10_000_000);
        assertEq(series.balanceOf(alice), 10_000_000);
        assertEq(yes.balanceOf(address(series)), 5_000_000);
        assertEq(no.balanceOf(address(series)), 5_000_000);
        assertEq(series.requiredBacking(series.totalSupply(), 0), yes.balanceOf(address(series)));
        assertEq(series.requiredBacking(series.totalSupply(), 1), no.balanceOf(address(series)));

        vm.prank(alice);
        series.transfer(bob, 6_000_000);
        vm.prank(bob);
        series.redeemInKind(6_000_000, bob);

        assertEq(series.balanceOf(alice), 4_000_000);
        assertEq(series.balanceOf(bob), 0);
        assertEq(yes.balanceOf(bob), 3_000_000);
        assertEq(no.balanceOf(bob), 3_000_000);
        assertEq(yes.balanceOf(address(series)), 2_000_000);
        assertEq(no.balanceOf(address(series)), 2_000_000);
        assertEq(series.totalSupply(), 4_000_000);
    }

    function test_nontrivialReducedWeightsUseSmallestExactLot() public {
        PrismSeriesP0 thirds = _series(address(yes), address(no), 2, 6, 4, 6);
        assertEq(thirds.lotSizeRaw(), 3);
        assertEq(thirds.componentAmount(9, 0), 3);
        assertEq(thirds.componentAmount(9, 1), 6);
    }

    function test_invalidLotRejectsBeforeTakingComponents() public {
        uint256 yesBefore = yes.balanceOf(address(series));
        uint256 noBefore = no.balanceOf(address(series));
        vm.expectRevert(abi.encodeWithSelector(PrismSeriesP0.InvalidLot.selector, 3, 2));
        vm.prank(alice);
        series.mint(3, alice);
        assertEq(yes.balanceOf(address(series)), yesBefore);
        assertEq(no.balanceOf(address(series)), noBefore);
        assertEq(series.totalSupply(), 0);
    }

    function test_unalignedRedemptionRejectsWithoutBurnOrTransfer() public {
        vm.prank(alice);
        series.mint(2, alice);
        uint256 supplyBefore = series.totalSupply();
        uint256 yesBefore = yes.balanceOf(address(series));
        uint256 noBefore = no.balanceOf(address(series));
        vm.expectRevert(abi.encodeWithSelector(PrismSeriesP0.InvalidLot.selector, 3, 2));
        vm.prank(alice);
        series.redeemInKind(3, alice);
        assertEq(series.totalSupply(), supplyBefore);
        assertEq(yes.balanceOf(address(series)), yesBefore);
        assertEq(no.balanceOf(address(series)), noBefore);
    }

    function test_aDonationCannotFundAnotherMintersMint() public {
        vm.startPrank(alice);
        yes.transfer(address(series), 1);
        no.transfer(address(series), 1);
        vm.stopPrank();

        uint256 supplyBefore = series.totalSupply();
        vm.expectRevert();
        vm.prank(bob);
        series.mint(2, bob);
        assertEq(series.totalSupply(), supplyBefore);
        assertEq(series.balanceOf(bob), 0);
        assertEq(yes.balanceOf(address(series)), 1);
        assertEq(no.balanceOf(address(series)), 1);
    }

    function test_rejectDuplicateZeroAndMoreThanFourComponents() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(yes);
        tokens[1] = address(yes);
        uint128[] memory nums = new uint128[](2);
        nums[0] = 1;
        nums[1] = 1;
        uint128[] memory dens = new uint128[](2);
        dens[0] = 2;
        dens[1] = 2;
        vm.expectRevert(abi.encodeWithSelector(PrismSeriesP0.DuplicateComponent.selector, address(yes)));
        prismFactory.createSeries(tokens, nums, dens, "dup", "DUP", bytes32("p"), bytes32("r"));

        tokens[1] = address(no);
        nums[1] = 0;
        vm.expectRevert(abi.encodeWithSelector(PrismSeriesP0.InvalidWeight.selector, 1));
        prismFactory.createSeries(tokens, nums, dens, "zero", "ZERO", bytes32("p"), bytes32("r"));

        address[] memory many = new address[](5);
        uint128[] memory manyNums = new uint128[](5);
        uint128[] memory manyDens = new uint128[](5);
        for (uint256 i; i < 5; ++i) {
            many[i] = address(uint160(i + 1));
            manyNums[i] = 1;
            manyDens[i] = 1;
        }
        vm.expectRevert(abi.encodeWithSelector(PrismSeriesP0.BadComponentCount.selector, 5));
        prismFactory.createSeries(many, manyNums, manyDens, "many", "MANY", bytes32("p"), bytes32("r"));
    }

    function test_unregisteredTokenCannotBeAdmitted() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(collateral);
        uint128[] memory nums = new uint128[](1);
        nums[0] = 1;
        uint128[] memory dens = new uint128[](1);
        dens[0] = 1;
        vm.expectRevert();
        prismFactory.createSeries(tokens, nums, dens, "fake", "FAKE", bytes32("p"), bytes32("r"));
    }

    function test_unregisteredOutcomeCloneForRealMarketCannotBeAdmitted() public {
        OutcomeTokenP0 clone = new OutcomeTokenP0(address(market), 0, "Clone", "CLONE", 6);
        address[] memory tokens = new address[](1);
        tokens[0] = address(clone);
        uint128[] memory nums = new uint128[](1);
        nums[0] = 1;
        uint128[] memory dens = new uint128[](1);
        dens[0] = 1;
        vm.expectRevert(
            abi.encodeWithSelector(PrismSeriesP0.SourceConfigurationMismatch.selector, address(clone))
        );
        prismFactory.createSeries(tokens, nums, dens, "clone", "CLONE", bytes32("p"), bytes32("r"));
    }

    function test_onlyFixedSeriesCreatorCanAdmitSeries() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(yes);
        uint128[] memory nums = new uint128[](1);
        nums[0] = 1;
        uint128[] memory dens = new uint128[](1);
        dens[0] = 1;
        vm.expectRevert(PrismFactoryP0.NotSeriesCreator.selector);
        vm.prank(alice);
        prismFactory.createSeries(tokens, nums, dens, "unauthorized", "BAD", bytes32("p"), bytes32("r"));
    }

    function test_directDonationIsSurplusAndNotSweepable() public {
        vm.prank(alice);
        yes.transfer(address(series), 1);
        assertEq(yes.balanceOf(address(series)), 1);
        assertEq(series.totalSupply(), 0);
        (bool success,) = address(series).call(abi.encodeWithSignature("sweepSettlementDust()"));
        assertFalse(success);
        (success,) = address(series).call(abi.encodeWithSignature("settleCash()"));
        assertFalse(success);
        (success,) = address(series).call(abi.encodeWithSignature("deposit(uint256)"));
        assertFalse(success);
        (success,) = address(series).call(abi.encodeWithSignature("mint(address,uint256)", alice, 1));
        assertFalse(success);
        (success,) = address(series).call(abi.encodeWithSignature("burn(address,uint256)", alice, 1));
        assertFalse(success);
    }
}

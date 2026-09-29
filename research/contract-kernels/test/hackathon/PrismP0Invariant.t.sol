// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {OutcomeTokenP0} from "../../src/hackathon/OutcomeTokenP0.sol";
import {PredictionFactoryP0} from "../../src/hackathon/PredictionFactoryP0.sol";
import {PredictionMarketP0} from "../../src/hackathon/PredictionMarketP0.sol";
import {PrismFactoryP0} from "../../src/hackathon/PrismFactoryP0.sol";
import {PrismSeriesP0} from "../../src/hackathon/PrismSeriesP0.sol";

contract PrismP0Actor {
    function transfer(PrismSeriesP0 series, address receiver, uint256 amount) external {
        series.transfer(receiver, amount);
    }

    function redeem(PrismSeriesP0 series, uint256 amount) external {
        series.redeemInKind(amount, address(this));
    }
}

contract PrismP0Handler {
    MockCollateral public immutable collateral;
    PredictionMarketP0 public immutable market;
    OutcomeTokenP0 public immutable yes;
    OutcomeTokenP0 public immutable no;
    PrismSeriesP0 public immutable series;
    PrismP0Actor[3] public actors;

    constructor(MockCollateral collateral_, PredictionMarketP0 market_, PrismSeriesP0 series_) {
        collateral = collateral_;
        market = market_;
        yes = market_.yesToken();
        no = market_.noToken();
        series = series_;
        actors[0] = new PrismP0Actor();
        actors[1] = new PrismP0Actor();
        actors[2] = new PrismP0Actor();
        collateral_.approve(address(market_), type(uint256).max);
        yes.approve(address(series_), type(uint256).max);
        no.approve(address(series_), type(uint256).max);
    }

    function mint(uint96 seedAmount, uint8 receiverIndex) external {
        uint256 amount = uint256(seedAmount) % 1_000_000;
        amount &= ~uint256(1);
        if (amount == 0) amount = 2;
        market.split(amount / 2);
        series.mint(amount, address(actors[receiverIndex % 3]));
    }

    function transfer(uint96 seedAmount, uint8 senderIndex, uint8 receiverIndex) external {
        uint256 amount = (uint256(seedAmount) % 1_000_000) & ~uint256(1);
        if (amount == 0) amount = 2;
        PrismP0Actor sender = actors[senderIndex % 3];
        PrismP0Actor receiver = actors[receiverIndex % 3];
        if (sender == receiver || series.balanceOf(address(sender)) < amount) return;
        sender.transfer(series, address(receiver), amount);
    }

    function redeem(uint96 seedAmount, uint8 actorIndex) external {
        uint256 amount = (uint256(seedAmount) % 1_000_000) & ~uint256(1);
        if (amount == 0) amount = 2;
        PrismP0Actor actor = actors[actorIndex % 3];
        if (series.balanceOf(address(actor)) < amount) return;
        actor.redeem(series, amount);
    }

    function donateOne(uint8 side) external {
        market.split(1);
        if (side % 2 == 0) yes.transfer(address(series), 1);
        else no.transfer(address(series), 1);
    }

    function rejectUnalignedMint() external {
        (bool success,) = address(series).call(abi.encodeCall(series.mint, (1, address(this))));
        require(!success, "unaligned mint unexpectedly succeeded");
    }

    function rejectUnalignedRedeem() external {
        (bool success,) = address(series).call(abi.encodeCall(series.redeemInKind, (1, address(this))));
        require(!success, "unaligned redemption unexpectedly succeeded");
    }
}

contract PrismP0InvariantTest is StdInvariant, Test {
    MockCollateral internal collateral;
    PredictionFactoryP0 internal factory;
    PrismFactoryP0 internal prismFactory;
    PredictionMarketP0 internal market;
    PrismSeriesP0 internal series;
    PrismP0Handler internal handler;

    function setUp() public {
        collateral = new MockCollateral(6);
        factory = new PredictionFactoryP0(address(collateral));
        prismFactory = new PrismFactoryP0(address(factory));
        market = factory.createMarket(address(0xBEEF), bytes32("inv"), "Yes", "YES", "No", "NO");
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
            tokens, numerators, denominators, "PRISM", "pP0", bytes32("payoff"), bytes32("replication")
        );
        handler = new PrismP0Handler(collateral, market, series);
        collateral.mint(address(handler), type(uint128).max);
        targetContract(address(handler));
    }

    function invariant_physicalBackingCoversSupplyAndClaimBalancesConserveSupply() public view {
        uint256 requiredYes = series.requiredBacking(series.totalSupply(), 0);
        uint256 requiredNo = series.requiredBacking(series.totalSupply(), 1);
        assertGe(market.yesToken().balanceOf(address(series)), requiredYes);
        assertGe(market.noToken().balanceOf(address(series)), requiredNo);
        uint256 representedSupply;
        for (uint256 i; i < 3; ++i) representedSupply += series.balanceOf(address(handler.actors(i)));
        assertEq(representedSupply, series.totalSupply());
        assertEq(market.yesSupply(), market.noSupply());
        assertGe(collateral.balanceOf(address(market)), market.liability());
    }
}

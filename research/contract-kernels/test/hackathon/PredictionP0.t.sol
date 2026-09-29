// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {OutcomeTokenP0} from "../../src/hackathon/OutcomeTokenP0.sol";
import {PredictionFactoryP0} from "../../src/hackathon/PredictionFactoryP0.sol";
import {PredictionMarketP0} from "../../src/hackathon/PredictionMarketP0.sol";

contract CallbackCollateralP0 is MockCollateral {
    LifecycleAttackResolver public attackResolver;
    PredictionMarketP0 public market;
    bool public armed;

    constructor() MockCollateral(6) {}

    function arm(LifecycleAttackResolver resolver_, PredictionMarketP0 market_) external {
        attackResolver = resolver_;
        market = market_;
        armed = true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        bool success = super.transferFrom(from, to, amount);
        if (armed) {
            armed = false;
            attackResolver.closeMintDuringTransfer(market);
        }
        return success;
    }
}

contract LifecycleAttackResolver {
    function closeMintDuringTransfer(PredictionMarketP0 market) external {
        market.closeMint();
    }
}

contract PredictionP0Test is Test {
    MockCollateral internal collateral;
    PredictionFactoryP0 internal factory;
    PredictionMarketP0 internal market;
    address internal resolver = address(0xBEEF);
    address internal alice = address(0xA11CE);

    function setUp() public {
        collateral = new MockCollateral(6);
        factory = new PredictionFactoryP0(address(collateral));
        market = factory.createMarket(resolver, bytes32("p0"), "Yes P0", "YES0", "No P0", "NO0");
        factory.activate(market);
        collateral.mint(alice, type(uint128).max);
        vm.prank(alice);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_binaryDomainRejectsNoneResult() public {
        vm.prank(alice);
        market.split(1);
        vm.prank(resolver);
        market.closeMint();
        vm.expectRevert(PredictionMarketP0.BadState.selector);
        vm.prank(resolver);
        market.resolve(PredictionMarketP0.Result.NONE);
        assertEq(uint256(market.result()), uint256(PredictionMarketP0.Result.NONE));
        assertEq(uint256(market.state()), uint256(PredictionMarketP0.State.LOCKED));
    }

    function test_completeSetIssuanceUsesExactReceipt() public {
        vm.prank(alice);
        market.split(100);
        assertEq(market.collateralLocked(), 100);
        assertEq(market.yesSupply(), 100);
        assertEq(market.noSupply(), 100);
        assertEq(market.yesToken().balanceOf(alice), 100);
        assertEq(market.noToken().balanceOf(alice), 100);
        assertEq(collateral.balanceOf(address(market)), 100);
        assertEq(market.liability(), 100);
    }

    function test_zeroSplitRejectsWithoutChangingState() public {
        vm.expectRevert(PredictionMarketP0.ZeroAmount.selector);
        vm.prank(alice);
        market.split(0);
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 0);
        assertEq(market.collateralLocked(), 0);
        assertEq(collateral.balanceOf(address(market)), 0);
    }

    function test_feeOnTransferCollateralCannotIssue() public {
        collateral.setFeeOnTransfer(true);
        vm.expectRevert(PredictionMarketP0.Shortfall.selector);
        vm.prank(alice);
        market.split(100);
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 0);
        assertEq(market.collateralLocked(), 0);
        assertEq(collateral.balanceOf(address(market)), 0);
    }

    function test_supplyCapBoundary() public {
        uint256 max = market.MAX_OUTCOME_SUPPLY();
        vm.prank(alice);
        market.split(max);
        assertEq(market.yesSupply(), max);
        assertEq(market.noSupply(), max);

        vm.expectRevert(abi.encodeWithSelector(PredictionMarketP0.SupplyCapExceeded.selector, max, uint256(1), max));
        vm.prank(alice);
        market.split(1);
    }

    function test_supplyCapRejectsAmountAboveMaxBeforeTransfer() public {
        uint256 max = market.MAX_OUTCOME_SUPPLY();
        vm.expectRevert(abi.encodeWithSelector(PredictionMarketP0.SupplyCapExceeded.selector, uint256(0), max + 1, max));
        vm.prank(alice);
        market.split(max + 1);
        assertEq(collateral.balanceOf(address(market)), 0);
    }

    function test_exactWinnerRedemptionDoesNotOverflowAtCap() public {
        uint256 max = market.MAX_OUTCOME_SUPPLY();
        vm.prank(alice);
        market.split(max);

        vm.startPrank(resolver);
        market.closeMint();
        market.resolve(PredictionMarketP0.Result.YES_WIN);
        vm.stopPrank();

        assertEq(market.liability(), max);
        market.openRedemption();
        vm.prank(alice);
        assertEq(market.redeemYes(max), max);
        assertEq(market.liability(), 0);
        assertEq(market.collateralLocked(), 0);
        assertEq(collateral.balanceOf(address(market)), 0);
    }

    function test_mergeRejectsNonExactOutboundCollateral() public {
        vm.prank(alice);
        market.split(100);
        uint256 aliceBefore = collateral.balanceOf(alice);
        collateral.setFeeOnTransfer(true);

        vm.expectRevert(
            abi.encodeWithSelector(PredictionMarketP0.NonExactCollateralTransfer.selector, 100, 100, 99)
        );
        vm.prank(alice);
        market.merge(100);

        assertEq(market.yesSupply(), 100);
        assertEq(market.noSupply(), 100);
        assertEq(market.collateralLocked(), 100);
        assertEq(collateral.balanceOf(address(market)), 100);
        assertEq(collateral.balanceOf(alice), aliceBefore);
        assertEq(market.yesToken().balanceOf(alice), 100);
        assertEq(market.noToken().balanceOf(alice), 100);
    }

    function test_winnerRedemptionRejectsNonExactOutboundCollateral() public {
        vm.prank(alice);
        market.split(100);
        vm.startPrank(resolver);
        market.closeMint();
        market.resolve(PredictionMarketP0.Result.YES_WIN);
        vm.stopPrank();
        market.openRedemption();
        uint256 aliceBefore = collateral.balanceOf(alice);
        collateral.setFeeOnTransfer(true);

        vm.expectRevert(
            abi.encodeWithSelector(PredictionMarketP0.NonExactCollateralTransfer.selector, 100, 100, 99)
        );
        vm.prank(alice);
        market.redeemYes(100);

        assertEq(market.yesSupply(), 100);
        assertEq(market.collateralLocked(), 100);
        assertEq(market.liability(), 100);
        assertEq(collateral.balanceOf(address(market)), 100);
        assertEq(collateral.balanceOf(alice), aliceBefore);
        assertEq(market.yesToken().balanceOf(alice), 100);
    }

    function testFuzz_binaryWinnerReceivesExactlyBurnedAmount(uint128 rawAmount, bool yesWins) public {
        uint256 amount = bound(uint256(rawAmount), 1, market.MAX_OUTCOME_SUPPLY());
        vm.prank(alice);
        market.split(amount);

        vm.startPrank(resolver);
        market.closeMint();
        market.resolve(yesWins ? PredictionMarketP0.Result.YES_WIN : PredictionMarketP0.Result.NO_WIN);
        vm.stopPrank();
        market.openRedemption();

        uint256 balanceBefore = collateral.balanceOf(alice);
        uint256 payout;
        if (yesWins) {
            vm.prank(alice);
            payout = market.redeemYes(amount);
        } else {
            vm.prank(alice);
            payout = market.redeemNo(amount);
        }
        assertEq(payout, amount);
        assertEq(collateral.balanceOf(alice) - balanceBefore, amount);
        assertEq(market.liability(), 0);
        assertEq(collateral.balanceOf(address(market)), 0);
    }

    function test_losingSideCannotRedeemButCanBurn() public {
        vm.prank(alice);
        market.split(10);
        vm.startPrank(resolver);
        market.closeMint();
        market.resolve(PredictionMarketP0.Result.NO_WIN);
        vm.stopPrank();
        market.openRedemption();

        vm.expectRevert(PredictionMarketP0.NotWinner.selector);
        vm.prank(alice);
        market.redeemYes(1);

        vm.prank(alice);
        market.burnWorthless(true, 10);
        assertEq(market.yesSupply(), 0);
        assertEq(market.noSupply(), 10);
    }

    function test_factoryRejectsCollateralResolverOverlap() public {
        PredictionFactoryP0 overlapFactory = new PredictionFactoryP0(address(collateral));
        vm.expectRevert(PredictionFactoryP0.CollateralResolverOverlap.selector);
        overlapFactory.createMarket(address(collateral), bytes32("overlap"), "Yes", "YES", "No", "NO");
    }

    function test_callbackLifecycleMutationDuringSplitRejectsSafely() public {
        CallbackCollateralP0 callbackCollateral = new CallbackCollateralP0();
        PredictionFactoryP0 callbackFactory = new PredictionFactoryP0(address(callbackCollateral));
        LifecycleAttackResolver attackResolver = new LifecycleAttackResolver();
        PredictionMarketP0 callbackMarket =
            callbackFactory.createMarket(address(attackResolver), bytes32("callback"), "Yes", "YES", "No", "NO");
        callbackFactory.activate(callbackMarket);

        callbackCollateral.mint(alice, 1);
        callbackCollateral.arm(attackResolver, callbackMarket);
        vm.startPrank(alice);
        callbackCollateral.approve(address(callbackMarket), 1);
        vm.expectRevert();
        callbackMarket.split(1);
        vm.stopPrank();

        assertEq(uint256(callbackMarket.state()), uint256(PredictionMarketP0.State.OPEN));
        assertEq(uint256(callbackMarket.result()), uint256(PredictionMarketP0.Result.NONE));
        assertEq(callbackMarket.collateralLocked(), 0);
        assertEq(callbackMarket.yesSupply(), 0);
        assertEq(callbackMarket.noSupply(), 0);
        assertEq(callbackCollateral.balanceOf(address(callbackMarket)), 0);
        assertEq(callbackMarket.yesToken().balanceOf(alice), 0);
        assertEq(callbackMarket.noToken().balanceOf(alice), 0);
    }

    function test_userCannotMintOutcome() public {
        OutcomeTokenP0 yes = market.yesToken();
        vm.expectRevert(OutcomeTokenP0.NotMarket.selector);
        vm.prank(alice);
        yes.mint(alice, 1);
    }
}

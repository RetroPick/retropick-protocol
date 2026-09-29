// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {PredictionFactoryP0} from "../../src/hackathon/PredictionFactoryP0.sol";
import {PredictionMarketP0} from "../../src/hackathon/PredictionMarketP0.sol";

/// @notice Executes the Python HackathonPredictionModel scenarios against the Solidity kernel.
contract PredictionP0DifferentialTest is Test {
    MockCollateral internal collateral;
    PredictionFactoryP0 internal factory;
    PredictionMarketP0 internal market;

    address internal constant RESOLVER = address(0xBEEF);
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);
    uint256 internal constant STATE = 0;
    uint256 internal constant RESULT = 1;
    uint256 internal constant LOCKED = 2;
    uint256 internal constant PHYSICAL = 3;
    uint256 internal constant LIABILITY = 4;
    uint256 internal constant YES_SUPPLY = 5;
    uint256 internal constant NO_SUPPLY = 6;
    uint256 internal constant YES_BALANCE = 7;
    uint256 internal constant NO_BALANCE = 8;

    function setUp() public {
        collateral = new MockCollateral(6);
        factory = new PredictionFactoryP0(address(collateral));
        market = factory.createMarket(RESOLVER, bytes32("p0-differential"), "Yes", "YES", "No", "NO");
        factory.activate(market);
        collateral.mint(ALICE, 12);
        vm.prank(ALICE);
        collateral.approve(address(market), type(uint256).max);
    }

    function test_yesWorldMatchesPythonSnapshots() public {
        _runScenario(0, PredictionMarketP0.Result.YES_WIN);
    }

    function test_noWorldMatchesPythonSnapshots() public {
        _runScenario(1, PredictionMarketP0.Result.NO_WIN);
    }

    function test_activationMatchesPythonSnapshots() public {
        string memory json = vm.readFile("../hackathon-p0/fixtures/prediction_p0_differential.json");
        market = factory.createMarket(RESOLVER, bytes32("activation"), "Yes", "YES", "No", "NO");
        _assertSnapshot(json, 0, 0);
        factory.activate(market);
        _assertSnapshot(json, 0, 1);
    }

    function test_rejectedWrongSideRedemptionPreservesP0State() public {
        vm.prank(ALICE);
        market.split(3);
        vm.startPrank(RESOLVER);
        market.closeMint();
        market.resolve(PredictionMarketP0.Result.YES_WIN);
        vm.stopPrank();
        market.openRedemption();

        uint256 collateralBefore = collateral.balanceOf(address(market));
        uint256 lockedBefore = market.collateralLocked();
        uint256 yesBefore = market.yesSupply();
        uint256 noBefore = market.noSupply();
        uint256 yesBalanceBefore = market.yesToken().balanceOf(ALICE);
        uint256 noBalanceBefore = market.noToken().balanceOf(ALICE);
        vm.expectRevert(PredictionMarketP0.NotWinner.selector);
        vm.prank(ALICE);
        market.redeemNo(1);

        assertEq(collateral.balanceOf(address(market)), collateralBefore);
        assertEq(market.collateralLocked(), lockedBefore);
        assertEq(market.yesSupply(), yesBefore);
        assertEq(market.noSupply(), noBefore);
        assertEq(market.yesToken().balanceOf(ALICE), yesBalanceBefore);
        assertEq(market.noToken().balanceOf(ALICE), noBalanceBefore);
    }

    function _runScenario(uint256 caseIndex, PredictionMarketP0.Result winningResult) private {
        string memory json = vm.readFile("../hackathon-p0/fixtures/prediction_p0_differential.json");
        _runLifecycle(json, caseIndex, winningResult);
        _runRedemptions(json, caseIndex, winningResult == PredictionMarketP0.Result.YES_WIN);
    }

    function _runLifecycle(string memory json, uint256 caseIndex, PredictionMarketP0.Result winningResult) private {
        _assertSnapshot(json, caseIndex, 1);

        vm.prank(ALICE);
        market.split(_scenario(json, "split_amount"));
        _assertSnapshot(json, caseIndex, 2);

        uint256 transferAmount = _scenario(json, "transfer_amount");
        vm.startPrank(ALICE);
        market.yesToken().transfer(BOB, transferAmount);
        market.noToken().transfer(BOB, transferAmount);
        vm.stopPrank();
        _assertSnapshot(json, caseIndex, 3);

        vm.prank(ALICE);
        market.merge(_scenario(json, "merge_amount"));
        _assertSnapshot(json, caseIndex, 4);

        vm.prank(RESOLVER);
        market.closeMint();
        _assertSnapshot(json, caseIndex, 5);

        vm.prank(BOB);
        market.merge(1);
        _assertSnapshot(json, caseIndex, 6);

        vm.prank(RESOLVER);
        market.resolve(winningResult);
        _assertSnapshot(json, caseIndex, 7);

        market.openRedemption();
        _assertSnapshot(json, caseIndex, 8);
    }

    function _runRedemptions(string memory json, uint256 caseIndex, bool yesWins) private {
        uint256 firstAmount = _scenario(json, "first_redeem_amount");
        uint256 aliceCollateralBefore = collateral.balanceOf(ALICE);
        vm.prank(ALICE);
        uint256 firstPayout = yesWins ? market.redeemYes(firstAmount) : market.redeemNo(firstAmount);
        assertEq(firstPayout, _payout(json, caseIndex, 0));
        assertEq(collateral.balanceOf(ALICE) - aliceCollateralBefore, firstPayout);
        _assertSnapshot(json, caseIndex, 9);

        uint256 bobRedeemAmount = _scenario(json, "bob_redeem_amount");
        uint256 bobCollateralBefore = collateral.balanceOf(BOB);
        vm.prank(BOB);
        uint256 bobPayout = yesWins ? market.redeemYes(bobRedeemAmount) : market.redeemNo(bobRedeemAmount);
        assertEq(bobPayout, _payout(json, caseIndex, 1));
        assertEq(collateral.balanceOf(BOB) - bobCollateralBefore, bobPayout);
        _assertSnapshot(json, caseIndex, 10);

        vm.prank(ALICE);
        market.burnWorthless(!yesWins, _scenario(json, "worthless_burn_amount"));
        vm.prank(BOB);
        market.burnWorthless(!yesWins, _scenario(json, "bob_worthless_burn_amount"));
        _assertSnapshot(json, caseIndex, 11);

        uint256 finalAmount = _scenario(json, "final_redeem_amount");
        aliceCollateralBefore = collateral.balanceOf(ALICE);
        vm.prank(ALICE);
        uint256 finalPayout = yesWins ? market.redeemYes(finalAmount) : market.redeemNo(finalAmount);
        assertEq(finalPayout, _payout(json, caseIndex, 2));
        assertEq(collateral.balanceOf(ALICE) - aliceCollateralBefore, finalPayout);

        _assertSnapshot(json, caseIndex, 12);
        market.archive();
        _assertSnapshot(json, caseIndex, 13);
    }

    function _assertSnapshot(string memory json, uint256 caseIndex, uint256 checkpoint) private view {
        assertEq(uint256(market.state()), _snapshot(json, caseIndex, checkpoint, STATE));
        assertEq(uint256(market.result()), _snapshot(json, caseIndex, checkpoint, RESULT));
        assertEq(market.collateralLocked(), _snapshot(json, caseIndex, checkpoint, LOCKED));
        assertEq(collateral.balanceOf(address(market)), _snapshot(json, caseIndex, checkpoint, PHYSICAL));
        assertEq(market.liability(), _snapshot(json, caseIndex, checkpoint, LIABILITY));
        assertEq(market.yesSupply(), _snapshot(json, caseIndex, checkpoint, YES_SUPPLY));
        assertEq(market.noSupply(), _snapshot(json, caseIndex, checkpoint, NO_SUPPLY));
        assertEq(market.yesToken().balanceOf(ALICE), _snapshot(json, caseIndex, checkpoint, YES_BALANCE));
        assertEq(market.noToken().balanceOf(ALICE), _snapshot(json, caseIndex, checkpoint, NO_BALANCE));
        assertEq(market.yesToken().balanceOf(BOB), _snapshot(json, caseIndex, checkpoint, 9));
        assertEq(market.noToken().balanceOf(BOB), _snapshot(json, caseIndex, checkpoint, 10));
    }

    function _scenario(string memory json, string memory key) private pure returns (uint256) {
        return vm.parseJsonUint(json, string.concat(".scenario.", key));
    }

    function _snapshot(string memory json, uint256 caseIndex, uint256 checkpoint, uint256 field)
        private
        pure
        returns (uint256)
    {
        string memory path = string.concat(
            ".cases[", vm.toString(caseIndex), "].snapshots[", vm.toString(checkpoint), "][", vm.toString(field), "]"
        );
        return vm.parseJsonUint(json, path);
    }

    function _payout(string memory json, uint256 caseIndex, uint256 payoutIndex) private pure returns (uint256) {
        string memory path = string.concat(".cases[", vm.toString(caseIndex), "].payouts[", vm.toString(payoutIndex), "]");
        return vm.parseJsonUint(json, path);
    }
}

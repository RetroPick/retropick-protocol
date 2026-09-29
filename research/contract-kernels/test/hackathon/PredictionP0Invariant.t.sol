// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockCollateral} from "../../src/prediction/MockCollateral.sol";
import {OutcomeTokenP0} from "../../src/hackathon/OutcomeTokenP0.sol";
import {PredictionFactoryP0} from "../../src/hackathon/PredictionFactoryP0.sol";
import {PredictionMarketP0} from "../../src/hackathon/PredictionMarketP0.sol";

/// @notice Stateful lifecycle campaign for the bounded binary Hackathon P0 kernel.
/// @dev Invalid action domains are skipped; unit/differential tests cover selected rejection paths.
/// forge-config: default.invariant.runs = 256
/// forge-config: default.invariant.depth = 100
/// forge-config: default.invariant.fail_on_revert = false
contract PredictionP0InvariantTest is Test {
    uint256 internal constant ACTION_CAP = 1_000_000;
    address internal constant RESOLVER = address(0xBEEF);
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);
    address internal constant CAROL = address(0xCA201);

    MockCollateral internal collateral;
    PredictionFactoryP0 internal factory;
    PredictionMarketP0 internal market;

    function setUp() public {
        collateral = new MockCollateral(6);
        factory = new PredictionFactoryP0(address(collateral));
        market = factory.createMarket(RESOLVER, bytes32("p0-invariant"), "Yes", "YES", "No", "NO");
        factory.activate(market);

        address[3] memory actors = [ALICE, BOB, CAROL];
        for (uint256 i; i < actors.length; ++i) {
            vm.prank(actors[i]);
            collateral.approve(address(market), type(uint256).max);
        }

        bytes4[] memory selectors = new bytes4[](13);
        selectors[0] = this.split.selector;
        selectors[1] = this.merge.selector;
        selectors[2] = this.transferYes.selector;
        selectors[3] = this.transferNo.selector;
        selectors[4] = this.closeMint.selector;
        selectors[5] = this.resolveYes.selector;
        selectors[6] = this.resolveNo.selector;
        selectors[7] = this.openRedemption.selector;
        selectors[8] = this.redeemWinner.selector;
        selectors[9] = this.burnLoser.selector;
        selectors[10] = this.attemptPostLockSplit.selector;
        selectors[11] = this.attemptSecondResolution.selector;
        selectors[12] = this.archive.selector;
        targetSelector(FuzzSelector({addr: address(this), selectors: selectors}));
        targetContract(address(this));
        excludeContract(address(collateral));
        excludeContract(address(factory));
        excludeContract(address(market));
        excludeContract(address(market.yesToken()));
        excludeContract(address(market.noToken()));
    }

    function split(uint96 rawAmount, uint8 actorSeed) external {
        if (market.state() != PredictionMarketP0.State.OPEN) return;
        uint256 current = market.yesSupply();
        if (current >= market.MAX_OUTCOME_SUPPLY()) return;
        uint256 amount = bound(uint256(rawAmount), 1, ACTION_CAP);
        uint256 remaining = market.MAX_OUTCOME_SUPPLY() - current;
        if (amount > remaining) amount = remaining;
        address actor = _actor(actorSeed);
        collateral.mint(actor, amount);
        vm.prank(actor);
        market.split(amount);
    }

    function merge(uint96 rawAmount, uint8 actorSeed) external {
        PredictionMarketP0.State state = market.state();
        if (state != PredictionMarketP0.State.OPEN && state != PredictionMarketP0.State.LOCKED) return;
        address actor = _actor(actorSeed);
        uint256 held = _min(market.yesToken().balanceOf(actor), market.noToken().balanceOf(actor));
        if (held == 0) return;
        uint256 amount = bound(uint256(rawAmount), 1, held);
        vm.prank(actor);
        market.merge(amount);
    }

    function transferYes(uint96 rawAmount, uint8 fromSeed, uint8 toSeed) external {
        address from = _actor(fromSeed);
        address to = _actor(toSeed);
        if (from == to) return;
        uint256 held = market.yesToken().balanceOf(from);
        if (held == 0) return;
        uint256 amount = bound(uint256(rawAmount), 1, held);
        OutcomeTokenP0 token = market.yesToken();
        vm.prank(from);
        token.transfer(to, amount);
    }

    function transferNo(uint96 rawAmount, uint8 fromSeed, uint8 toSeed) external {
        address from = _actor(fromSeed);
        address to = _actor(toSeed);
        if (from == to) return;
        uint256 held = market.noToken().balanceOf(from);
        if (held == 0) return;
        uint256 amount = bound(uint256(rawAmount), 1, held);
        OutcomeTokenP0 token = market.noToken();
        vm.prank(from);
        token.transfer(to, amount);
    }

    function closeMint() external {
        if (market.state() != PredictionMarketP0.State.OPEN) return;
        vm.prank(RESOLVER);
        market.closeMint();
    }

    function resolveYes() external {
        _resolve(PredictionMarketP0.Result.YES_WIN);
    }

    function resolveNo() external {
        _resolve(PredictionMarketP0.Result.NO_WIN);
    }

    function openRedemption() external {
        if (market.state() != PredictionMarketP0.State.RESOLVED) return;
        market.openRedemption();
    }

    function redeemWinner(uint96 rawAmount, uint8 actorSeed) external {
        if (market.state() != PredictionMarketP0.State.REDEEMABLE) return;
        bool yesWins = market.result() == PredictionMarketP0.Result.YES_WIN;
        address actor = _actor(actorSeed);
        uint256 held = yesWins ? market.yesToken().balanceOf(actor) : market.noToken().balanceOf(actor);
        if (held == 0) return;
        uint256 amount = bound(uint256(rawAmount), 1, held);
        uint256 balanceBefore = collateral.balanceOf(actor);
        vm.prank(actor);
        uint256 paid = yesWins ? market.redeemYes(amount) : market.redeemNo(amount);
        assertEq(paid, amount, "winner payout must be one-for-one");
        assertEq(collateral.balanceOf(actor) - balanceBefore, amount, "physical payout must equal burn");
    }

    function burnLoser(uint96 rawAmount, uint8 actorSeed) external {
        if (market.state() != PredictionMarketP0.State.REDEEMABLE) return;
        bool loserIsYes = market.result() == PredictionMarketP0.Result.NO_WIN;
        address actor = _actor(actorSeed);
        uint256 held = loserIsYes ? market.yesToken().balanceOf(actor) : market.noToken().balanceOf(actor);
        if (held == 0) return;
        uint256 amount = bound(uint256(rawAmount), 1, held);
        vm.prank(actor);
        market.burnWorthless(loserIsYes, amount);
    }

    /// @dev Keeps the post-close issuance rejection in the generated action stream.
    function attemptPostLockSplit(uint96 rawAmount, uint8 actorSeed) external {
        PredictionMarketP0.State state = market.state();
        if (state != PredictionMarketP0.State.LOCKED && state != PredictionMarketP0.State.RESOLVED
            && state != PredictionMarketP0.State.REDEEMABLE && state != PredictionMarketP0.State.ARCHIVED) return;
        uint256 amount = bound(uint256(rawAmount), 1, ACTION_CAP);
        address actor = _actor(actorSeed);
        collateral.mint(actor, amount);
        uint256 yesBefore = market.yesSupply();
        uint256 noBefore = market.noSupply();
        uint256 collateralBefore = collateral.balanceOf(address(market));
        vm.expectRevert(PredictionMarketP0.BadState.selector);
        vm.prank(actor);
        market.split(amount);
        assertEq(market.yesSupply(), yesBefore);
        assertEq(market.noSupply(), noBefore);
        assertEq(collateral.balanceOf(address(market)), collateralBefore);
    }

    /// @dev Checks resolution is immutable after its first accepted commitment.
    function attemptSecondResolution() external {
        if (market.state() != PredictionMarketP0.State.RESOLVED
            && market.state() != PredictionMarketP0.State.REDEEMABLE
            && market.state() != PredictionMarketP0.State.ARCHIVED) return;
        PredictionMarketP0.Result oldResult = market.result();
        vm.expectRevert(PredictionMarketP0.BadState.selector);
        vm.prank(RESOLVER);
        market.resolve(oldResult == PredictionMarketP0.Result.YES_WIN
            ? PredictionMarketP0.Result.NO_WIN
            : PredictionMarketP0.Result.YES_WIN);
        assertEq(uint256(market.result()), uint256(oldResult));
    }

    function archive() external {
        if (market.state() != PredictionMarketP0.State.REDEEMABLE || market.liability() != 0) return;
        market.archive();
    }

    function invariant_physicalCollateralCoversLiability() public view {
        assertGe(collateral.balanceOf(address(market)), market.liability());
    }

    function invariant_accountedSupplyMatchesOutcomeTokens() public view {
        assertEq(market.yesSupply(), market.yesToken().totalSupply());
        assertEq(market.noSupply(), market.noToken().totalSupply());
    }

    function invariant_completeSetsRemainConservedBeforeRedemption() public view {
        PredictionMarketP0.State state = market.state();
        if (state == PredictionMarketP0.State.OPEN || state == PredictionMarketP0.State.LOCKED
            || state == PredictionMarketP0.State.RESOLVED) {
            assertEq(market.yesSupply(), market.noSupply());
            assertEq(market.yesSupply(), market.collateralLocked());
        }
    }

    function invariant_accountingLiabilityAndActualBalanceAgree() public view {
        assertEq(market.collateralLocked(), market.liability());
        assertGe(collateral.balanceOf(address(market)), market.collateralLocked());
    }

    function invariant_resultAndLifecycleAreConsistent() public view {
        PredictionMarketP0.State state = market.state();
        PredictionMarketP0.Result result = market.result();
        if (state == PredictionMarketP0.State.DRAFT || state == PredictionMarketP0.State.OPEN
            || state == PredictionMarketP0.State.LOCKED) {
            assertEq(uint256(result), uint256(PredictionMarketP0.Result.NONE));
        } else {
            assertTrue(result == PredictionMarketP0.Result.YES_WIN || result == PredictionMarketP0.Result.NO_WIN);
        }
        if (state == PredictionMarketP0.State.ARCHIVED) assertEq(market.liability(), 0);
    }

    function _resolve(PredictionMarketP0.Result result) internal {
        if (market.state() != PredictionMarketP0.State.LOCKED) return;
        vm.prank(RESOLVER);
        market.resolve(result);
    }

    function _actor(uint8 seed) internal pure returns (address) {
        uint8 choice = seed % 3;
        if (choice == 0) return ALICE;
        if (choice == 1) return BOB;
        return CAROL;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

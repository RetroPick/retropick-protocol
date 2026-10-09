// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    RetroPickV4BehaviorFixtureV2,
    V4BehaviorPositionManager
} from "../integration/RetroPickV4GraduationBehavior.t.sol";
import {RetroPickLaunchFactoryV2} from "../../../src/v2/RetroPickLaunchFactoryV2.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2/RetroPickBondingCurveV2.sol";
import {GraduationCoordinatorV2} from "../../../src/v2/GraduationCoordinatorV2.sol";
import {
    GraduationState,
    GraduationLedger,
    GraduationPacket
} from "../../../src/v2/interfaces/IGraduationExecutorV2.sol";

contract CoordinatorHandlerV2 is Test {
    RetroPickLaunchFactoryV2 public immutable factory;
    GraduationCoordinatorV2 public immutable coordinator;
    V4BehaviorPositionManager public immutable position;
    address public immutable actor;
    address public immutable operator;
    address[] public tokens;
    mapping(address => bytes32) public initialPacketHash;
    mapping(address => bytes32) public destination;
    bool public unexpectedFinishFailure;
    bool public unexpectedCompletionFailure;
    bool public replayOrEscapeSucceeded;

    constructor(
        RetroPickLaunchFactoryV2 f,
        GraduationCoordinatorV2 c,
        V4BehaviorPositionManager p,
        address actor_,
        address operator_
    ) {
        factory = f;
        coordinator = c;
        position = p;
        actor = actor_;
        operator = operator_;
    }

    function count() external view returns (uint256) {
        return tokens.length;
    }

    function launch() public {
        if (tokens.length >= 4) return;
        RetroPickLaunchFactoryV2.TokenParams memory p;
        p.name = "Invariant";
        p.symbol = "INV";
        p.creatorFeeRecipient = actor;
        vm.prank(actor);
        (address token,) = factory.launchToken(p, 0, address(0));
        tokens.push(token);
        initialPacketHash[token] = keccak256(abi.encode(coordinator.packet(token)));
    }

    function buy(uint256 index, uint256 amount) external {
        if (tokens.length == 0) return;
        RetroPickBondingCurveV2 curve = _curve(tokens[index % tokens.length]);
        amount = bound(amount, 1, 250 ether);
        vm.prank(actor);
        try curve.buy{value: amount}(amount, 0, actor) {} catch {}
    }

    function sell(uint256 index, uint256 fraction) external {
        if (tokens.length == 0) return;
        address token = tokens[index % tokens.length];
        RetroPickBondingCurveV2 curve = _curve(token);
        uint256 amount = IERC20(token).balanceOf(actor) / bound(fraction, 1, 100);
        if (amount == 0) return;
        vm.startPrank(actor);
        IERC20(token).approve(address(curve), amount);
        try curve.sell(amount, 0, actor) {} catch {}
        vm.stopPrank();
    }

    function sweep(uint256 index) external {
        if (tokens.length == 0) return;
        vm.prank(operator);
        try _curve(tokens[index % tokens.length]).sweepFees(0) {} catch {}
    }

    function finish(uint256 index) external {
        if (tokens.length == 0) return;
        address token = tokens[index % tokens.length];
        RetroPickBondingCurveV2 curve = _curve(token);
        if (coordinator.ledger(token).phase != GraduationState.NONE) return;
        if (curve.readyToGraduate()) {
            try factory.graduate(token) {}
            catch {
                unexpectedFinishFailure = true;
            }
        } else {
            (, uint256 gross) = curve.completionQuote();
            vm.prank(actor);
            try curve.buy{value: gross}(gross, 0, actor) {}
            catch {
                unexpectedFinishFailure = true;
            }
        }
    }

    function complete(uint256 index, bool transientFailure) external {
        if (tokens.length == 0) return;
        address token = tokens[index % tokens.length];
        GraduationState phase = coordinator.ledger(token).phase;
        position.setFailMint(transientFailure);
        try coordinator.complete(token) {
            if (phase != GraduationState.GRADUATING) replayOrEscapeSucceeded = true;
            bytes32 actual = coordinator.ledger(token).destinationIdentity;
            if (destination[token] != bytes32(0) && destination[token] != actual) replayOrEscapeSucceeded = true;
            destination[token] = actual;
        } catch {
            if (phase == GraduationState.GRADUATING && !transientFailure) unexpectedCompletionFailure = true;
        }
        position.setFailMint(false);
    }

    function attemptProtectedEscape(uint256 index) external {
        if (tokens.length == 0) return;
        GraduationPacket memory p = coordinator.packet(tokens[index % tokens.length]);
        (bool ok,) = p.protectedLPReceiver.call(abi.encodeWithSignature("withdraw(address)", actor));
        if (ok) replayOrEscapeSucceeded = true;
        (ok,) = p.protectedLPReceiver
            .call(
                abi.encodeWithSignature(
                    "execute(address,bytes)", p.token, abi.encodeWithSignature("transfer(address,uint256)", actor, 1)
                )
            );
        if (ok) replayOrEscapeSucceeded = true;
    }

    function _curve(address token) private view returns (RetroPickBondingCurveV2) {
        return RetroPickBondingCurveV2(factory.getLaunchedToken(token).curve);
    }
}

/// @notice Stateful production ledger conservation, liveness and custody under bonding/secure/retry interleavings.
contract GraduationCoordinatorV2InvariantTest is RetroPickV4BehaviorFixtureV2 {
    CoordinatorHandlerV2 internal handler;

    function setUp() public override {
        super.setUp();
        vm.deal(creator, 1_000_000 ether);
        handler = new CoordinatorHandlerV2(factory, coordinator, position, creator, address(this));
        handler.launch();
        targetContract(address(handler));
    }

    function invariantOneLedgerPhysicalBackingImmutableVenueAndDestination() public view {
        uint256 totalAvailable;
        for (uint256 i; i < handler.count(); ++i) {
            address token = handler.tokens(i);
            GraduationLedger memory l = coordinator.ledger(token);
            GraduationPacket memory p = coordinator.packet(token);
            (uint256 availableQuote, uint256 availableTokens) = coordinator.available(token);
            assertEq(l.consumedQuote + availableQuote, l.securedQuote);
            assertEq(l.consumedLaunchTokens + availableTokens, l.securedLaunchTokens);
            assertGe(IERC20(token).balanceOf(address(coordinator)), availableTokens);
            totalAvailable += availableQuote;
            assertEq(keccak256(abi.encode(p)), handler.initialPacketHash(token));
            assertEq(IERC20(token).allowance(address(coordinator), p.executor), 0);
            assertEq(IERC20(token).allowance(p.protectedExcessReceiver, creator), 0);
            if (l.phase == GraduationState.GRADUATED) {
                assertTrue(l.destinationIdentity != bytes32(0));
                assertTrue(l.receiptHash != bytes32(0));
                assertEq(availableQuote, 0);
                assertEq(availableTokens, 0);
            } else {
                assertEq(l.destinationIdentity, bytes32(0));
            }
            RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(p.curve);
            if (l.phase == GraduationState.NONE) assertLe(curve.completionTerminalQuote(), p.graduationQuoteCeiling);
            else assertTrue(curve.graduated());
        }
        assertGe(address(coordinator).balance, totalAvailable);
        assertEq(coordinator.quoteLiability(address(0)), totalAvailable);
        assertEq(address(factory).balance, 0);
    }

    function invariantNoCompletionDeadlockReplayOrProtectedExit() public view {
        assertFalse(handler.unexpectedFinishFailure());
        assertFalse(handler.unexpectedCompletionFailure());
        assertFalse(handler.replayOrEscapeSucceeded());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2/RetroPickBondingCurveV2.sol";
import {RetroPickLauncherTokenV2} from "../../../src/v2/RetroPickLauncherTokenV2.sol";
import {RetroPickBuybackVaultV2} from "../../../src/v2/RetroPickBuybackVaultV2.sol";
import {IRetroPickFeePolicyV2, IRetroPickFeeEscrowV2} from "../../../src/v2/interfaces/IRetroPickLaunchpadV2.sol";
import {CurveStateFeePolicyV2, CurveStateFeeEscrowV2} from "../unit/RetroPickCurrentCurveStateV2Qualification.t.sol";

contract CurrentCurveV2Handler is Test {
    RetroPickBondingCurveV2 public immutable curve;
    RetroPickLauncherTokenV2 public immutable token;
    address public immutable operator;
    address[3] internal actors;
    uint256 public successfulBuys;
    uint256 public successfulSells;
    uint256 public successfulSweeps;
    uint256 public unauthorizedMutations;

    constructor(
        RetroPickBondingCurveV2 curve_,
        RetroPickLauncherTokenV2 token_,
        address operator_,
        address[3] memory actors_
    ) {
        curve = curve_;
        token = token_;
        operator = operator_;
        actors = actors_;
    }

    function actor(uint256 index) external view returns (address) {
        return actors[index];
    }

    function buy(uint256 actorSeed, uint256 amountSeed) external {
        address buyer = actors[actorSeed % actors.length];
        uint256 quoteIn = bound(amountSeed, 1e12, 1 ether);
        vm.deal(buyer, buyer.balance + quoteIn);
        vm.prank(buyer);
        try curve.buy{value: quoteIn}(quoteIn, 0, buyer) {
            successfulBuys++;
        } catch {}
    }

    function sell(uint256 actorSeed, uint256 amountSeed) external {
        address seller = actors[actorSeed % actors.length];
        uint256 balance = token.balanceOf(seller);
        if (balance == 0) return;
        uint256 tokensIn = bound(amountSeed, 1, balance);
        vm.startPrank(seller);
        token.approve(address(curve), tokensIn);
        try curve.sell(tokensIn, 0, seller) {
            successfulSells++;
        } catch {}
        vm.stopPrank();
    }

    function sweep() external {
        vm.prank(operator);
        try curve.sweepFees(0) {
            successfulSweeps++;
        } catch {}
    }

    function attemptUnauthorizedMutation(uint256 actorSeed) external {
        vm.prank(actors[actorSeed % actors.length]);
        try curve.setBuybackEnabled(true) {
            unauthorizedMutations++;
        } catch {}
    }
}

/// @notice CURRENT native-quote Curve state, not Factory or Kuru qualification.
contract RetroPickCurrentCurveV2InvariantTest is StdInvariant, Test {
    uint256 internal constant SUPPLY = 1_000_000 ether;
    uint256 internal constant PHANTOM = 100 ether;
    RetroPickBondingCurveV2 internal curve;
    RetroPickLauncherTokenV2 internal token;
    CurrentCurveV2Handler internal handler;

    function setUp() public {
        address creator = makeAddr("creator");
        address protocol = makeAddr("protocol");
        address operator = makeAddr("operator");
        address[3] memory actors = [makeAddr("buyer-a"), makeAddr("buyer-b"), makeAddr("buyer-c")];
        CurveStateFeeEscrowV2 escrow = new CurveStateFeeEscrowV2();
        CurveStateFeePolicyV2 policy =
            new CurveStateFeePolicyV2(protocol, operator, IRetroPickFeeEscrowV2(address(escrow)));
        RetroPickBuybackVaultV2 vault = new RetroPickBuybackVaultV2(
            address(this), IRetroPickFeePolicyV2(address(policy)), IRetroPickFeeEscrowV2(address(escrow))
        );
        curve = new RetroPickBondingCurveV2(
            address(0),
            creator,
            address(this),
            IRetroPickFeePolicyV2(address(policy)),
            policy.currentFeePolicy(),
            IRetroPickFeeEscrowV2(address(escrow)),
            vault,
            PHANTOM,
            100,
            50,
            false,
            100 ether
        );
        RetroPickLauncherTokenV2.Socials memory socials;
        token = new RetroPickLauncherTokenV2(
            "Launch", "LCH", "", "", socials, creator, address(curve), address(this), SUPPLY
        );
        curve.initialize(address(token));
        handler = new CurrentCurveV2Handler(curve, token, operator, actors);
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = handler.buy.selector;
        selectors[1] = handler.sell.selector;
        selectors[2] = handler.sweep.selector;
        selectors[3] = handler.attemptUnauthorizedMutation.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function invariantPhysicalBalancesAndFeeBuckets() public view {
        assertEq(address(curve).balance, curve.trackedQuote(), "native balance = tracked quote");
        assertEq(token.balanceOf(address(curve)), curve.trackedTokens(), "token balance = tracked tokens");
        assertLe(curve.quoteFeeBalance() + curve.creatorTaxBalance(), curve.trackedQuote(), "pending <= tracked");
        uint256 realQuote = curve.trackedQuote() - curve.quoteFeeBalance() - curve.creatorTaxBalance();
        assertEq(curve.realQuoteReserve(), realQuote, "real quote equation");
        (uint256 quoteReserve, uint256 tokenReserve) = curve.getReserves();
        assertEq(quoteReserve, PHANTOM + realQuote, "phantom pricing equation");
        assertEq(tokenReserve, curve.trackedTokens(), "token reserve equation");
        assertLe(curve.buybackQuoteBalance(), curve.quoteFeeBalance(), "earmark subset");
    }

    function invariantFixedSupplyAndNoUnauthorizedMutation() public view {
        uint256 held = token.balanceOf(address(curve));
        for (uint256 i; i < 3; ++i) {
            held += token.balanceOf(handler.actor(i));
        }
        assertEq(held, SUPPLY, "all issued tokens held by curve or actors");
        assertEq(token.totalSupply(), SUPPLY, "fixed supply");
        assertEq(handler.unauthorizedMutations(), 0, "unauthorized admin action");
        assertFalse(curve.buybackEnabled(), "unauthorized flag change");
    }

    function testHandlerExercisesAcceptedAndRejectedBranches() public {
        handler.buy(0, 1 ether);
        handler.sell(0, token.balanceOf(handler.actor(0)) / 2);
        handler.sweep();
        handler.attemptUnauthorizedMutation(1);
        assertEq(handler.successfulBuys(), 1);
        assertEq(handler.successfulSells(), 1);
        assertEq(handler.successfulSweeps(), 1);
        assertEq(handler.unauthorizedMutations(), 0);
    }
}

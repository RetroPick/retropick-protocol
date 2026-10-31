// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CommunityFlowFixtureV2} from "./CommunityCurveFlow.t.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2-research-experiment/RetroPickBondingCurveV2.sol";
import {CommunityFeeRouterV2} from "../../../src/v2-research-experiment/CommunityFeeRouterV2.sol";
import {CommunityPolicyRegistryV2 as Registry} from "../../../src/v2-research-experiment/CommunityPolicyRegistryV2.sol";
import {CommunityControllerV2} from "../../../src/v2-research-experiment/CommunityControllerV2.sol";

contract CommunityAccountingHandler is Test {
    RetroPickBondingCurveV2 public c;
    CommunityFeeRouterV2 public r;
    Registry public reg;
    CommunityControllerV2 public ctrl;
    address public creator;
    address public treasury;
    uint256 public trades;
    uint256 public settlements;
    uint256 public claims;
    uint256 public proposals;
    uint256 public cancellations;
    uint256 public activations;
    uint256 public rotations;
    uint256 public donations;
    uint256 public unauthorizedAttempts;
    uint256 public invalidAttempts;
    uint256 public rejected;
    uint256 public unexpectedAuthoritySuccess;

    constructor(RetroPickBondingCurveV2 c_, CommunityFeeRouterV2 r_, address creator_, address treasury_) {
        c = c_;
        r = r_;
        reg = r_.registry();
        ctrl = CommunityControllerV2(r_.authority());
        creator = creator_;
        treasury = treasury_;
    }

    function trade(uint256 amount, bool sell) public {
        amount = bound(amount, 1e8, 1e16);
        address token = c.token();
        if (sell && IERC20(token).balanceOf(creator) > 0) {
            uint256 balance = IERC20(token).balanceOf(creator);
            vm.startPrank(creator);
            IERC20(token).approve(address(c), balance / 2);
            try c.sell(balance / 2, 0, creator) {
                ++trades;
            } catch {
                ++rejected;
            }
            vm.stopPrank();
        } else {
            vm.deal(creator, creator.balance + amount);
            vm.prank(creator);
            try c.buy{value: amount}(amount, 0, creator) {
                ++trades;
            } catch {
                ++rejected;
            }
        }
    }

    function settle() public {
        try r.settle() {
            ++settlements;
        } catch {
            ++rejected;
        }
    }

    function claim(uint256 seed, uint256 amount) public {
        address actor = seed % 2 == 0 ? creator : treasury;
        uint256 debt = r.credit(actor);
        if (debt == 0) return;
        amount = bound(amount, 1, debt);
        vm.prank(actor);
        try r.claim(amount) {
            ++claims;
        } catch {
            ++rejected;
        }
    }

    function propose(uint16 share) public {
        share = uint16(bound(share, 1, 6000));
        Registry.Allocation[] memory a = new Registry.Allocation[](2);
        a[0] = Registry.Allocation(creator, share, 0);
        a[1] = Registry.Allocation(treasury, uint16(10000 - share), 2);
        address admin = ctrl.controller();
        vm.prank(admin);
        try reg.proposePolicy(a) {
            ++proposals;
        } catch {
            ++rejected;
        }
    }

    function cancel() public {
        (, uint256 n,,,,) = reg.pendingPolicy();
        address admin = ctrl.controller();
        vm.prank(admin);
        try reg.cancelPolicy(n) {
            ++cancellations;
        } catch {
            ++rejected;
        }
    }

    function activate() public {
        (, uint256 n,, uint256 eta,,) = reg.pendingPolicy();
        if (eta > block.timestamp) vm.warp(eta);
        try reg.activatePolicy(n) {
            ++activations;
        } catch {
            ++rejected;
        }
    }

    function rotate() public {
        address admin = ctrl.controller();
        address next = admin == creator ? address(0xCAFE) : creator;
        vm.prank(admin);
        try ctrl.schedule(next, false) {}
        catch {
            ++rejected;
            return;
        }
        uint256 n = ctrl.nonce();
        vm.warp(block.timestamp + 3 days);
        vm.prank(next);
        try ctrl.accept(n) {
            ++rotations;
        } catch {
            ++rejected;
        }
    }

    function donate(uint256 amount) public {
        amount = bound(amount, 1, 1e15);
        vm.deal(address(this), amount);
        (bool ok,) = address(r).call{value: amount}("");
        require(ok);
        ++donations;
    }

    function unauthorized() public {
        ++unauthorizedAttempts;
        try r.fund(address(1), address(0), 1, 1, 1) {
            ++unexpectedAuthoritySuccess;
        } catch {}
    }

    function invalidSettlement() public {
        ++invalidAttempts;
        address token = c.token();
        uint256 e = reg.epoch();
        uint256 seq = r.sequence();
        vm.prank(address(c));
        try r.fund(token, address(0), e, seq, 1) {
            ++unexpectedAuthoritySuccess;
        } catch {}
    }
}

contract CommunityAccountingInvariantTest is StdInvariant, CommunityFlowFixtureV2 {
    RetroPickBondingCurveV2 internal invariantCurve;
    CommunityFeeRouterV2 internal invariantRouter;
    CommunityAccountingHandler internal handler;

    function setUp() public override {
        super.setUp();
        (invariantCurve, invariantRouter) = launchCE(address(0), creator);
        handler = new CommunityAccountingHandler(invariantCurve, invariantRouter, creator, treasury);
        // Reach each intended branch deterministically before randomized sequences.
        handler.trade(1e16, false);
        handler.trade(1e8, true);
        handler.settle();
        handler.claim(0, 1);
        handler.propose(3000);
        handler.cancel();
        handler.propose(3000);
        handler.activate();
        handler.rotate();
        handler.donate(1);
        handler.unauthorized();
        handler.invalidSettlement();
        targetContract(address(handler));
        bytes4[] memory selectors = new bytes4[](10);
        selectors[0] = handler.trade.selector;
        selectors[1] = handler.settle.selector;
        selectors[2] = handler.claim.selector;
        selectors[3] = handler.propose.selector;
        selectors[4] = handler.cancel.selector;
        selectors[5] = handler.activate.selector;
        selectors[6] = handler.rotate.selector;
        selectors[7] = handler.donate.selector;
        selectors[8] = handler.unauthorized.selector;
        selectors[9] = handler.invalidSettlement.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function invariantCEConservationBackingAndRights() public view {
        assertEq(invariantRouter.totalFunded(), invariantRouter.totalPaid() + invariantRouter.totalLiability());
        assertEq(invariantRouter.credit(creator) + invariantRouter.credit(treasury), invariantRouter.totalLiability());
        assertGe(address(invariantRouter).balance, invariantRouter.totalLiability());
        assertGe(address(invariantCurve).balance, invariantCurve.trackedQuote());
        assertEq(
            invariantCurve.realQuoteReserve(),
            invariantCurve.trackedQuote() - invariantCurve.quoteFeeBalance() - invariantCurve.creatorTaxBalance()
        );
        assertEq(IERC20(invariantCurve.token()).totalSupply(), 1000000 ether);
        assertEq(handler.unexpectedAuthoritySuccess(), 0);
        assertGt(handler.trades(), 0);
        assertGt(handler.claims(), 0);
        assertGt(handler.activations(), 0);
        assertGt(handler.rotations(), 0);
        assertGt(handler.invalidAttempts(), 0);
    }

    function afterInvariant() public {
        // Inner economic reverts are caught by the handler, so report them separately
        // from Foundry's zero outer-handler revert count. Counts include the seeded actions.
        emit log_named_uint("successful trades", handler.trades());
        emit log_named_uint("successful settlements", handler.settlements());
        emit log_named_uint("successful claims", handler.claims());
        emit log_named_uint("successful proposals", handler.proposals());
        emit log_named_uint("successful cancellations", handler.cancellations());
        emit log_named_uint("successful activations", handler.activations());
        emit log_named_uint("successful controller rotations", handler.rotations());
        emit log_named_uint("donations", handler.donations());
        emit log_named_uint("unauthorized attempts", handler.unauthorizedAttempts());
        emit log_named_uint("invalid settlement attempts", handler.invalidAttempts());
        emit log_named_uint("caught economic rejections", handler.rejected());
    }
}

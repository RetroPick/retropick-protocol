// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Test} from "forge-std/Test.sol";
import {CommunityTreasuryIntegrationFixtureV2, TreasuryRejectingRecipient} from "./CommunityTreasuryIntegration.t.sol";
import {CommunityTreasuryVaultV2 as V} from "../../../../src/v2/CommunityTreasuryVaultV2.sol";
import {CommunityTimelockV2 as T} from "../../../../src/v2/CommunityTimelockV2.sol";
import {CommunityFeeRouterV2 as R} from "../../../../src/v2/CommunityFeeRouterV2.sol";
import {RetroPickBondingCurveV2 as C} from "../../../../src/v2/RetroPickBondingCurveV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TreasuryAccountingHandler is Test {
    C public curve;
    R public router;
    V public treasury;
    T public governance;
    address public creator;
    address public proposer;
    address public contributor;
    address public recipient;
    address public rejecting;
    uint256 public trades;
    uint256 public settlements;
    uint256 public treasuryClaims;
    uint256 public otherClaims;
    uint256 public schedules;
    uint256 public executions;
    uint256 public donations;
    uint256 public rejected;
    uint256 public failedExecutions;
    uint256 public unauthorizedAttempts;
    uint256 public unexpectedUnauthorizedSuccess;
    uint256 public nonce;

    struct Operation {
        bytes data;
        bytes32 salt;
    }
    Operation[] internal operations;

    constructor(C c, R r, V v, address creator_, address proposer_, address contributor_, address recipient_) {
        curve = c;
        router = r;
        treasury = v;
        governance = v.timelock();
        creator = creator_;
        proposer = proposer_;
        contributor = contributor_;
        recipient = recipient_;
        rejecting = address(new TreasuryRejectingRecipient());
    }

    function trade(uint256 amount, bool sell) public {
        amount = bound(amount, 1e8, 1e16);
        address token = curve.token();
        uint256 balance = IERC20(token).balanceOf(creator);
        vm.startPrank(creator);
        if (sell && balance > 1) {
            IERC20(token).approve(address(curve), balance / 2);
            try curve.sell(balance / 2, 0, creator) {
                ++trades;
            } catch {
                ++rejected;
            }
        } else {
            vm.deal(creator, creator.balance + amount);
            try curve.buy{value: amount}(amount, 0, creator) {
                ++trades;
            } catch {
                ++rejected;
            }
        }
        vm.stopPrank();
    }

    function settle() public {
        try router.settle() {
            ++settlements;
        } catch {
            ++rejected;
        }
    }

    function claim(uint256 amount) public {
        uint256 credit = router.credit(address(treasury));
        if (credit == 0) return;
        amount = amount == type(uint256).max ? credit : bound(amount, 1, credit);
        try treasury.claimFromRouter(amount) {
            ++treasuryClaims;
        } catch {
            ++rejected;
        }
    }

    function claimOther(uint256 seed, uint256 amount) public {
        address actor = seed % 2 == 0 ? creator : contributor;
        uint256 credit = router.credit(actor);
        if (credit == 0) return;
        amount = bound(amount, 1, credit);
        vm.prank(actor);
        try router.claim(amount) {
            ++otherClaims;
        } catch {
            ++rejected;
        }
    }

    function schedule(uint256 amount, bool badRecipient) public {
        uint256 earned = treasury.held();
        if (earned == 0) return;
        amount = bound(amount, 1, earned);
        bytes32 id = keccak256(abi.encode(address(this), ++nonce));
        bytes memory data = abi.encodeCall(V.spend, (address(0), badRecipient ? rejecting : recipient, amount, id));
        vm.prank(proposer);
        try governance.schedule(address(treasury), 0, data, bytes32(0), id, 72 hours) {
            operations.push(Operation(data, id));
            ++schedules;
        } catch {
            ++rejected;
        }
    }

    function execute(uint256 seed) public {
        if (operations.length == 0) return;
        Operation memory op = operations[seed % operations.length];
        uint256 eta =
            governance.getTimestamp(governance.hashOperation(address(treasury), 0, op.data, bytes32(0), op.salt));
        if (eta > 1 && eta > block.timestamp) vm.warp(eta);
        try governance.execute(address(treasury), 0, op.data, bytes32(0), op.salt) {
            ++executions;
        } catch {
            ++failedExecutions;
        }
    }

    function donate(uint256 amount) public {
        amount = bound(amount, 1, 1e15);
        vm.deal(address(this), amount);
        (bool ok,) = address(treasury).call{value: amount}("");
        require(ok);
        ++donations;
    }

    function unauthorized() public {
        ++unauthorizedAttempts;
        try treasury.spend(address(0), recipient, 1, bytes32(uint256(1000))) {
            ++unexpectedUnauthorizedSuccess;
        } catch {}
    }
}

contract CanonicalCommunityTreasuryInvariantTest is CommunityTreasuryIntegrationFixtureV2 {
    C internal c;
    R internal r;
    V internal v;
    TreasuryAccountingHandler internal handler;

    function setUp() public override {
        super.setUp();
        (c, r, v) = launch(address(0));
        handler = new TreasuryAccountingHandler(c, r, v, creator, proposer, contributor, recipient);
        handler.trade(1e16, false);
        handler.trade(1, true);
        handler.settle();
        handler.claim(type(uint256).max);
        handler.claimOther(0, 1);
        handler.schedule(1, false);
        handler.execute(0);
        handler.schedule(1, true);
        handler.execute(1);
        handler.donate(1);
        handler.unauthorized();
        targetContract(address(handler));
        bytes4[] memory selectors = new bytes4[](8);
        selectors[0] = handler.trade.selector;
        selectors[1] = handler.settle.selector;
        selectors[2] = handler.claim.selector;
        selectors[3] = handler.claimOther.selector;
        selectors[4] = handler.schedule.selector;
        selectors[5] = handler.execute.selector;
        selectors[6] = handler.donate.selector;
        selectors[7] = handler.unauthorized.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function invariantCETreasuryEarnedCustodyAndSourceConservation() public view {
        assertEq(v.claimed(), v.spent() + v.held());
        assertGe(v.actualBalance(), v.held());
        assertEq(v.actualBalance(), v.held() + v.surplus());
        assertEq(v.deficit(), 0);
        assertEq(r.totalFunded(), r.totalPaid() + r.totalLiability());
        assertGe(address(r).balance, r.totalLiability());
        assertEq(r.credit(creator) + r.credit(contributor) + r.credit(address(v)), r.totalLiability());
        assertGe(address(c).balance, c.trackedQuote());
        assertEq(c.realQuoteReserve(), c.trackedQuote() - c.quoteFeeBalance() - c.creatorTaxBalance());
        assertEq(handler.unexpectedUnauthorizedSuccess(), 0);
        assertGt(handler.trades(), 0);
        assertGt(handler.treasuryClaims(), 0);
        assertGt(handler.executions(), 0);
        assertGt(handler.failedExecutions(), 0);
        assertGt(handler.donations(), 0);
        assertGt(handler.unauthorizedAttempts(), 0);
    }

    function afterInvariant() public {
        emit log_named_uint("successful trades (includes seed)", handler.trades());
        emit log_named_uint("successful settlements", handler.settlements());
        emit log_named_uint("successful treasury claims", handler.treasuryClaims());
        emit log_named_uint("successful other claims", handler.otherClaims());
        emit log_named_uint("successful schedules", handler.schedules());
        emit log_named_uint("successful executions", handler.executions());
        emit log_named_uint("failed executions caught", handler.failedExecutions());
        emit log_named_uint("other economic rejections caught", handler.rejected());
        emit log_named_uint("donations", handler.donations());
        emit log_named_uint("unauthorized attempts", handler.unauthorizedAttempts());
    }
}

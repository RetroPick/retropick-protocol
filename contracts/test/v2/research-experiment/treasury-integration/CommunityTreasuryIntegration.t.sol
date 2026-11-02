// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockERC20} from "../../../mocks/MockERC20.sol";
import {CommunityFactoryFixtureV2} from "../CommunityFactoryFixtureV2.sol";
import {CommunityLaunchBuilderV2 as L} from "../../../../src/v2-research-experiment/CommunityLaunchBuilderV2.sol";
import {
    CommunityTreasuryLaunchBuilderV2 as B
} from "../../../../src/v2-research-experiment/CommunityTreasuryLaunchBuilderV2.sol";
import {CommunityTreasuryDeployerV2 as D} from "../../../../src/v2-research-experiment/CommunityTreasuryDeployerV2.sol";
import {CommunityTreasuryVaultV2 as V} from "../../../../src/v2-research-experiment/CommunityTreasuryVaultV2.sol";
import {CommunityTimelockV2 as T} from "../../../../src/v2-research-experiment/CommunityTimelockV2.sol";
import {CommunityFeeRouterV2 as R} from "../../../../src/v2-research-experiment/CommunityFeeRouterV2.sol";
import {CommunityPolicyRegistryV2 as P} from "../../../../src/v2-research-experiment/CommunityPolicyRegistryV2.sol";
import {CommunityControllerV2 as Controller} from "../../../../src/v2-research-experiment/CommunityControllerV2.sol";
import {RetroPickLaunchFactoryV2 as F} from "../../../../src/v2-research-experiment/RetroPickLaunchFactoryV2.sol";
import {RetroPickBondingCurveV2 as C} from "../../../../src/v2-research-experiment/RetroPickBondingCurveV2.sol";

contract TreasuryIntegrationQuote is MockERC20 {
    uint256 public mode;
    address public callback;
    bool public attempted;
    bool public callbackSucceeded;
    constructor() MockERC20("Exact quote", "Q", 6) {}

    function configure(uint256 mode_, address callback_) external {
        mode = mode_;
        callback = callback_;
        attempted = false;
    }

    function slash(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (mode == 1) return false;
        bool ok = super.transfer(to, amount);
        if (callback != address(0) && !attempted) {
            attempted = true;
            (callbackSucceeded,) = callback.call(abi.encodeWithSelector(V.claimFromRouter.selector, 1));
        }
        return ok;
    }

    function _update(address from, address to, uint256 amount) internal override {
        super._update(from, to, amount);
        if (from != address(0) && to != address(0)) {
            if (mode == 2) _burn(to, amount / 10);
            if (mode == 3) _burn(from, amount / 10);
        }
    }
}

contract TreasuryRejectingRecipient {
    receive() external payable {
        revert("reject");
    }
}

contract TreasuryReentrantRecipient {
    V public target;
    bool public reentered;

    constructor(V target_) {
        target = target_;
    }

    receive() external payable {
        (reentered,) = address(target).call(abi.encodeCall(V.claimFromRouter, (1)));
    }
}

/// @notice Real experimental financial contracts; external market destinations and proposer identity are fixtures.
/// @dev The proposer is a role actor, not a qualified live Safe deployment.
abstract contract CommunityTreasuryIntegrationFixtureV2 is CommunityFactoryFixtureV2 {
    B internal builder;
    D internal treasuryDeployment;
    address internal proposer = makeAddr("treasury-proposer-role-fixture");
    address internal recipient = makeAddr("spend-recipient");
    address internal contributor = makeAddr("contributor");
    address internal guardian = makeAddr("guardian");
    address internal constant CIRCLE = 0x534b2f3A21130d7a60830c2Df862319e593943A3;

    function setUp() public virtual override {
        super.setUp();
        treasuryDeployment = new D(address(factory));
        builder = new B(address(factory), treasuryDeployment);
        factory.setCommunityBuilder(builder);
    }

    function quote() internal returns (TreasuryIntegrationQuote q) {
        TreasuryIntegrationQuote implementation = new TreasuryIntegrationQuote();
        vm.etch(CIRCLE, address(implementation).code);
        q = TreasuryIntegrationQuote(CIRCLE);
        _admit(CIRCLE, 100e6, 100e6, 6);
        q.mint(creator, 1000e6);
    }

    function config(bool invalid) internal view returns (bytes memory) {
        L.Config memory c;
        c.controller = creator;
        c.guardian = guardian;
        c.bounds = P.Bounds(6000, 4000, 150, 3 days);
        c.allocations = new P.Allocation[](3);
        c.allocations[0] = P.Allocation(creator, 4000, 0);
        c.allocations[1] = P.Allocation(contributor, 2000, 1);
        c.allocations[2] = P.Allocation(address(0), invalid ? 3000 : 4000, 2);
        return abi.encode(B.ConfigV1(1, c, proposer));
    }

    function launch(address asset) internal returns (C c, R r, V v) {
        F.TokenParams memory p = _params(bytes32(uint256(903)));
        p.expectedEconomics = factory.previewLaunchEconomics(0, asset);
        bytes memory cfg = config(false);
        bytes32 h = keccak256(abi.encode(address(builder), address(builder).codehash, cfg));
        vm.prank(creator);
        (, address curve) = factory.launchCommunityToken(p, 0, asset, cfg, h);
        c = C(payable(curve));
        r = R(payable(c.communityRouter()));
        v = V(payable(treasuryDeployment.vaultForRouter(address(r))));
    }

    function cycle(C c, uint256 amount) internal {
        address asset = c.pairToken();
        vm.startPrank(creator);
        if (asset != address(0)) IERC20(asset).approve(address(c), amount);
        uint256 bought = c.buy{value: asset == address(0) ? amount : 0}(amount, 0, creator);
        IERC20(c.token()).approve(address(c), bought / 2);
        c.sell(bought / 2, 0, creator);
        vm.stopPrank();
    }

    function payload(V v, address to, uint256 amount, bytes32 id) internal view returns (bytes memory) {
        return abi.encodeCall(V.spend, (v.feeAsset(), to, amount, id));
    }

    function queue(T t, V v, bytes memory data, bytes32 salt) internal returns (bytes32 op) {
        op = t.hashOperation(address(v), 0, data, bytes32(0), salt);
        vm.prank(proposer);
        t.schedule(address(v), 0, data, bytes32(0), salt, 72 hours);
    }

    function runFlow(address asset, uint256 amount) internal {
        (C c, R r, V v) = launch(asset);
        assertEq(v.factory(), address(factory));
        assertEq(v.launchToken(), c.token());
        assertEq(v.creator(), creator);
        assertEq(address(v.router()), address(r));
        assertEq(r.registry().module(2), address(v));
        cycle(c, amount);
        uint256 protocolOwed = c.quoteFeeBalance() * c.protocolFeeShareBps() / 10000;
        uint256 communityOwed = c.quoteFeeBalance() - protocolOwed + c.creatorTaxBalance();
        uint256 reserve = c.realQuoteReserve();
        r.settle();
        assertEq(c.realQuoteReserve(), reserve);
        assertEq(r.totalFunded(), communityOwed);
        assertEq(
            asset == address(0) ? escrow.balanceOf(protocol) : escrow.balanceOfToken(protocol, asset), protocolOwed
        );
        uint256 credit = r.credit(address(v));
        vm.expectRevert(V.InvalidClaim.selector);
        v.claimFromRouter(0);
        v.claimFromRouter(credit / 2);
        assertEq(v.claimed(), credit / 2);
        assertEq(v.held(), credit / 2);
        assertEq(r.credit(address(v)), credit - credit / 2);
        uint256 contributorCredit = r.credit(contributor);
        vm.prank(contributor);
        r.claim(contributorCredit);
        T t = v.timelock();
        bytes memory data = payload(v, recipient, credit / 4, bytes32(uint256(1)));
        bytes32 salt = bytes32(uint256(1));
        bytes32 op = queue(t, v, data, salt);
        vm.expectRevert();
        t.execute(address(v), 0, data, bytes32(0), salt);
        uint256 before = asset == address(0) ? recipient.balance : IERC20(asset).balanceOf(recipient);
        vm.warp(t.getTimestamp(op));
        t.execute(address(v), 0, data, bytes32(0), salt);
        assertEq((asset == address(0) ? recipient.balance : IERC20(asset).balanceOf(recipient)) - before, credit / 4);
        assertEq(v.claimed(), v.spent() + v.held());
        assertEq(v.actualBalance(), v.held());
        assertEq(r.totalFunded(), r.totalPaid() + r.totalLiability());
        vm.expectRevert();
        t.execute(address(v), 0, data, bytes32(0), salt);
    }
}

contract CommunityTreasuryIntegrationTest is CommunityTreasuryIntegrationFixtureV2 {
    function testCETreasuryNativeTradeClaimTimelockedSpend() public {
        runFlow(address(0), 1 ether);
    }

    function testCETreasuryUSDCTradeClaimTimelockedSpend() public {
        quote();
        runFlow(CIRCLE, 1e6);
    }

    function testCETreasuryTwoSameCreatorLaunchesAndCrossGovernanceIsolation() public {
        (C a, R ra, V va) = launch(address(0));
        (C b, R rb, V vb) = launch(address(0));
        assertTrue(address(va) != address(vb));
        assertTrue(address(va.timelock()) != address(vb.timelock()));
        cycle(a, 1 ether);
        cycle(b, 1 ether);
        ra.settle();
        rb.settle();
        uint256 ca = ra.credit(address(va));
        uint256 cb = rb.credit(address(vb));
        va.claimFromRouter(ca);
        assertEq(rb.credit(address(vb)), cb);
        vb.claimFromRouter(cb);
        T tb = vb.timelock();
        bytes memory data = payload(va, recipient, 1, bytes32(uint256(2)));
        bytes32 salt = bytes32(uint256(2));
        bytes32 op = queue(tb, va, data, salt);
        vm.warp(tb.getTimestamp(op));
        vm.expectRevert(V.Unauthorized.selector);
        tb.execute(address(va), 0, data, bytes32(0), salt);
        assertEq(va.held(), ca);
        assertEq(vb.held(), cb);
        vm.prank(address(va));
        vm.expectRevert(R.InvalidSettlement.selector);
        rb.claimTo(address(va), 1);
    }

    function testCETreasuryDonationsCannotBecomeSpendableAndUnauthorizedSpendsFail() public {
        (C c, R r, V v) = launch(address(0));
        cycle(c, 1 ether);
        r.settle();
        uint256 credit = r.credit(address(v));
        vm.deal(address(this), 1 ether);
        (bool donated,) = address(v).call{value: 1 ether}("");
        assertTrue(donated);
        assertEq(v.claimed(), 0);
        assertEq(v.surplus(), 1 ether);
        v.claimFromRouter(credit);
        assertEq(v.surplus(), 1 ether);
        vm.expectRevert(V.Unauthorized.selector);
        v.spend(address(0), recipient, 1, bytes32(uint256(3)));
        T t = v.timelock();
        bytes memory data = payload(v, recipient, credit + 1, bytes32(uint256(3)));
        bytes32 salt = bytes32(uint256(3));
        bytes32 op = queue(t, v, data, salt);
        vm.warp(t.getTimestamp(op));
        vm.expectRevert(V.InvalidSpend.selector);
        t.execute(address(v), 0, data, bytes32(0), salt);
        assertEq(v.held(), credit);
        assertEq(v.surplus(), 1 ether);
    }

    function testCETreasuryPolicyAndControllerChangesPreserveOldRightsAndGovernance() public {
        (C c, R r, V v) = launch(address(0));
        cycle(c, 1 ether);
        uint256 oldCommunity =
            c.quoteFeeBalance() - c.quoteFeeBalance() * c.protocolFeeShareBps() / 10000 + c.creatorTaxBalance();
        P reg = r.registry();
        P.Allocation[] memory next = new P.Allocation[](3);
        next[0] = P.Allocation(creator, 2000, 0);
        next[1] = P.Allocation(contributor, 1000, 1);
        next[2] = P.Allocation(address(v), 7000, 2);
        vm.prank(creator);
        uint256 n = reg.proposePolicy(next);
        vm.warp(block.timestamp + 3 days);
        reg.activatePolicy(n);
        uint256 oldTreasury = oldCommunity - oldCommunity * 4000 / 10000 - oldCommunity * 2000 / 10000;
        assertEq(r.credit(address(v)), oldTreasury);
        Controller control = Controller(r.authority());
        vm.prank(creator);
        control.schedule(address(0xCAFE), false);
        vm.warp(control.effectiveAt());
        uint256 cn = control.nonce();
        vm.prank(address(0xCAFE));
        control.accept(cn);
        assertEq(r.credit(address(v)), oldTreasury);
        v.claimFromRouter(oldTreasury);
        cycle(c, 1 ether);
        uint256 newCommunity =
            c.quoteFeeBalance() - c.quoteFeeBalance() * c.protocolFeeShareBps() / 10000 + c.creatorTaxBalance();
        r.settle();
        assertEq(r.credit(address(v)), newCommunity - newCommunity * 2000 / 10000 - newCommunity * 1000 / 10000);
        assertEq(v.claimed(), oldTreasury);
        assertFalse(v.timelock().hasRole(v.timelock().PROPOSER_ROLE(), address(0xCAFE)));
    }

    function testCETreasuryFailedRecipientDoesNotConsumeOperationAndOtherSpendSucceeds() public {
        (C c, R r, V v) = launch(address(0));
        cycle(c, 1 ether);
        r.settle();
        v.claimFromRouter(r.credit(address(v)));
        uint256 old = v.held();
        T t = v.timelock();
        bytes memory bad = payload(v, address(new TreasuryRejectingRecipient()), old / 2, bytes32(uint256(4)));
        bytes memory good = payload(v, recipient, old / 2, bytes32(uint256(5)));
        bytes32 badSalt = bytes32(uint256(4));
        bytes32 goodSalt = bytes32(uint256(5));
        bytes32 op = queue(t, v, bad, badSalt);
        queue(t, v, good, goodSalt);
        vm.warp(t.getTimestamp(op));
        vm.expectRevert(V.TransferFailed.selector);
        t.execute(address(v), 0, bad, bytes32(0), badSalt);
        assertTrue(t.isOperationReady(op));
        assertFalse(v.spentIds(bytes32(uint256(4))));
        assertEq(v.held(), old);
        t.execute(address(v), 0, good, bytes32(0), goodSalt);
        assertEq(v.spent(), old / 2);
    }

    function testCETreasuryNativeReentryCannotClaimWhileSpending() public {
        (C c, R r, V v) = launch(address(0));
        cycle(c, 1 ether);
        r.settle();
        uint256 credit = r.credit(address(v));
        v.claimFromRouter(credit / 2);
        TreasuryReentrantRecipient receiver = new TreasuryReentrantRecipient(v);
        T t = v.timelock();
        bytes memory data = payload(v, address(receiver), v.held() / 2, bytes32(uint256(6)));
        bytes32 salt = bytes32(uint256(6));
        bytes32 op = queue(t, v, data, salt);
        vm.warp(t.getTimestamp(op));
        t.execute(address(v), 0, data, bytes32(0), salt);
        assertFalse(receiver.reentered());
        assertEq(v.claimed(), credit / 2);
        assertEq(r.credit(address(v)), credit - credit / 2);
    }

    function testCETreasuryExpiryAndSpendIdReplayRejected() public {
        (C c, R r, V v) = launch(address(0));
        cycle(c, 1 ether);
        r.settle();
        v.claimFromRouter(r.credit(address(v)));
        T t = v.timelock();
        bytes memory data = payload(v, recipient, 1, bytes32(uint256(7)));
        bytes32 salt = bytes32(uint256(7));
        bytes32 op = queue(t, v, data, salt);
        vm.warp(t.getTimestamp(op) + 7 days + 1);
        vm.expectRevert(abi.encodeWithSelector(T.OperationExpired.selector, op));
        t.execute(address(v), 0, data, bytes32(0), salt);
        bytes32 fresh = bytes32(uint256(8));
        op = queue(t, v, data, fresh);
        vm.warp(t.getTimestamp(op));
        t.execute(address(v), 0, data, bytes32(0), fresh);
        bytes32 replay = bytes32(uint256(9));
        op = queue(t, v, data, replay);
        vm.warp(t.getTimestamp(op));
        vm.expectRevert(V.InvalidSpend.selector);
        t.execute(address(v), 0, data, bytes32(0), replay);
        assertEq(v.spent(), 1);
    }

    function testCETreasuryQuoteDeficitBlocksNewClaimsAndSpending() public {
        TreasuryIntegrationQuote q = quote();
        (C c, R r, V v) = launch(CIRCLE);
        cycle(c, 1e6);
        r.settle();
        v.claimFromRouter(r.credit(address(v)));
        uint256 old = v.held();
        q.slash(address(v), 1);
        assertEq(v.deficit(), 1);
        cycle(c, 1e6);
        r.settle();
        uint256 debt = r.credit(address(v));
        vm.expectRevert(V.BackingDeficit.selector);
        v.claimFromRouter(1);
        assertEq(r.credit(address(v)), debt);
        T t = v.timelock();
        bytes memory data = payload(v, recipient, 1, bytes32(uint256(10)));
        bytes32 salt = bytes32(uint256(10));
        bytes32 op = queue(t, v, data, salt);
        vm.warp(t.getTimestamp(op));
        vm.expectRevert(V.BackingDeficit.selector);
        t.execute(address(v), 0, data, bytes32(0), salt);
        q.mint(address(v), 1);
        v.claimFromRouter(1);
        assertEq(v.claimed(), old + 1);
        assertEq(v.deficit(), 0);
    }

    function testCETreasuryFalseAndInexactQuotePayoutsRollbackCredits() public {
        TreasuryIntegrationQuote q = quote();
        (C c, R r, V v) = launch(CIRCLE);
        cycle(c, 1e6);
        r.settle();
        uint256 debt = r.credit(address(v));
        for (uint256 m = 1; m <= 3; ++m) {
            q.configure(m, address(0));
            vm.expectRevert();
            v.claimFromRouter(debt);
            assertEq(r.credit(address(v)), debt);
            assertEq(v.claimed(), 0);
        }
        q.configure(0, address(v));
        v.claimFromRouter(debt);
        assertTrue(q.attempted());
        assertFalse(q.callbackSucceeded());
        assertEq(v.claimed(), debt);
    }

    function failedLaunch(address asset, bytes memory cfg, bytes4 selector) internal {
        F.TokenParams memory p = _params(bytes32(uint256(903)));
        p.expectedEconomics = factory.previewLaunchEconomics(0, asset);
        bytes32 h = keccak256(abi.encode(address(builder), address(builder).codehash, cfg));
        vm.prank(creator);
        vm.expectRevert(selector);
        factory.launchCommunityToken(p, 0, asset, cfg, h);
    }

    function testCETreasuryRealConstructorAndLateRegistryFailureRollbackAndRetry() public {
        uint64 dn = vm.getNonce(address(treasuryDeployment));
        uint64 bn = vm.getNonce(address(builder));
        uint64 fn = vm.getNonce(address(factory));
        uint64 sn = vm.getNonce(address(deployer));
        address predictedRouter = computeCreateAddress(address(builder), bn + 1);
        address predictedToken = computeCreateAddress(address(deployer), sn + 1);
        address oldProposer = proposer;
        proposer = address(treasuryDeployment);
        failedLaunch(address(0), config(false), T.InvalidProposer.selector);
        proposer = oldProposer;
        assertEq(vm.getNonce(address(treasuryDeployment)), dn);
        assertEq(vm.getNonce(address(builder)), bn);
        assertEq(vm.getNonce(address(deployer)), sn);
        assertEq(vm.getNonce(address(factory)), fn);
        failedLaunch(address(0), config(true), P.InvalidPolicy.selector);
        assertEq(vm.getNonce(address(treasuryDeployment)), dn);
        assertEq(vm.getNonce(address(builder)), bn);
        assertEq(vm.getNonce(address(deployer)), sn);
        assertEq(vm.getNonce(address(factory)), fn);
        assertEq(treasuryDeployment.vaultForRouter(predictedRouter), address(0));
        assertEq(treasuryDeployment.vaultForToken(predictedToken), address(0));
        assertEq(predictedRouter.code.length, 0);
        assertEq(predictedToken.code.length, 0);
        (C c, R r, V v) = launch(address(0));
        assertEq(address(r), predictedRouter);
        assertEq(c.token(), predictedToken);
        assertEq(treasuryDeployment.vaultForToken(predictedToken), address(v));
        cycle(c, 1 ether);
        r.settle();
        v.claimFromRouter(r.credit(address(v)));
        assertGt(v.held(), 0);
    }

    function testCETreasuryDeployerCannotReuseFundedRouterOrWrongCaller() public {
        (, R r,) = launch(address(0));
        vm.expectRevert(D.InvalidDeployment.selector);
        treasuryDeployment.deployForLaunch(r, creator, proposer);
        vm.prank(address(builder));
        vm.expectRevert(D.InvalidDeployment.selector);
        treasuryDeployment.deployForLaunch(r, creator, proposer);
    }

    function testCETreasuryOneUnitDustNativeAndUSDC() public {
        quote();
        for (uint256 i; i < 2; ++i) {
            address asset = i == 0 ? address(0) : CIRCLE;
            (C c, R r, V v) = launch(asset);
            cycle(c, 100);
            assertEq(c.quoteFeeBalance(), 1);
            r.settle();
            assertEq(r.credit(address(v)), 1);
            assertEq(r.credit(creator), 0);
            assertEq(r.credit(contributor), 0);
            v.claimFromRouter(1);
            T t = v.timelock();
            bytes memory data = payload(v, recipient, 1, bytes32(uint256(12)));
            bytes32 salt = bytes32(uint256(12));
            bytes32 op = queue(t, v, data, salt);
            vm.warp(t.getTimestamp(op));
            t.execute(address(v), 0, data, bytes32(0), salt);
            assertEq(v.claimed(), 1);
            assertEq(v.spent(), 1);
            assertEq(v.actualBalance(), 0);
        }
    }

    function testCETreasuryInvalidSpendFieldsRejectedThroughRealTimelock() public {
        (C c, R r, V v) = launch(address(0));
        cycle(c, 1 ether);
        r.settle();
        v.claimFromRouter(r.credit(address(v)));
        T t = v.timelock();
        uint256 beforeHeld = v.held();
        bytes32 id = bytes32(uint256(13));
        bytes[] memory calls = new bytes[](5);
        calls[0] = abi.encodeCall(V.spend, (address(1), recipient, 1, id));
        calls[1] = payload(v, recipient, 0, id);
        calls[2] = payload(v, address(v), 1, id);
        calls[3] = payload(v, address(0), 1, id);
        calls[4] = payload(v, recipient, 1, bytes32(0));
        for (uint256 i; i < calls.length; ++i) {
            bytes32 salt = bytes32(uint256(100 + i));
            bytes32 op = queue(t, v, calls[i], salt);
            vm.warp(t.getTimestamp(op));
            vm.expectRevert(V.InvalidSpend.selector);
            t.execute(address(v), 0, calls[i], bytes32(0), salt);
            assertEq(v.held(), beforeHeld);
            assertEq(v.spent(), 0);
        }
    }

    function testCETreasuryBatchFailureRollsBackEarlierRealPayment() public {
        (C c, R r, V v) = launch(address(0));
        cycle(c, 1 ether);
        r.settle();
        v.claimFromRouter(r.credit(address(v)));
        T t = v.timelock();
        bytes memory data = payload(v, recipient, 1, bytes32(uint256(14)));
        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](2);
        bytes[] memory calls = new bytes[](2);
        targets[0] = address(v);
        targets[1] = address(v);
        calls[0] = data;
        calls[1] = data;
        bytes32 salt = bytes32(uint256(14));
        bytes32 op = t.hashOperationBatch(targets, values, calls, bytes32(0), salt);
        vm.prank(proposer);
        t.scheduleBatch(targets, values, calls, bytes32(0), salt, 72 hours);
        vm.warp(t.getTimestamp(op));
        uint256 before = recipient.balance;
        vm.expectRevert(V.InvalidSpend.selector);
        t.executeBatch(targets, values, calls, bytes32(0), salt);
        assertEq(v.spent(), 0);
        assertFalse(v.spentIds(bytes32(uint256(14))));
        assertEq(recipient.balance, before);
        assertTrue(t.isOperationReady(op));
    }

    function testFuzzCETreasuryRealFundingClaimsAndSpend(uint96 amount, uint16 fraction) public {
        amount = uint96(bound(amount, 1e8, 1 ether));
        fraction = uint16(bound(fraction, 1, 10000));
        (C c, R r, V v) = launch(address(0));
        cycle(c, amount);
        r.settle();
        uint256 credit = r.credit(address(v));
        uint256 collect = credit * fraction / 10000;
        v.claimFromRouter(collect);
        T t = v.timelock();
        bytes memory data = payload(v, recipient, collect, bytes32(uint256(11)));
        bytes32 salt = bytes32(uint256(11));
        bytes32 op = queue(t, v, data, salt);
        vm.warp(t.getTimestamp(op));
        t.execute(address(v), 0, data, bytes32(0), salt);
        assertEq(v.claimed(), collect);
        assertEq(v.spent(), collect);
        assertEq(v.held(), 0);
        assertEq(v.actualBalance(), 0);
        assertEq(r.credit(address(v)), credit - collect);
        assertEq(r.totalFunded(), r.totalPaid() + r.totalLiability());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {CommunityFactoryFixtureV2} from "./CommunityFactoryFixtureV2.sol";
import {MockERC20} from "../../mocks/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RetroPickLaunchFactoryV2} from "../../../src/v2-research-experiment/RetroPickLaunchFactoryV2.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2-research-experiment/RetroPickBondingCurveV2.sol";
import {CommunityFeeRouterV2} from "../../../src/v2-research-experiment/CommunityFeeRouterV2.sol";
import {CommunityLaunchBuilderV2 as Builder} from "../../../src/v2-research-experiment/CommunityLaunchBuilderV2.sol";
import {CommunityPolicyRegistryV2 as Registry} from "../../../src/v2-research-experiment/CommunityPolicyRegistryV2.sol";
import {CommunityControllerV2} from "../../../src/v2-research-experiment/CommunityControllerV2.sol";

contract CEAdversarialQuote is MockERC20 {
    uint256 public mode;
    address public target;
    bytes public payload;
    bool public attempted;
    bool public callbackSucceeded;
    constructor() MockERC20("USDC-like", "USDC", 6) {}

    function configure(uint256 m, address t, bytes calldata data) external {
        mode = m;
        target = t;
        payload = data;
        attempted = false;
    }

    function slash(address a, uint256 amount) external {
        _burn(a, amount);
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (mode == 4) return false;
        bool ok = super.transferFrom(from, to, value);
        if (mode == 1) _burn(from, value / 10);
        if (mode == 2) _burn(to, value / 10);
        if (mode == 3) revert("injected transfer failure");
        if (target != address(0) && !attempted) {
            attempted = true;
            (callbackSucceeded,) = target.call(payload);
        }
        return ok;
    }
}

contract CERevertingBeneficiary {
    receive() external payable {
        revert("reject");
    }

    function claim(CommunityFeeRouterV2 r, uint256 n) external {
        r.claim(n);
    }
}

contract CEReentrantBeneficiary {
    CommunityFeeRouterV2 public r;
    bool public reentered;

    function claim(CommunityFeeRouterV2 r_, uint256 n) external {
        r = r_;
        r_.claim(n);
    }

    receive() external payable {
        (reentered,) = address(r).call(abi.encodeCall(r.claim, (1)));
    }
}

abstract contract CommunityFlowFixtureV2 is CommunityFactoryFixtureV2 {
    Builder internal builder;
    address internal treasury = makeAddr("community-treasury");
    address internal guardian = makeAddr("guardian");
    address internal constant CIRCLE = 0x534b2f3A21130d7a60830c2Df862319e593943A3;

    function setUp() public virtual override {
        super.setUp();
        builder = new Builder(address(factory));
        factory.setCommunityBuilder(builder);
    }

    function allocation(uint16 bps, address beneficiary) internal view returns (Registry.Allocation[] memory a) {
        a = new Registry.Allocation[](2);
        a[0] = Registry.Allocation(beneficiary, bps, 0);
        a[1] = Registry.Allocation(treasury, uint16(10000 - bps), 2);
    }

    function launchCE(address quote, address beneficiary)
        internal
        returns (RetroPickBondingCurveV2 curve, CommunityFeeRouterV2 router)
    {
        Builder.Config memory c;
        c.controller = creator;
        c.guardian = guardian;
        c.bounds = Registry.Bounds(6000, 4000, 150, 3 days);
        c.modules[0] = treasury;
        c.allocations = allocation(6000, beneficiary);
        bytes memory config = abi.encode(c);
        bytes32 commitment = keccak256(abi.encode(address(builder), address(builder).codehash, config));
        RetroPickLaunchFactoryV2.TokenParams memory p = _params(bytes32(uint256(903)));
        p.expectedEconomics = factory.previewLaunchEconomics(0, quote);
        vm.prank(creator);
        (, address src) = factory.launchCommunityToken(p, 0, quote, config, commitment);
        curve = RetroPickBondingCurveV2(payable(src));
        router = CommunityFeeRouterV2(payable(curve.communityRouter()));
    }

    function installQuote() internal returns (CEAdversarialQuote q) {
        CEAdversarialQuote impl = new CEAdversarialQuote();
        vm.etch(CIRCLE, address(impl).code);
        q = CEAdversarialQuote(CIRCLE);
        _admit(CIRCLE, 100e6, 100e6, 6);
        q.mint(creator, 1000e6);
    }

    function cycle(RetroPickBondingCurveV2 curve, uint256 amount) internal {
        address quote = curve.pairToken();
        vm.startPrank(creator);
        if (quote != address(0)) IERC20(quote).approve(address(curve), amount);
        uint256 tokens = curve.buy{value: quote == address(0) ? amount : 0}(amount, 0, creator);
        IERC20(curve.token()).approve(address(curve), tokens / 2);
        curve.sell(tokens / 2, 0, creator);
        vm.stopPrank();
    }

    function communityOwed(RetroPickBondingCurveV2 c) internal view returns (uint256 p, uint256 owed) {
        uint256 f = c.quoteFeeBalance();
        p = f * c.protocolFeeShareBps() / 10000;
        owed = f - p + c.creatorTaxBalance();
    }

    function proveFlow(address quote, uint256 unit) internal {
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(quote, creator);
        Registry reg = r.registry();
        cycle(c, unit);
        (uint256 p, uint256 owed) = communityOwed(c);
        uint256 reserve = c.realQuoteReserve();
        r.settle();
        assertEq(c.realQuoteReserve(), reserve);
        assertEq(r.credit(creator), owed * 6000 / 10000);
        assertEq(r.credit(treasury), owed - owed * 6000 / 10000);
        assertEq(quote == address(0) ? escrow.balanceOf(protocol) : escrow.balanceOfToken(protocol, quote), p);
        uint256 creatorPart = r.credit(creator) / 2;
        vm.prank(creator);
        r.claim(creatorPart);
        uint256 treasuryPart = r.credit(treasury);
        vm.prank(treasury);
        r.claim(treasuryPart);
        cycle(c, unit);
        vm.prank(creator);
        uint256 n = reg.proposePolicy(allocation(3000, creator));
        vm.expectRevert(Registry.OutsideWindow.selector);
        reg.activatePolicy(n);
        uint256 previous = r.credit(creator);
        (, uint256 oldOwed) = communityOwed(c);
        vm.warp(block.timestamp + 3 days);
        reg.activatePolicy(n);
        assertEq(r.credit(creator), previous + oldOwed * 6000 / 10000);
        assertEq(reg.epoch(), 2);
        assertEq(c.communityPending(), 0);
        previous = r.credit(creator);
        cycle(c, unit);
        (, owed) = communityOwed(c);
        r.settle();
        assertEq(r.credit(creator), previous + owed * 3000 / 10000);
        assertEq(r.epochFunded(1) + r.epochFunded(2), r.totalFunded());
        assertEq(r.totalFunded(), r.totalPaid() + r.totalLiability());
        assertEq(quote == address(0) ? address(r).balance : IERC20(quote).balanceOf(address(r)), r.totalLiability());
    }
}

contract CommunityCurveFlowTest is CommunityFlowFixtureV2 {
    function testCENativeRealTradesPolicyAndClaims() public {
        proveFlow(address(0), 1 ether);
    }

    function testCEUSDCRealTradesPolicyAndClaims() public {
        installQuote();
        proveFlow(CIRCLE, 1e6);
    }

    function testCEBeneficiaryRotationCannotReassignAccruedRights() public {
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(address(0), creator);
        Registry reg = r.registry();
        address replacement = address(0xBEEF);
        cycle(c, 1 ether);
        (, uint256 oldOwed) = communityOwed(c);
        vm.prank(creator);
        uint256 n = reg.proposePolicy(allocation(3000, replacement));
        vm.warp(block.timestamp + 3 days);
        reg.activatePolicy(n);
        uint256 oldCredit = oldOwed * 6000 / 10000;
        assertEq(r.credit(creator), oldCredit);
        assertEq(r.credit(replacement), 0);
        cycle(c, 1 ether);
        (, uint256 newOwed) = communityOwed(c);
        r.settle();
        assertEq(r.credit(creator), oldCredit);
        assertEq(r.credit(replacement), newOwed * 3000 / 10000);
        vm.prank(creator);
        r.claim(oldCredit);
        assertEq(r.credit(creator), 0);
        assertEq(r.totalFunded(), r.totalPaid() + r.totalLiability());
    }

    function testCEUnauthorizedFundingReplayAndCrossLaunch() public {
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(address(0), creator);
        address tokenIdentity = c.token();
        vm.expectRevert(CommunityFeeRouterV2.Unauthorized.selector);
        r.fund(tokenIdentity, address(0), 1, 1, 1);
        cycle(c, 1 ether);
        r.settle();
        vm.prank(address(c));
        vm.expectRevert(CommunityFeeRouterV2.InvalidSettlement.selector);
        r.fund(tokenIdentity, address(0), 1, 1, 1);
        vm.prank(address(c));
        vm.expectRevert(CommunityFeeRouterV2.InvalidSettlement.selector);
        r.fund(address(123), address(0), 1, 2, 1);
        vm.prank(address(c));
        vm.expectRevert(CommunityFeeRouterV2.InvalidSettlement.selector);
        r.fund(tokenIdentity, address(0), 2, 2, 1);
        vm.prank(address(123));
        vm.expectRevert(CommunityFeeRouterV2.Unauthorized.selector);
        r.checkpoint(1);
        assertEq(r.totalFunded(), r.totalLiability());
    }

    function testCEDonationsAndRepeatedSettlementDoNotCreateIncome() public {
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(address(0), creator);
        vm.deal(address(this), 1 ether);
        (bool ok,) = address(r).call{value: 1 ether}("");
        assertTrue(ok);
        r.settle();
        assertEq(r.totalFunded(), 0);
        cycle(c, 1 ether);
        r.settle();
        uint256 n = r.sequence();
        uint256 f = r.totalFunded();
        r.settle();
        assertEq(r.sequence(), n);
        assertEq(r.totalFunded(), f);
        assertEq(address(r).balance, r.totalLiability() + 1 ether);
    }

    function testCERevertingBeneficiaryDoesNotBlockTreasury() public {
        CERevertingBeneficiary bad = new CERevertingBeneficiary();
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(address(0), address(bad));
        cycle(c, 1 ether);
        r.settle();
        uint256 debt = r.credit(address(bad));
        vm.expectRevert(CommunityFeeRouterV2.TransferFailed.selector);
        bad.claim(r, debt);
        assertEq(r.credit(address(bad)), debt);
        uint256 treasuryDebt = r.credit(treasury);
        vm.prank(treasury);
        r.claim(treasuryDebt);
        assertEq(r.credit(treasury), 0);
    }

    function testCEReentrantClaimCannotDoublePay() public {
        CEReentrantBeneficiary bad = new CEReentrantBeneficiary();
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(address(0), address(bad));
        cycle(c, 1 ether);
        r.settle();
        bad.claim(r, r.credit(address(bad)));
        assertFalse(bad.reentered());
        assertEq(r.credit(address(bad)), 0);
    }

    function testCEFundingFailureAndDeficitFailAtomically() public {
        CEAdversarialQuote q = installQuote();
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(CIRCLE, creator);
        cycle(c, 1e6);
        uint256 f = c.quoteFeeBalance();
        uint256 tracked = c.trackedQuote();
        q.configure(3, address(0), "");
        vm.expectRevert();
        r.settle();
        assertEq(c.quoteFeeBalance(), f);
        assertEq(c.trackedQuote(), tracked);
        assertEq(r.totalFunded(), 0);
        q.configure(0, address(0), "");
        r.settle();
        q.slash(address(r), 1);
        uint256 debt = r.credit(creator);
        vm.prank(creator);
        vm.expectRevert(CommunityFeeRouterV2.BackingDeficit.selector);
        r.claim(debt);
        assertEq(r.credit(creator), debt);
    }

    function testCEPolicyCallbackCannotActivateInsideTrade() public {
        CEAdversarialQuote q = installQuote();
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(CIRCLE, creator);
        Registry callbackRegistry = r.registry();
        vm.prank(creator);
        uint256 n = callbackRegistry.proposePolicy(allocation(3000, creator));
        vm.warp(block.timestamp + 3 days);
        q.configure(0, address(r.registry()), abi.encodeCall(Registry.activatePolicy, (n)));
        cycle(c, 1e6);
        assertTrue(q.attempted());
        assertFalse(q.callbackSucceeded());
        assertEq(r.registry().epoch(), 1);
        q.configure(0, address(0), "");
        r.registry().activatePolicy(n);
        assertEq(r.registry().epoch(), 2);
    }

    function testCELegacyRecipientAndBuybackBypassesRejected() public {
        (RetroPickBondingCurveV2 c,) = launchCE(address(0), creator);
        address tokenIdentity = c.token();
        vm.expectRevert(RetroPickLaunchFactoryV2.InvalidCommunity.selector);
        factory.setCreatorFeeRecipient(tokenIdentity, address(1));
        vm.prank(creator);
        vm.expectRevert(RetroPickLaunchFactoryV2.InvalidCommunity.selector);
        factory.transferCreatorFeeRecipient(tokenIdentity, address(1));
        vm.prank(creator);
        vm.expectRevert(RetroPickLaunchFactoryV2.InvalidCommunity.selector);
        factory.setBuybackEnabled(tokenIdentity, true);
    }

    function testCEControllerHandoffPreservesOldClaims() public {
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(address(0), creator);
        cycle(c, 1 ether);
        r.settle();
        uint256 debt = r.credit(creator);
        CommunityControllerV2 control = CommunityControllerV2(r.authority());
        address next = makeAddr("next");
        vm.prank(creator);
        control.schedule(next, false);
        vm.warp(block.timestamp + 3 days);
        vm.prank(next);
        control.accept(1);
        assertEq(control.controllerEpoch(), 1);
        assertEq(r.credit(creator), debt);
        assertEq(r.credit(next), 0);
        vm.prank(creator);
        r.claim(debt);
        assertEq(r.credit(creator), 0);
    }

    function testFuzzCERealSettlementConservation(uint96 input) public {
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(address(0), creator);
        uint256 amount = bound(uint256(input), 1e8, 1 ether);
        cycle(c, amount);
        (uint256 p, uint256 owed) = communityOwed(c);
        uint256 beforeReserve = c.realQuoteReserve();
        r.settle();
        assertEq(c.realQuoteReserve(), beforeReserve);
        assertEq(r.totalFunded(), owed);
        assertEq(escrow.balanceOf(protocol), p);
        assertEq(r.credit(creator) + r.credit(treasury), owed);
        assertEq(address(r).balance, r.totalLiability());
    }

    function testCEGraduationSecuresOnlyReservesAndClaimsSurvive() public {
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(address(0), creator);
        vm.deal(creator, 200 ether);
        vm.prank(creator);
        c.buy{value: 150 ether}(150 ether, 0, creator);
        assertTrue(c.graduated());
        assertGt(r.totalFunded(), 0);
        assertEq(c.communityPending(), 0);
        assertEq(address(coordinator).balance, factory.getLaunchedToken(c.token()).sweptQuote);
        uint256 debt = r.credit(creator);
        vm.prank(creator);
        r.claim(debt);
        assertEq(r.credit(creator), 0);
        uint256 funded = r.totalFunded();
        r.settle();
        assertEq(r.totalFunded(), funded);
        address tokenIdentity = c.token();
        vm.expectRevert();
        factory.createGraduatedPool(tokenIdentity);
        assertEq(r.totalLiability(), r.credit(treasury));
    }

    function testCEExpiredRecoveryCanBeClearedWithoutGuardian() public {
        (, CommunityFeeRouterV2 r) = launchCE(address(0), creator);
        CommunityControllerV2 control = CommunityControllerV2(r.authority());
        address next = makeAddr("recovery-next");
        vm.prank(guardian);
        control.schedule(next, true);
        vm.warp(block.timestamp + 14 days);
        vm.expectRevert(CommunityControllerV2.InvalidTransition.selector);
        control.expire(1);
        vm.warp(block.timestamp + 1);
        control.expire(1);
        assertEq(control.controller(), creator);
        assertEq(control.controllerEpoch(), 0);
        vm.prank(creator);
        control.schedule(next, false);
        vm.warp(block.timestamp + 3 days);
        vm.prank(next);
        control.accept(2);
        assertEq(control.controller(), next);
    }

    function testCERejectsInexactAndFalseReturnQuoteBeforeAccounting() public {
        CEAdversarialQuote q = installQuote();
        (RetroPickBondingCurveV2 c, CommunityFeeRouterV2 r) = launchCE(CIRCLE, creator);
        vm.prank(creator);
        q.approve(address(c), type(uint256).max);
        for (uint256 mode = 1; mode <= 4; ++mode) {
            q.configure(mode, address(0), "");
            vm.prank(creator);
            vm.expectRevert();
            c.buy(1e6, 0, creator);
            assertEq(c.trackedQuote(), 0);
            assertEq(c.communityPending(), 0);
            assertEq(r.totalLiability(), 0);
        }
    }

    function testCETwoLaunchAssetsCannotCoverEachOther() public {
        CEAdversarialQuote q = installQuote();
        (RetroPickBondingCurveV2 c1, CommunityFeeRouterV2 r1) = launchCE(CIRCLE, creator);
        (RetroPickBondingCurveV2 c2, CommunityFeeRouterV2 r2) = launchCE(CIRCLE, creator);
        cycle(c1, 1e6);
        cycle(c2, 1e6);
        r1.settle();
        r2.settle();
        q.slash(address(r2), 1);
        uint256 debt2 = r2.credit(creator);
        uint256 debt1 = r1.credit(creator);
        vm.prank(creator);
        vm.expectRevert(CommunityFeeRouterV2.BackingDeficit.selector);
        r2.claim(debt2);
        vm.prank(creator);
        r1.claim(debt1);
        assertEq(r2.credit(creator), debt2);
        assertEq(r1.credit(creator), 0);
        address token2 = c2.token();
        vm.prank(address(c1));
        vm.expectRevert(CommunityFeeRouterV2.Unauthorized.selector);
        r2.fund(token2, CIRCLE, 1, 2, 1);
    }
}

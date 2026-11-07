// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {
    CommunityRevenueRouterV2,
    CommunityPolicyRegistryV2
} from "../../../../src/v2-research-experiment/m6/CommunityRevenueRouterV2.sol";
import {CommunityControllerV2} from "../../../../src/v2-research-experiment/CommunityControllerV2.sol";
import {
    CommunityRevenueRouterFixtureV2,
    M6AccountingHook,
    M6AccountingCurve,
    M6AccountingToken
} from "./CommunityRevenueRouterV2.t.sol";

/// @notice Accounting/state-machine model only. Genuine venue actions are qualified in the separate lifecycle suite.
contract RevenueAccountingHandler is Test {
    CommunityRevenueRouterV2 public immutable router;
    M6AccountingHook public immutable hook;
    M6AccountingCurve public immutable curve;
    CommunityPolicyRegistryV2 public immutable registry;
    CommunityControllerV2 public immutable controller;
    address constant CREATOR = address(0xCAFE);
    address constant TREASURY = address(0xBEEF);
    uint256 public fundings;
    uint256 public claims;
    uint256 public settlements;
    uint256 public proposals;
    uint256 public activations;
    uint256 public cancellations;
    uint256 public rotations;
    uint256 public donations;
    uint256 public rejected;
    mapping(address => uint256) public expectedFunded;
    mapping(address => uint256) public expectedPaid;

    constructor(CommunityRevenueRouterV2 r, M6AccountingHook h, M6AccountingCurve c) {
        router = r;
        hook = h;
        curve = c;
        registry = r.registry();
        controller = CommunityControllerV2(r.authority());
    }
    receive() external payable {}

    function fund(uint128 raw, bool tokenAsset) public {
        address asset = tokenAsset ? router.launchToken() : router.feeAsset();
        uint256 fee = bound(uint256(raw), 1, 1e18);
        uint256 tax = fee / 2;
        hook.fund(router, asset, router.activeEpoch(), router.venueSequence(asset) + 1, fee, tax);
        expectedFunded[asset] += fee + tax - fee * router.protocolFeeShareBps() / 10000;
        ++fundings;
    }

    function settle(uint128 raw) public {
        uint256 amount = bound(uint256(raw), 1, 1e18);
        curve.accrue(amount);
        router.settle();
        expectedFunded[router.feeAsset()] += amount;
        ++settlements;
    }

    function claim(uint128 raw, bool tokenAsset, bool treasury) public {
        address asset = tokenAsset ? router.launchToken() : router.feeAsset();
        address beneficiary = treasury ? TREASURY : CREATOR;
        uint256 credit = router.creditOf(asset, beneficiary);
        if (credit == 0) return;
        uint256 amount = bound(uint256(raw), 1, credit);
        vm.prank(beneficiary);
        router.claimAsset(asset, amount);
        expectedPaid[asset] += amount;
        ++claims;
    }

    function propose(uint16 raw) public {
        (bytes32 hash,,,,,) = registry.pendingPolicy();
        if (hash != bytes32(0)) return;
        CommunityPolicyRegistryV2.Allocation[] memory allocations = new CommunityPolicyRegistryV2.Allocation[](2);
        uint16 creatorShare = uint16(bound(uint256(raw), 2000, 6000));
        allocations[0] = CommunityPolicyRegistryV2.Allocation(CREATOR, creatorShare, 0);
        allocations[1] = CommunityPolicyRegistryV2.Allocation(TREASURY, uint16(10000 - creatorShare), 2);
        vm.prank(controller.controller());
        registry.proposePolicy(allocations);
        ++proposals;
    }

    function cancel() public {
        (bytes32 hash, uint256 nonce,,,,) = registry.pendingPolicy();
        if (hash == bytes32(0)) return;
        vm.prank(controller.controller());
        registry.cancelPolicy(nonce);
        ++cancellations;
    }

    function activate() public {
        (bytes32 hash, uint256 nonce,, uint256 eta, address proposer, uint256 generation) = registry.pendingPolicy();
        if (hash == bytes32(0)) return;
        if (proposer != controller.controller() || generation != controller.controllerEpoch()) {
            vm.expectRevert(CommunityPolicyRegistryV2.WrongProposal.selector);
            registry.activatePolicy(nonce);
            ++rejected;
            return;
        }
        uint256 beforeCreator = router.credit(CREATOR);
        uint256 beforeTreasury = router.credit(TREASURY);
        uint256 oldTokenCreator = router.creditOf(router.launchToken(), CREATOR);
        if (block.timestamp < eta) vm.warp(eta);
        if (block.timestamp > eta + 7 days) {
            cancel();
            return;
        }
        registry.activatePolicy(nonce);
        assertEq(router.credit(CREATOR), beforeCreator);
        assertEq(router.credit(TREASURY), beforeTreasury);
        assertEq(router.creditOf(router.launchToken(), CREATOR), oldTokenCreator);
        ++activations;
    }

    function rotate() public {
        address replacement = address(uint160(0x100000 + rotations));
        uint256 oldQuoteCreator = router.credit(CREATOR);
        vm.prank(controller.controller());
        controller.schedule(replacement, false);
        uint256 nonce = controller.nonce();
        vm.warp(controller.effectiveAt());
        vm.prank(replacement);
        controller.accept(nonce);
        assertEq(router.credit(CREATOR), oldQuoteCreator);
        ++rotations;
    }

    function donate(uint128 raw, bool tokenAsset) public {
        uint256 amount = bound(uint256(raw), 1, 1e18);
        address asset = tokenAsset ? router.launchToken() : router.feeAsset();
        uint256 oldFunded = router.funded(asset);
        uint256 oldLiability = router.liability(asset);
        if (asset != address(0)) {
            M6AccountingToken(asset).mint(address(this), amount);
            assertTrue(M6AccountingToken(asset).transfer(address(router), amount));
        } else {
            vm.deal(address(this), amount);
            (bool ok,) = payable(address(router)).call{value: amount}("");
            assertTrue(ok);
        }
        assertEq(router.funded(asset), oldFunded);
        assertEq(router.liability(asset), oldLiability);
        ++donations;
    }

    function invalid() public {
        bytes32 id = router.venuePoolId();
        uint256 epoch = router.activeEpoch();
        address asset = router.feeAsset();
        vm.expectRevert(CommunityRevenueRouterV2.Unauthorized.selector);
        router.fundVenue(id, asset, epoch, 1, 100, 0);
        uint256 duplicate = router.venueSequence(asset);
        vm.expectRevert(CommunityRevenueRouterV2.InvalidSettlement.selector);
        hook.fund(router, asset, epoch, duplicate, 100, 0);
        rejected += 2;
    }
}

contract CommunityRevenueRouterInvariantTest is StdInvariant, CommunityRevenueRouterFixtureV2 {
    RevenueAccountingHandler internal handler;

    function setUp() public virtual override {
        _boot(false);
    }

    function _boot(bool usdc) internal {
        _setup(usdc);
        handler = new RevenueAccountingHandler(router, hook, curve);
        // Deterministic setup reachability only; these seeded counters do not prove random-action coverage.
        // No catch-all rejection suppression; inspect Foundry selector call/revert statistics separately.
        handler.fund(10000, false);
        handler.fund(20000, true);
        handler.settle(30000);
        handler.claim(10, false, false);
        handler.claim(10, true, true);
        handler.propose(4000);
        handler.activate();
        handler.propose(5000);
        handler.cancel();
        handler.rotate();
        handler.donate(77, false);
        handler.invalid();
        bytes4[] memory selectors = new bytes4[](10);
        selectors[0] = handler.fund.selector;
        selectors[1] = handler.settle.selector;
        selectors[2] = handler.claim.selector;
        selectors[3] = handler.propose.selector;
        selectors[4] = handler.activate.selector;
        selectors[5] = handler.cancel.selector;
        selectors[6] = handler.rotate.selector;
        selectors[7] = handler.donate.selector;
        selectors[8] = handler.invalid.selector;
        selectors[9] = handler.claim.selector;
        targetSelector(FuzzSelector(address(handler), selectors));
        targetContract(address(handler));
    }

    function testHandlerDonationUsesSupportedQuoteWithoutAttributingIncome() public {
        address asset = router.feeAsset();
        uint256 beforeBalance =
            asset == address(0) ? address(router).balance : M6AccountingToken(asset).balanceOf(address(router));
        uint256 beforeNative = address(router).balance;
        uint256 beforeFunded = router.funded(asset);
        uint256 beforeLiability = router.liability(asset);
        handler.donate(77, false);
        uint256 afterBalance =
            asset == address(0) ? address(router).balance : M6AccountingToken(asset).balanceOf(address(router));
        assertEq(afterBalance, beforeBalance + 77);
        assertEq(router.funded(asset), beforeFunded);
        assertEq(router.liability(asset), beforeLiability);
        if (asset != address(0)) assertEq(address(router).balance, beforeNative);
    }

    function testHandlerReplayTargetsPreviouslyFundedSupportedQuote() public {
        address asset = router.feeAsset();
        uint256 duplicate = router.venueSequence(asset);
        assertGt(duplicate, 0);
        uint256 beforeFunded = router.funded(asset);
        uint256 beforeLiability = router.liability(asset);
        vm.expectCall(
            address(hook),
            abi.encodeCall(M6AccountingHook.fund, (router, asset, router.activeEpoch(), duplicate, 100, 0))
        );
        handler.invalid();
        assertEq(router.venueSequence(asset), duplicate);
        assertEq(router.funded(asset), beforeFunded);
        assertEq(router.liability(asset), beforeLiability);
    }

    /// @dev Reachability counters include setup; randomized branch coverage is a separate qualification gate.
    function invariant_twoAssetConservationBackingRightsAndReachability() public view {
        address[2] memory assets = [router.feeAsset(), address(token)];
        for (uint256 i; i < 2; ++i) {
            address asset = assets[i];
            assertEq(router.funded(asset), handler.expectedFunded(asset));
            assertEq(router.paid(asset), handler.expectedPaid(asset));
            assertEq(router.funded(asset), router.paid(asset) + router.liability(asset));
            assertEq(router.liability(asset), router.creditOf(asset, CREATOR) + router.creditOf(asset, TREASURY));
            assertEq(router.venueGross(asset), router.venueProtocolRemitted(asset) + router.venueCommunityFunded(asset));
            assertGe(
                asset == address(0) ? address(router).balance : M6AccountingToken(asset).balanceOf(address(router)),
                router.liability(asset)
            );
        }
        assertGt(handler.fundings(), 0);
        assertGt(handler.claims(), 0);
        assertGt(handler.settlements(), 0);
        assertGt(handler.proposals(), 0);
        assertGt(handler.activations(), 0);
        assertGt(handler.cancellations(), 0);
        assertGt(handler.rotations(), 0);
        assertGt(handler.donations(), 0);
        assertGt(handler.rejected(), 0);
    }
}

/// @notice Same action model with admitted, modeled six-decimal quote plus the launch token.
contract CommunityRevenueRouterUSDCInvariantTest is CommunityRevenueRouterInvariantTest {
    function setUp() public override {
        _boot(true);
    }
}

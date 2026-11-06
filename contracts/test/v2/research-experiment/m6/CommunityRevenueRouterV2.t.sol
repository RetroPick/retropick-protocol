// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CommunityRevenueRouterV2} from "../../../../src/v2-research-experiment/m6/CommunityRevenueRouterV2.sol";
import {
    CommunityPolicyRegistryV2,
    ICommunityCheckpointV2
} from "../../../../src/v2-research-experiment/CommunityPolicyRegistryV2.sol";
import {CommunityControllerV2} from "../../../../src/v2-research-experiment/CommunityControllerV2.sol";
import {RetroPickFeeEscrowV2} from "../../../../src/v2-research-experiment/RetroPickFeeEscrowV2.sol";
import {
    ICommunityFeeSourceV2,
    ICommunityFeeFundingV2
} from "../../../../src/v2-research-experiment/interfaces/ICommunityFeesV2.sol";
import {
    GraduationPacket,
    GraduationLedger,
    GraduationReceipt,
    GraduationState,
    GraduationVenue
} from "../../../../src/v2-research-experiment/interfaces/IGraduationExecutorV2.sol";

/// @dev These identity/source doubles qualify Router accounting only, never genuine venue/trade integration.
contract M6AccountingToken is ERC20 {
    uint8 public mode;
    address public callback;
    bytes public callbackData;
    bool public callbackSucceeded;
    constructor() ERC20("M6 accounting fixture", "M6U") {}

    function decimals() public view override returns (uint8) {
        return address(this) == 0x534b2f3A21130d7a60830c2Df862319e593943A3 ? 6 : 18;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function destroy(address from, uint256 amount) external {
        _burn(from, amount);
    }

    function setMode(uint8 m) external {
        mode = m;
    }

    function setCallback(address target, bytes calldata data) external {
        callback = target;
        callbackData = data;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (mode == 1) return false;
        if (mode == 2) {
            super.transfer(to, amount);
            _burn(to, amount / 10 + 1);
            return true;
        }
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (mode == 1) return false;
        if (callback != address(0)) {
            address target = callback;
            callback = address(0);
            (callbackSucceeded,) = target.call(callbackData);
        }
        bool ok = super.transferFrom(from, to, amount);
        if (mode == 2) _burn(to, amount / 10 + 1);
        return ok;
    }
}

contract M6RouterIdentityManager {
    address public owner;
    uint128 public liquidity = 1000;

    function setOwner(address a) external {
        owner = a;
    }

    function setLiquidity(uint128 v) external {
        liquidity = v;
    }

    function ownerOf(uint256) external view returns (address) {
        return owner;
    }

    function getPositionLiquidity(uint256) external view returns (uint128) {
        return liquidity;
    }
}

contract M6RouterIdentityLocker {
    address public positionManager;
    address public factory;
    address public graduationExecutor;
    bool public locked = true;

    constructor(address pm) {
        positionManager = pm;
    }

    function configure(address f, address e) external {
        factory = f;
        graduationExecutor = e;
    }

    function lockedPositions(address) external pure returns (uint256) {
        return 1;
    }

    function isLocked(address) external view returns (bool) {
        return locked;
    }

    function setLocked(bool v) external {
        locked = v;
    }
}

contract M6RouterIdentityExecutor {
    address public coordinator;
    address public poolManager;
    address public positionManager;

    constructor(address c, address m, address p) {
        coordinator = c;
        poolManager = m;
        positionManager = p;
    }
}

contract M6RouterIdentityCoordinator {
    address public factory;
    GraduationPacket private p;
    GraduationLedger private l;
    GraduationReceipt private r;

    function configure(address f, GraduationPacket calldata packet_) external {
        factory = f;
        p = packet_;
    }

    function packet(address) external view returns (GraduationPacket memory) {
        return p;
    }

    function ledger(address) external view returns (GraduationLedger memory) {
        return l;
    }

    function receipt(address) external view returns (GraduationReceipt memory) {
        return r;
    }

    function graduate(bytes32 pool, address lock) external {
        r.packetHash = keccak256(abi.encode(p));
        r.destinationIdentity = pool;
        r.positionId = 1;
        r.protectedLPReceiver = lock;
        r.protectedLPAmount = 1000;
        l.phase = GraduationState.GRADUATED;
        l.destinationIdentity = pool;
        l.protectedLPReceiver = lock;
        l.protectedLPAmount = 1000;
        l.receiptHash = keccak256(abi.encode(r));
    }

    function setPhase(GraduationState phase) external {
        l.phase = phase;
    }
}

contract M6RouterIdentityFactory {
    address public communityBuilder;
    address public graduationCoordinator;
    address public locker;
    address public memeHook;
    address public curve;

    constructor(address registrar) {
        communityBuilder = registrar;
    }

    function configure(address c, address l, address h, address source_) external {
        graduationCoordinator = c;
        locker = l;
        memeHook = h;
        curve = source_;
    }

    function communitySource(address) external view returns (address) {
        return curve;
    }
}

contract M6AccountingCurve is ICommunityFeeSourceV2 {
    address public factory;
    address public token;
    address public pairToken;
    address public communityRouter;
    address public feeEscrow;
    address public protocolFeeRecipient = address(0xFEE);
    uint256 public protocolFeeShareBps = 2000;
    uint256 public creatorTaxBps = 100;
    uint256 public feeBps = 100;
    uint256 public communityPending;
    uint256 public seq;
    bool public failCheckpoint;

    constructor(address f, address t, address quote, address escrow) {
        factory = f;
        token = t;
        pairToken = quote;
        feeEscrow = escrow;
    }
    receive() external payable {}

    function bind(address router) external {
        communityRouter = router;
    }

    function accrue(uint256 amount) external {
        communityPending += amount;
    }

    function setFailure(bool v) external {
        failCheckpoint = v;
    }

    function checkpointCommunityFees() external {
        require(!failCheckpoint, "checkpoint-failure");
        uint256 n = communityPending;
        if (n == 0) return;
        communityPending = 0;
        _fund(n, ++seq);
    }

    function fundDirect(uint256 amount, uint256 next) external {
        _fund(amount, next);
    }

    function _fund(uint256 amount, uint256 next) private {
        if (pairToken != address(0)) IERC20(pairToken).approve(communityRouter, amount);
        ICommunityFeeFundingV2(communityRouter).fund{value: pairToken == address(0) ? amount : 0}(
            token, pairToken, ICommunityFeeFundingV2(communityRouter).activeEpoch(), next, amount
        );
    }
}

contract M6AccountingHook {
    address public factory;
    address public poolManager;
    address public graduationExecutor;
    address public feeEscrow;

    constructor(address f, address manager, address escrow) {
        factory = f;
        poolManager = manager;
        feeEscrow = escrow;
    }
    receive() external payable {}

    function revenueHookVersion() external pure returns (uint256) {
        return 2;
    }

    function setExecutor(address executor) external {
        graduationExecutor = executor;
    }

    function fund(CommunityRevenueRouterV2 router, address asset, uint256 epoch_, uint256 seq, uint256 f, uint256 t)
        external
    {
        fundPool(router, router.venuePoolId(), asset, epoch_, seq, f, t);
    }

    function fundPool(
        CommunityRevenueRouterV2 router,
        bytes32 pool,
        address asset,
        uint256 epoch_,
        uint256 seq,
        uint256 f,
        uint256 t
    ) public {
        uint256 amount = f + t;
        if (asset != address(0)) IERC20(asset).approve(address(router), amount);
        router.fundVenue{value: asset == address(0) ? amount : 0}(pool, asset, epoch_, seq, f, t);
    }
}

contract M6RejectingClaimant {
    function withdraw(CommunityRevenueRouterV2 router, uint256 amount) external {
        router.claim(amount);
    }

    receive() external payable {
        revert("reject");
    }
}

contract M6ReentrantClaimant {
    CommunityRevenueRouterV2 public router;
    bool public reentrySucceeded;

    function withdraw(CommunityRevenueRouterV2 r, uint256 amount) external {
        router = r;
        r.claim(amount);
    }

    receive() external payable {
        (reentrySucceeded,) = address(router).call(abi.encodeCall(router.claim, (1)));
    }
}

/// @notice MOCK-ONLY source/venue identity suite. No real swaps, position mint or fork is qualified here.
abstract contract CommunityRevenueRouterFixtureV2 is Test {
    address constant USDC = 0x534b2f3A21130d7a60830c2Df862319e593943A3;
    address constant CREATOR = address(0xCAFE);
    address constant TREASURY = address(0xBEEF);
    address constant PROTOCOL = address(0xFEE);
    CommunityRevenueRouterV2 router;
    CommunityPolicyRegistryV2 registry;
    CommunityControllerV2 control;
    M6AccountingToken token;
    M6AccountingToken quote;
    M6AccountingCurve curve;
    M6AccountingHook hook;
    M6RouterIdentityCoordinator coord;
    M6RouterIdentityLocker lock;
    M6RouterIdentityManager manager;
    M6RouterIdentityFactory factory;
    RetroPickFeeEscrowV2 escrow;

    function setUp() public virtual {
        _setup(false);
    }

    function _setup(bool usdc) internal {
        vm.chainId(10143);
        token = new M6AccountingToken();
        if (usdc) {
            M6AccountingToken implementation = new M6AccountingToken();
            vm.etch(USDC, address(implementation).code);
            quote = M6AccountingToken(USDC);
        }
        escrow = new RetroPickFeeEscrowV2();
        factory = new M6RouterIdentityFactory(address(this));
        manager = new M6RouterIdentityManager();
        coord = new M6RouterIdentityCoordinator();
        lock = new M6RouterIdentityLocker(address(manager));
        curve = new M6AccountingCurve(address(factory), address(token), usdc ? USDC : address(0), address(escrow));
        hook = new M6AccountingHook(address(factory), address(manager), address(escrow));
        M6RouterIdentityExecutor executor =
            new M6RouterIdentityExecutor(address(coord), address(manager), address(manager));
        lock.configure(address(factory), address(executor));
        manager.setOwner(address(lock));
        hook.setExecutor(address(executor));
        factory.configure(address(coord), address(lock), address(hook), address(curve));
        GraduationPacket memory p;
        p.token = address(token);
        p.curve = address(curve);
        p.quoteAsset = usdc ? USDC : address(0);
        p.quoteDecimals = usdc ? 6 : 18;
        p.venue = GraduationVenue.UNISWAP_V4;
        p.executor = address(executor);
        p.executorCodeHash = address(executor).codehash;
        p.protectedLPReceiver = address(lock);
        p.protectedExcessReceiver = address(lock);
        p.tickSpacing = 60;
        p.feePolicy.protocolFeeRecipient = PROTOCOL;
        p.feePolicy.protocolFeeShareBps = 2000;
        p.feePolicy.hookFeeBps = 200;
        coord.configure(address(factory), p);
        control = new CommunityControllerV2(address(this), address(0xA11));
        router = new CommunityRevenueRouterV2(
            address(factory), curve, address(token), address(control), address(this), address(hook)
        );
        registry = _registry(_alloc(CREATOR, 6000, TREASURY), 300);
        router.bindRegistry(registry);
        curve.bind(address(router));
        coord.graduate(router.venuePoolId(), address(lock));
        vm.deal(address(hook), 1e30);
        vm.deal(address(curve), 1e30);
        token.mint(address(hook), 1e30);
        if (usdc) {
            quote.mint(address(hook), 1e30);
            quote.mint(address(curve), 1e30);
        }
    }

    function _alloc(address creator, uint16 bps, address treasury)
        internal
        pure
        returns (CommunityPolicyRegistryV2.Allocation[] memory a)
    {
        a = new CommunityPolicyRegistryV2.Allocation[](2);
        a[0] = CommunityPolicyRegistryV2.Allocation(creator, bps, 0);
        a[1] = CommunityPolicyRegistryV2.Allocation(treasury, uint16(10000 - bps), 2);
    }

    function _registry(CommunityPolicyRegistryV2.Allocation[] memory a, uint16 fee)
        internal
        returns (CommunityPolicyRegistryV2)
    {
        address[5] memory modules;
        modules[0] = a[1].beneficiary;
        return new CommunityPolicyRegistryV2(
            address(token),
            control,
            ICommunityCheckpointV2(address(router)),
            CommunityPolicyRegistryV2.Bounds(6000, 4000, 500, 3 days),
            fee,
            modules,
            a
        );
    }
}

/// @notice Original unit tests use a pristine fixture; action-model suites inherit only the fixture above.
contract CommunityRevenueRouterV2AccountingTest is CommunityRevenueRouterFixtureV2 {
    function _fund(address asset, uint256 f, uint256 t) private {
        hook.fund(router, asset, router.activeEpoch(), router.venueSequence(asset) + 1, f, t);
    }

    // Cache all external views before arming Foundry's next-call revert expectation.
    function _fundReverts(address asset, uint256 f, uint256 t, bytes4 reason) private {
        uint256 epoch = router.activeEpoch();
        uint256 seq = router.venueSequence(asset) + 1;
        if (reason == bytes4(0)) vm.expectRevert();
        else vm.expectRevert(reason);
        hook.fund(router, asset, epoch, seq, f, t);
    }

    function _conservation(address asset) private view {
        assertEq(router.funded(asset), router.paid(asset) + router.liability(asset));
        assertEq(router.venueGross(asset), router.venueProtocolRemitted(asset) + router.venueCommunityFunded(asset));
        assertGe(
            asset == address(0) ? address(router).balance : IERC20(asset).balanceOf(address(router)),
            router.liability(asset)
        );
    }

    function testMockNativeVenueProtocolOnceAndCurvePreSeparated() public {
        _fund(address(0), 101, 7);
        assertEq(escrow.balanceOf(PROTOCOL), 20);
        assertEq(router.credit(CREATOR), 52);
        assertEq(router.credit(TREASURY), 36);
        curve.accrue(100);
        router.settle();
        assertEq(escrow.balanceOf(PROTOCOL), 20);
        assertEq(router.credit(CREATOR), 112);
        assertEq(router.credit(TREASURY), 76);
        vm.prank(CREATOR);
        router.claim(12);
        vm.prank(TREASURY);
        router.claim(76);
        assertEq(router.totalLiability(), 100);
        assertEq(router.totalPaid(), 88);
        _conservation(address(0));
    }

    function testMockUSDCAndLaunchedTokenLedgersAreIndependent() public {
        _setup(true);
        _fund(USDC, 1000, 100);
        _fund(address(token), 2000, 300);
        assertEq(router.credit(CREATOR), 540);
        assertEq(router.creditOf(address(token), CREATOR), 1140);
        assertEq(escrow.balanceOfToken(PROTOCOL, USDC), 200);
        assertEq(escrow.balanceOfToken(PROTOCOL, address(token)), 400);
        vm.prank(CREATOR);
        router.claimAsset(address(token), 1140);
        assertEq(token.balanceOf(CREATOR), 1140);
        assertEq(router.credit(CREATOR), 540);
        assertEq(token.allowance(address(router), address(escrow)), 0);
        assertEq(quote.allowance(address(router), address(escrow)), 0);
        _conservation(USDC);
        _conservation(address(token));
    }

    function testMockAuthenticCallerReplayPoolEpochAndAssetGuards() public {
        bytes32 pool = router.venuePoolId();
        vm.expectRevert(CommunityRevenueRouterV2.Unauthorized.selector);
        router.fundVenue(pool, address(0), 1, 1, 100, 0);
        vm.expectRevert(CommunityRevenueRouterV2.Unauthorized.selector);
        router.fund(address(token), address(0), 1, 1, 100);
        _fund(address(0), 100, 0);
        vm.expectRevert(CommunityRevenueRouterV2.InvalidSettlement.selector);
        hook.fund(router, address(0), 1, 1, 100, 0);
        vm.expectRevert(CommunityRevenueRouterV2.InvalidSettlement.selector);
        hook.fund(router, address(0), 2, 2, 100, 0);
        vm.expectRevert(CommunityRevenueRouterV2.InvalidSettlement.selector);
        hook.fundPool(router, bytes32(uint256(123)), address(0), 1, 2, 100, 0);
        vm.prank(address(hook));
        vm.expectRevert(CommunityRevenueRouterV2.InvalidSettlement.selector);
        router.fundVenue(pool, address(0xBAD), 1, 1, 100, 0);
        _conservation(address(0));
        assertEq(router.venueSequence(address(0)), 1);
    }

    function testMockUnfinalizedOrUnlockedOrChangedPrincipalRejectsRevenue() public {
        coord.setPhase(GraduationState.GRADUATING);
        _fundReverts(address(0), 100, 0, CommunityRevenueRouterV2.InvalidSettlement.selector);
        coord.graduate(router.venuePoolId(), address(lock));
        lock.setLocked(false);
        _fundReverts(address(0), 100, 0, CommunityRevenueRouterV2.InvalidSettlement.selector);
        lock.setLocked(true);
        manager.setOwner(CREATOR);
        _fundReverts(address(0), 100, 0, CommunityRevenueRouterV2.InvalidSettlement.selector);
        manager.setOwner(address(lock));
        manager.setLiquidity(999);
        _fundReverts(address(0), 100, 0, CommunityRevenueRouterV2.InvalidSettlement.selector);
        assertEq(router.venueSequence(address(0)), 0);
    }

    function testMockDonationsDoNotBookIncomeAndCannotCoverOldDeficit() public {
        vm.deal(address(router), 77);
        token.mint(address(router), 33);
        assertEq(router.funded(address(0)), 0);
        assertEq(router.funded(address(token)), 0);
        _fund(address(token), 1000, 100);
        token.destroy(address(router), 34);
        _fundReverts(address(token), 10, 1, CommunityRevenueRouterV2.BackingDeficit.selector);
        vm.prank(CREATOR);
        vm.expectRevert(CommunityRevenueRouterV2.BackingDeficit.selector);
        router.claimAsset(address(token), 1);
        _fund(address(0), 100, 0); // Unrelated solvent asset remains independently claimable.
        vm.prank(CREATOR);
        router.claim(48);
        _conservation(address(0));
    }

    function testMockFalseReturnAndDeflationaryFundingRollback() public {
        token.setMode(1);
        _fundReverts(address(token), 100, 0, bytes4(0));
        token.setMode(2);
        _fundReverts(address(token), 100, 0, bytes4(0));
        assertEq(router.venueSequence(address(token)), 0);
        assertEq(router.funded(address(token)), 0);
        token.setMode(0);
        _fund(address(token), 100, 0);
        token.setMode(2);
        vm.prank(CREATOR);
        vm.expectRevert();
        router.claimAsset(address(token), 48);
        assertEq(router.creditOf(address(token), CREATOR), 48);
        token.setMode(0);
        _conservation(address(token));
    }

    function testMockPolicyActivationCheckpointsOldCurveFeesAndKeepsOldRights() public {
        _fund(address(0), 100, 0);
        curve.accrue(100);
        uint256 nonce = registry.proposePolicy(_alloc(CREATOR, 3000, TREASURY));
        vm.expectRevert(CommunityPolicyRegistryV2.OutsideWindow.selector);
        registry.activatePolicy(nonce);
        vm.warp(block.timestamp + 3 days);
        registry.activatePolicy(nonce);
        assertEq(router.activeEpoch(), 2);
        assertEq(router.credit(CREATOR), 108);
        _fund(address(0), 100, 0);
        assertEq(router.credit(CREATOR), 132);
        assertEq(router.credit(TREASURY), 128);
        assertEq(router.epochFundedAsset(address(0), 1), 180);
        assertEq(router.epochFundedAsset(address(0), 2), 80);
        _conservation(address(0));
    }

    function testMockFailedCheckpointKeepsPolicyAndPendingFees() public {
        curve.accrue(100);
        uint256 nonce = registry.proposePolicy(_alloc(CREATOR, 3000, TREASURY));
        vm.warp(block.timestamp + 3 days);
        curve.setFailure(true);
        vm.expectRevert(bytes("checkpoint-failure"));
        registry.activatePolicy(nonce);
        assertEq(registry.epoch(), 1);
        assertEq(curve.communityPending(), 100);
        curve.setFailure(false);
        registry.activatePolicy(nonce);
        assertEq(router.credit(CREATOR), 60);
        assertEq(registry.epoch(), 2);
    }

    function testMockTokenCallbackCannotActivatePolicyDuringVenueFunding() public {
        uint256 nonce = registry.proposePolicy(_alloc(CREATOR, 3000, TREASURY));
        vm.warp(block.timestamp + 3 days);
        token.setCallback(address(registry), abi.encodeCall(registry.activatePolicy, (nonce)));
        _fund(address(token), 100, 0);
        assertFalse(token.callbackSucceeded());
        assertEq(registry.epoch(), 1);
        assertEq(router.creditOf(address(token), CREATOR), 48);
        registry.activatePolicy(nonce);
        assertEq(registry.epoch(), 2);
        assertEq(router.creditOf(address(token), CREATOR), 48);
    }

    function testMockFeeCapBindingAndRegistrarCannotBeSpoofed() public {
        CommunityRevenueRouterV2 other = new CommunityRevenueRouterV2(
            address(factory), curve, address(token), address(control), address(this), address(hook)
        );
        address[5] memory modules;
        modules[0] = TREASURY;
        CommunityPolicyRegistryV2 bad = new CommunityPolicyRegistryV2(
            address(token),
            control,
            ICommunityCheckpointV2(address(other)),
            CommunityPolicyRegistryV2.Bounds(6000, 4000, 500, 3 days),
            200,
            modules,
            _alloc(CREATOR, 6000, TREASURY)
        );
        vm.expectRevert(CommunityRevenueRouterV2.InvalidBinding.selector);
        other.bindRegistry(bad);
        vm.expectRevert(CommunityRevenueRouterV2.InvalidBinding.selector);
        new CommunityRevenueRouterV2(
            address(factory), curve, address(token), address(control), address(hook), address(hook)
        );
        vm.prank(CREATOR);
        vm.expectRevert(CommunityRevenueRouterV2.InvalidBinding.selector);
        other.bindRegistry(registry);
    }

    function testMockMaliciousRecipientCannotBlockIndependentClaims() public {
        M6RejectingClaimant rejector = new M6RejectingClaimant();
        uint256 nonce = registry.proposePolicy(_alloc(address(rejector), 6000, TREASURY));
        vm.warp(block.timestamp + 3 days);
        registry.activatePolicy(nonce);
        _fund(address(0), 100, 0);
        vm.expectRevert(CommunityRevenueRouterV2.TransferFailed.selector);
        rejector.withdraw(router, 48);
        assertEq(router.credit(address(rejector)), 48);
        vm.prank(TREASURY);
        router.claim(32);
        assertEq(router.credit(TREASURY), 0);
        _conservation(address(0));
    }

    function testMockReentrantClaimCannotDoublePayOrReplay() public {
        M6ReentrantClaimant receiver = new M6ReentrantClaimant();
        uint256 nonce = registry.proposePolicy(_alloc(address(receiver), 6000, TREASURY));
        vm.warp(block.timestamp + 3 days);
        registry.activatePolicy(nonce);
        _fund(address(0), 100, 0);
        receiver.withdraw(router, 48);
        assertFalse(receiver.reentrySucceeded());
        assertEq(router.credit(address(receiver)), 0);
        vm.expectRevert(CommunityRevenueRouterV2.InvalidSettlement.selector);
        receiver.withdraw(router, 1);
        _conservation(address(0));
    }

    function testFuzzMockIntegerConservationAndTreasuryDust(uint128 rawFee, uint128 rawTax) public {
        uint256 f = bound(uint256(rawFee), 0, 1e25);
        uint256 t = bound(uint256(rawTax), 0, 1e25);
        vm.assume(f + t > 0);
        _fund(address(0), f, t);
        uint256 c = f + t - (f * 2000 / 10000);
        assertEq(router.credit(CREATOR), c * 6000 / 10000);
        assertEq(router.credit(TREASURY), c - c * 6000 / 10000);
        assertEq(router.liability(address(0)), c);
        _conservation(address(0));
    }
}

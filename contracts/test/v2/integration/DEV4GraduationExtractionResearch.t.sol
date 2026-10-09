// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {RetroPickBondingCurveV2} from "../../../src/v2/RetroPickBondingCurveV2.sol";
import {RetroPickLauncherTokenV2} from "../../../src/v2/RetroPickLauncherTokenV2.sol";
import {RetroPickBuybackVaultV2} from "../../../src/v2/RetroPickBuybackVaultV2.sol";
import {RetroPickFeeEscrowV2} from "../../../src/v2/RetroPickFeeEscrowV2.sol";
import {
    FeePolicySnapshot,
    IRetroPickFeeEscrowV2,
    IRetroPickFeePolicyV2
} from "../../../src/v2/interfaces/IRetroPickLaunchpadV2.sol";

/// @title DEV-4 Factory-to-Coordinator extraction research fixture.
/// @notice Research-only architecture proof. No contract here is production
/// authority and none of these types may be moved into contracts/src/v2.
contract DEV4ResearchFeePolicy is IRetroPickFeePolicyV2 {
    FeePolicySnapshot private _snapshot = FeePolicySnapshot({
        protocolFeeRecipient: address(0xBEEF),
        protocolFeeShareBps: 3_000,
        buybackBurnBps: 0,
        hookFeeBps: 0,
        maxInternalPriceImpactBps: 100
    });

    function protocolFeeShareBps() external view returns (uint256) {
        return _snapshot.protocolFeeShareBps;
    }

    function buybackBurnBps() external view returns (uint256) {
        return _snapshot.buybackBurnBps;
    }

    function protocolFeeRecipient() external view returns (address) {
        return _snapshot.protocolFeeRecipient;
    }

    function feeEscrow() external view returns (IRetroPickFeeEscrowV2) {
        revert("unused");
    }

    function maxInternalPriceImpactBps() external view returns (uint256) {
        return _snapshot.maxInternalPriceImpactBps;
    }

    function feeSweepOperator() external view returns (address) {
        return address(this);
    }

    function currentFeePolicy() external view returns (FeePolicySnapshot memory) {
        return _snapshot;
    }
}

contract DEV4ResearchQuote is IERC20 {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function totalSupply() external pure override returns (uint256) {
        return type(uint256).max;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        return _move(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "allowance");
        allowance[from][msg.sender] = allowed - amount;
        return _move(from, to, amount);
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function _move(address from, address to, uint256 amount) private returns (bool) {
        require(balanceOf[from] >= amount, "balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

interface IDEV4ThinFactory {
    function secureCurve(address token, address quoteAsset) external returns (uint256 quoteOut, uint256 tokenOut);
}

struct DEV4VenueResult {
    address destination;
    uint256 quoteConsumed;
    uint256 baseSeed;
    uint256 excessTokens;
    uint256 lpShares;
}

interface IDEV4VenueExecutor {
    function execute(
        address coordinator,
        address token,
        address quoteAsset,
        uint256 quoteAmount,
        uint256 tokenAmount,
        address custody
    ) external payable returns (DEV4VenueResult memory result);
}

/// @notice Permanent P0-style protected custody. It has no exit, transfer,
/// approval, withdrawal, callback, or arbitrary-call surface.
contract DEV4ProtectedCustody {
    address public immutable recorder;
    mapping(address destination => uint256 shares) public lpShares;

    constructor(address recorder_) {
        recorder = recorder_;
    }

    function recordLP(address destination, uint256 shares) external {
        require(msg.sender == recorder, "wrong recorder");
        lpShares[destination] += shares;
    }
}

/// @notice One immutable venue executor with deterministic fault injection.
/// The coordinator cannot replace the packet after securing the launch.
contract DEV4ResearchVenueExecutor is IDEV4VenueExecutor {
    using SafeERC20 for IERC20;

    error InjectedFailure();

    uint256 public immutable baseSeed;
    uint256 public immutable lpShares;
    bool public failNext;

    constructor(uint256 baseSeed_, uint256 lpShares_) {
        baseSeed = baseSeed_;
        lpShares = lpShares_;
    }

    function setFailNext(bool value) external {
        failNext = value;
    }

    function execute(
        address coordinator,
        address token,
        address quoteAsset,
        uint256 quoteAmount,
        uint256 tokenAmount,
        address custody
    ) external payable returns (DEV4VenueResult memory) {
        if (failNext) revert InjectedFailure();
        require(tokenAmount >= baseSeed, "seed exceeds packet");
        uint256 excess = tokenAmount - baseSeed;

        if (quoteAsset == address(0)) {
            require(msg.value == quoteAmount, "native packet mismatch");
            (bool consumed,) = payable(address(0xA11CE)).call{value: quoteAmount}("");
            require(consumed, "native venue failure");
        } else {
            require(msg.value == 0, "unexpected native value");
            DEV4ResearchQuote(quoteAsset).transferFrom(coordinator, address(0xA11CE), quoteAmount);
        }

        // Pull the complete base packet and route only the non-seed excess to
        // protected custody. The venue is stateless, so no packet remains here.
        IERC20(token).safeTransferFrom(coordinator, address(this), baseSeed);
        IERC20(token).safeTransferFrom(coordinator, custody, excess);
        DEV4ProtectedCustody(custody).recordLP(address(0xA11CE), lpShares);
        return DEV4VenueResult({
            destination: address(0xA11CE),
            quoteConsumed: quoteAmount,
            baseSeed: baseSeed,
            excessTokens: excess,
            lpShares: lpShares
        });
    }
}

contract DEV4GraduationCoordinator {
    using SafeERC20 for IERC20;

    error NotInitialized();
    error AlreadyInitialized();
    error WrongPhase();
    error ZeroAddress();
    error ZeroSecuredAsset();
    error QuoteAssetMismatch();
    error WrongVenueResult();
    error WrongCustody();
    error ExecutorDrift();

    enum Phase {
        Active,
        Graduating,
        Graduated
    }

    struct SecuredLaunch {
        address token;
        address quoteAsset;
        uint256 quoteAmount;
        uint256 tokenAmount;
        uint256 consumedQuote;
        uint256 consumedTokens;
        address destination;
    }

    DEV4ThinFactory public factory;
    IDEV4VenueExecutor public venueExecutor;
    DEV4ProtectedCustody public custody;
    mapping(address token => Phase) public phase;
    mapping(address token => SecuredLaunch) private _secured;

    function secured(address token) external view returns (SecuredLaunch memory) {
        return _secured[token];
    }

    function initialize(DEV4ThinFactory factory_, IDEV4VenueExecutor executor_, DEV4ProtectedCustody custody_)
        external
    {
        if (
            factory != DEV4ThinFactory(address(0)) || address(venueExecutor) != address(0)
                || address(custody) != address(0)
        ) {
            revert AlreadyInitialized();
        }
        if (
            factory_ == DEV4ThinFactory(address(0)) || executor_ == IDEV4VenueExecutor(address(0))
                || custody_ == DEV4ProtectedCustody(address(0))
        ) {
            revert ZeroAddress();
        }
        factory = factory_;
        venueExecutor = executor_;
        custody = custody_;
    }

    receive() external payable {}

    /// @notice Permissionless phase 1 through the thin Factory's narrow callback.
    function secure(address token, address quoteAsset) external {
        if (phase[token] != Phase.Active) revert WrongPhase();
        if (address(factory) == address(0)) revert NotInitialized();
        if (_secured[token].token != address(0) && quoteAsset != _secured[token].quoteAsset) {
            revert QuoteAssetMismatch();
        }
        (uint256 quoteOut, uint256 tokenOut) = factory.secureCurve(token, quoteAsset);
        _commitSecured(token, quoteAsset, quoteOut, tokenOut);
    }

    /// @notice Permissionless atomic phase 2 and retry. Replay is rejected
    /// before any executor call or useful asset movement.
    function complete(address token) external returns (address destination) {
        if (phase[token] != Phase.Graduating) revert WrongPhase();

        SecuredLaunch memory packet = _secured[token];
        uint256 quoteBefore = _quoteBalance(packet.quoteAsset);
        uint256 tokenBefore = IERC20(token).balanceOf(address(this));

        DEV4VenueResult memory result = IDEV4VenueExecutor(venueExecutor)
        .execute{value: packet.quoteAsset == address(0) ? packet.quoteAmount : 0}(
            address(this), token, packet.quoteAsset, packet.quoteAmount, packet.tokenAmount, address(custody)
        );
        if (packet.quoteAsset != address(0)) {
            IERC20(packet.quoteAsset).forceApprove(address(venueExecutor), 0);
        }
        IERC20(token).forceApprove(address(venueExecutor), 0);
        _verifyResult(token, packet, result, quoteBefore, tokenBefore);

        _secured[token].consumedQuote = result.quoteConsumed;
        _secured[token].consumedTokens = result.baseSeed + result.excessTokens;
        _secured[token].destination = result.destination;
        destination = result.destination;
        phase[token] = Phase.Graduated;
    }

    function _commitSecured(address token, address quoteAsset, uint256 quoteOut, uint256 tokenOut) private {
        if (quoteOut == 0 || tokenOut == 0) revert ZeroSecuredAsset();

        uint256 quoteBefore = _quoteBalance(quoteAsset) - quoteOut;
        uint256 tokenBefore = IERC20(token).balanceOf(address(this)) - tokenOut;
        uint256 quoteAfter = _quoteBalance(quoteAsset);
        uint256 tokenAfter = IERC20(token).balanceOf(address(this));
        if (quoteAfter - quoteBefore != quoteOut || quoteBefore > quoteAfter) {
            revert ExecutorDrift();
        }
        if (tokenAfter - tokenBefore != tokenOut || tokenBefore > tokenAfter) {
            revert ExecutorDrift();
        }

        // The stateless venue worker is the sole pull spender, and only for
        // the exact immutable packet committed here. A failed approval reverts
        // the whole phase-1 handoff; no transaction-scoped pull can persist.
        if (quoteAsset != address(0)) {
            IERC20(quoteAsset).forceApprove(address(venueExecutor), quoteOut);
        }
        IERC20(token).forceApprove(address(venueExecutor), tokenOut);

        _secured[token] = SecuredLaunch({
            token: token,
            quoteAsset: quoteAsset,
            quoteAmount: quoteOut,
            tokenAmount: tokenOut,
            consumedQuote: 0,
            consumedTokens: 0,
            destination: address(0)
        });
        phase[token] = Phase.Graduating;
    }

    function _verifyResult(
        address token,
        SecuredLaunch memory packet,
        DEV4VenueResult memory result,
        uint256 quoteBefore,
        uint256 tokenBefore
    ) private view {
        if (
            result.destination == address(0) || result.quoteConsumed != packet.quoteAmount || result.baseSeed == 0
                || result.excessTokens == 0 || result.baseSeed + result.excessTokens != packet.tokenAmount
                || result.lpShares == 0
        ) {
            revert WrongVenueResult();
        }

        uint256 quoteAfter = _quoteBalance(packet.quoteAsset);
        uint256 tokenAfter = IERC20(token).balanceOf(address(this));
        if (quoteBefore - quoteAfter != packet.quoteAmount || quoteAfter > quoteBefore) {
            revert ExecutorDrift();
        }
        if (tokenBefore - tokenAfter != packet.tokenAmount || tokenAfter > tokenBefore) {
            revert ExecutorDrift();
        }
        if (IERC20(token).balanceOf(address(custody)) < result.excessTokens) {
            revert WrongCustody();
        }
        if (DEV4ProtectedCustody(custody).lpShares(result.destination) < result.lpShares) {
            revert WrongCustody();
        }
    }

    function _quoteBalance(address quoteAsset) private view returns (uint256) {
        return quoteAsset == address(0) ? address(this).balance : IERC20(quoteAsset).balanceOf(address(this));
    }
}

/// @notice Thin Factory research seam. It owns launch identity and the immutable
/// one-hop authority marker, but deliberately owns no phase or secured balances.
contract DEV4ThinFactory is IDEV4ThinFactory {
    error NotCoordinator();
    error TokenNotFound();
    error AlreadyHandedOff();
    error CurveAlreadyGraduated();
    error NotReady();
    error WrongCurve();
    error QuoteMismatch();

    struct Launch {
        address token;
        address pairToken;
        RetroPickBondingCurveV2 curve;
        bool exists;
        bool authorityHandedOff;
    }

    DEV4GraduationCoordinator public immutable coordinator;
    mapping(address token => Launch) private _launches;
    mapping(address curve => address) private _curveTokens;

    constructor(DEV4GraduationCoordinator coordinator_) {
        coordinator = coordinator_;
    }

    /// @notice Production-equivalent trust seam called by the unchanged Curve.
    function graduate(address token) external {
        Launch storage record = _launches[token];
        if (!record.exists) revert TokenNotFound();
        if (record.authorityHandedOff) revert AlreadyHandedOff();
        coordinator.secure(token, record.pairToken);
    }

    /// @notice The only privileged Curve operation retained by this Factory.
    function secureCurve(address token, address quoteAsset) external returns (uint256 quoteOut, uint256 tokenOut) {
        if (msg.sender != address(coordinator)) revert NotCoordinator();
        Launch storage record = _launches[token];
        if (!record.exists) revert TokenNotFound();
        if (record.authorityHandedOff) revert AlreadyHandedOff();
        if (quoteAsset != record.pairToken) revert QuoteMismatch();
        RetroPickBondingCurveV2 curve = record.curve;
        if (curve.graduated()) revert CurveAlreadyGraduated();
        if (!curve.readyToGraduate()) revert NotReady();
        if (_curveTokens[address(curve)] != token) revert WrongCurve();

        // Commit authority handoff before the Curve's guarded external sweep.
        // A reverted sweep rolls this marker back with the whole transaction.
        record.authorityHandedOff = true;
        (quoteOut, tokenOut) = curve.graduate(address(coordinator));
    }

    function launch(
        address pairToken,
        address creator,
        uint256 supply,
        uint256 phantomQuote,
        uint256 graduationThreshold,
        DEV4ResearchFeePolicy policy,
        RetroPickFeeEscrowV2 feeEscrow,
        RetroPickBuybackVaultV2 buybackVault
    ) external returns (address token, address curve) {
        RetroPickLauncherTokenV2.Socials memory empty;
        curve = address(
            new RetroPickBondingCurveV2(
                pairToken,
                creator,
                address(this),
                IRetroPickFeePolicyV2(address(policy)),
                policy.currentFeePolicy(),
                IRetroPickFeeEscrowV2(address(feeEscrow)),
                buybackVault,
                phantomQuote,
                100,
                50,
                false,
                graduationThreshold
            ,
            (graduationThreshold) * 50
        )
        );
        token = address(
            new RetroPickLauncherTokenV2(
                "DEV4 Extraction", "DEV4", "", "", empty, creator, curve, address(this), supply
            )
        );
        RetroPickBondingCurveV2(payable(curve)).initialize(token);
        _launches[token] = Launch({
            token: token,
            pairToken: pairToken,
            curve: RetroPickBondingCurveV2(payable(curve)),
            exists: true,
            authorityHandedOff: false
        });
        _curveTokens[curve] = token;
    }

    function getLaunch(address token) external view returns (Launch memory) {
        return _launches[token];
    }

    function authorityHandedOff(address token) external view returns (bool) {
        return _launches[token].authorityHandedOff;
    }
}

contract DEV4MaliciousCallback {
    function callSecureCurve(IDEV4ThinFactory factory, address token, address quoteAsset) external {
        factory.secureCurve(token, quoteAsset);
    }

    function callCoordinatorSecure(DEV4GraduationCoordinator coordinator, address token, address quoteAsset) external {
        coordinator.secure(token, quoteAsset);
    }
}

contract DEV4GraduationExtractionResearchTest is Test {
    DEV4ResearchFeePolicy internal feePolicy;
    RetroPickFeeEscrowV2 internal escrow;
    RetroPickBuybackVaultV2 internal buybackVault;
    DEV4ProtectedCustody internal custody;
    DEV4ResearchVenueExecutor internal executor;
    DEV4GraduationCoordinator internal coordinator;
    DEV4ThinFactory internal factory;
    DEV4MaliciousCallback internal attacker;
    DEV4ResearchQuote internal quote;

    address internal creator = makeAddr("creator");
    address internal arbitraryCaller = makeAddr("arbitraryCaller");

    function setUp() public {
        vm.chainId(10143);
        feePolicy = new DEV4ResearchFeePolicy();
        escrow = new RetroPickFeeEscrowV2();
        buybackVault = new RetroPickBuybackVaultV2(
            address(this), IRetroPickFeePolicyV2(address(feePolicy)), IRetroPickFeeEscrowV2(address(escrow))
        );
        custody = new DEV4ProtectedCustody(address(this));
        coordinator = new DEV4GraduationCoordinator();
        factory = new DEV4ThinFactory(coordinator);
        buybackVault.setFactory(address(factory));
        attacker = new DEV4MaliciousCallback();
        quote = new DEV4ResearchQuote();
    }

    function _wireExecutor(uint256 terminalTokens) internal {
        executor = new DEV4ResearchVenueExecutor(terminalTokens / 2, 123);
        custody = new DEV4ProtectedCustody(address(executor));
        coordinator.initialize(factory, executor, custody);
        executor.setFailNext(true);
    }

    function _nativeLaunch()
        internal
        returns (address token, address curveAddress, uint256 terminalQuote, uint256 terminalTokens)
    {
        (token, curveAddress) = factory.launch(
            address(0), creator, 1_000_000 ether, 100 ether, 100 ether, feePolicy, escrow, buybackVault
        );
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        // With no prior trades, the eventual graduation packet is exactly the
        // Curve's initialized token balance. Wire immutable phase-2 authority
        // before the threshold-crossing buy so the unchanged Curve's automatic
        // factory callback can enter phase 1 atomically.
        // The threshold-crossing buy leaves half of the initial token reserve;
        // the other half is distributed to the buyer before phase 1.
        _wireExecutor(curve.trackedTokens() / 2);
        vm.deal(creator, 1_000 ether);
        vm.prank(creator);
        curve.buy{value: 1_000 ether}(1_000 ether, 0, creator);
        terminalQuote = address(coordinator).balance;
        terminalTokens = IERC20(token).balanceOf(address(coordinator));
    }

    function _quoteLaunch()
        internal
        returns (address token, address curveAddress, uint256 terminalQuote, uint256 terminalTokens)
    {
        (token, curveAddress) = factory.launch(
            address(quote), creator, 1_000_000 ether, 100 ether, 100 ether, feePolicy, escrow, buybackVault
        );
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(payable(curveAddress));
        _wireExecutor(curve.trackedTokens() / 2);
        quote.mint(creator, 1_000 ether);
        vm.prank(creator);
        quote.approve(curveAddress, type(uint256).max);
        vm.prank(creator);
        curve.buy(1_000 ether, 0, creator);
        terminalQuote = quote.balanceOf(address(coordinator));
        terminalTokens = IERC20(token).balanceOf(address(coordinator));
    }

    function testNativeAutomaticHandoffFailureRetryReplayAndCustody() public {
        (address token, address curveAddress, uint256 terminalQuote, uint256 terminalTokens) = _nativeLaunch();
        _assertSecured(token, curveAddress, address(0), terminalQuote, terminalTokens);
        _assertHandoffAndResweepProtection(token);
        _assertFailedRetryUnchanged(token, address(0), terminalQuote, terminalTokens);

        executor.setFailNext(false);
        vm.prank(arbitraryCaller);
        address destination = coordinator.complete(token);
        assertEq(destination, address(0xA11CE));
        _assertCompleted(token, terminalQuote, terminalTokens);

        vm.expectRevert(DEV4GraduationCoordinator.WrongPhase.selector);
        vm.prank(arbitraryCaller);
        coordinator.complete(token);
    }

    function testQuoteAutomaticHandoffFailureRetryReplayAndCustody() public {
        (address token, address curveAddress, uint256 terminalQuote, uint256 terminalTokens) = _quoteLaunch();
        _assertSecured(token, curveAddress, address(quote), terminalQuote, terminalTokens);
        _assertHandoffAndResweepProtection(token);
        _assertFailedRetryUnchanged(token, curveAddress, terminalQuote, terminalTokens);

        executor.setFailNext(false);
        vm.prank(arbitraryCaller);
        address destination = coordinator.complete(token);
        assertEq(destination, address(0xA11CE));
        _assertCompleted(token, terminalQuote, terminalTokens);

        vm.expectRevert(DEV4GraduationCoordinator.WrongPhase.selector);
        vm.prank(arbitraryCaller);
        coordinator.complete(token);
    }

    function testWrongExecutorCannotConsumeSecuredQuotePacket() public {
        (address token,, uint256 terminalQuote, uint256 terminalTokens) = _quoteLaunch();
        DEV4ResearchVenueExecutor wrong = new DEV4ResearchVenueExecutor(terminalTokens / 2, 1);
        vm.expectRevert("allowance");
        wrong.execute(address(coordinator), token, address(quote), terminalQuote, terminalTokens, address(custody));

        executor.setFailNext(false);
        vm.prank(arbitraryCaller);
        coordinator.complete(token);
        assertEq(uint8(coordinator.phase(token)), uint8(DEV4GraduationCoordinator.Phase.Graduated));
    }

    function testThinFactoryRuntimeIsResearchOnly() public {
        emit log_named_uint("research_thin_factory_runtime_bytes", address(factory).code.length);
        assertLt(address(factory).code.length, 23_500);
    }

    function _assertSecured(
        address token,
        address curveAddress,
        address quoteAsset,
        uint256 terminalQuote,
        uint256 terminalTokens
    ) internal view {
        assertEq(uint8(coordinator.phase(token)), uint8(DEV4GraduationCoordinator.Phase.Graduating));
        DEV4GraduationCoordinator.SecuredLaunch memory packet = coordinator.secured(token);
        assertEq(packet.token, token);
        assertEq(packet.quoteAsset, quoteAsset);
        assertEq(packet.quoteAmount, terminalQuote);
        assertEq(packet.tokenAmount, terminalTokens);
        assertEq(packet.consumedQuote, 0);
        assertEq(packet.consumedTokens, 0);
        assertEq(packet.destination, address(0));
        assertEq(address(factory).balance, 0);
        assertEq(IERC20(token).balanceOf(address(factory)), 0);
        assertTrue(factory.authorityHandedOff(token));
        assertTrue(RetroPickBondingCurveV2(payable(curveAddress)).graduated());
    }

    function _assertHandoffAndResweepProtection(address token) internal {
        vm.expectRevert(DEV4ThinFactory.AlreadyHandedOff.selector);
        factory.graduate(token);

        vm.expectRevert(DEV4GraduationCoordinator.WrongPhase.selector);
        attacker.callCoordinatorSecure(coordinator, token, address(0));

        vm.expectRevert(DEV4ThinFactory.NotCoordinator.selector);
        attacker.callSecureCurve(factory, token, address(0));
    }

    function _assertFailedRetryUnchanged(
        address token,
        address curveAddress,
        uint256 terminalQuote,
        uint256 terminalTokens
    ) internal {
        vm.expectRevert(DEV4ResearchVenueExecutor.InjectedFailure.selector);
        vm.prank(arbitraryCaller);
        coordinator.complete(token);

        assertEq(uint8(coordinator.phase(token)), uint8(DEV4GraduationCoordinator.Phase.Graduating));
        assertEq(address(coordinator).balance, curveAddress == address(0) ? terminalQuote : 0);
        assertEq(quote.balanceOf(address(coordinator)), curveAddress == address(0) ? 0 : terminalQuote);
        assertEq(IERC20(token).balanceOf(address(coordinator)), terminalTokens);
        DEV4GraduationCoordinator.SecuredLaunch memory packet = coordinator.secured(token);
        assertEq(packet.consumedQuote, 0);
        assertEq(packet.consumedTokens, 0);
        assertEq(packet.destination, address(0));
    }

    function _assertCompleted(address token, uint256 terminalQuote, uint256 terminalTokens) internal view {
        assertEq(uint8(coordinator.phase(token)), uint8(DEV4GraduationCoordinator.Phase.Graduated));
        DEV4GraduationCoordinator.SecuredLaunch memory packet = coordinator.secured(token);
        assertEq(packet.consumedQuote, terminalQuote);
        assertEq(packet.consumedTokens, terminalTokens);
        assertEq(packet.destination, address(0xA11CE));
        assertEq(address(coordinator).balance, 0);
        assertEq(quote.balanceOf(address(coordinator)), 0);
        assertEq(IERC20(token).balanceOf(address(coordinator)), 0);
        assertEq(IERC20(token).balanceOf(address(custody)), terminalTokens / 2);
        assertEq(custody.lpShares(address(0xA11CE)), 123);
    }
}

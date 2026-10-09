// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {RetroPickQuoteAssetRegistryV2} from "./RetroPickQuoteAssetRegistryV2.sol";
import {IRetroPickFeePolicyV2, FeePolicySnapshot} from "./interfaces/IRetroPickLaunchpadV2.sol";
import {QuoteAssetConfig} from "./interfaces/IGraduationExecutorV2.sol";
import {RetroPickBondingCurveV2} from "./RetroPickBondingCurveV2.sol";
import {ExactAssetV2} from "./libraries/ExactAssetV2.sol";
import {
    GraduationVenue,
    GraduationState,
    GraduationPacket,
    GraduationLedger,
    GraduationReceipt,
    IGraduationExecutorV2,
    IGraduationFactoryV2
} from "./interfaces/IGraduationExecutorV2.sol";

struct GraduationLaunchConfigV2 {
    uint256 supply; uint256 curveFeeBps; uint256 phantomQuote; uint256 graduationThreshold;
    uint24 poolFee; int24 tickSpacing; bool enabled;
}
interface IGraduationLaunchConfigV2 {
    function getLaunchConfig(uint256 id) external view returns (GraduationLaunchConfigV2 memory);
    function memeHook() external view returns (IRetroPickFeePolicyV2);
    function quoteRegistry() external view returns (RetroPickQuoteAssetRegistryV2);
    function getLaunchFeePolicy(address token) external view returns (FeePolicySnapshot memory);
}

/// @notice Sole graduation ledger. Securing commits separately from atomic completion.
contract GraduationCoordinatorV2 is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public factory;
    mapping(GraduationVenue => address) public executors;
    mapping(address => GraduationPacket) private _packets;
    mapping(address => GraduationLedger) private _ledgers;
    mapping(address => GraduationReceipt) private _receipts;
    mapping(address => uint256) public quoteLiability;

    error Unauthorized();
    error InvalidBinding();
    error WrongPhase();
    error InvalidPacket();
    error InexactHandoff();
    error BackingDeficit();
    error InvalidReceipt();
    error UnsafeAllowance();
    event FactoryBound(address indexed factory);
    event ExecutorConfigured(GraduationVenue indexed venue, address indexed executor);
    event LaunchCommitted(address indexed token, GraduationVenue indexed venue, bytes32 packetHash);
    event GraduationSecured(address indexed token, uint256 quote, uint256 launchTokens);
    event GraduationCompleted(address indexed token, bytes32 indexed destination, bytes32 receiptHash);

    constructor(address owner_) Ownable(owner_) {}
    modifier onlyFactory() {
        if (msg.sender != factory) revert Unauthorized();
        _;
    }

    function bindFactory(address factory_) external onlyOwner {
        if (factory != address(0) || factory_.code.length == 0) revert InvalidBinding();
        factory = factory_;
        emit FactoryBound(factory_);
    }

    /// @notice Factory configuration authority; existing packets remain unchanged.
    function configureExecutor(GraduationVenue venue, address executor) external onlyFactory {
        if (
            executor.code.length == 0 || IGraduationExecutorV2(executor).coordinator() != address(this)
                || IGraduationExecutorV2(executor).policyHash() == bytes32(0)
        ) revert InvalidBinding();
        executors[venue] = executor;
        emit ExecutorConfigured(venue, executor);
    }

    function packet(address token) external view returns (GraduationPacket memory) {
        return _packets[token];
    }

    function ledger(address token) external view returns (GraduationLedger memory) {
        return _ledgers[token];
    }

    function receipt(address token) external view returns (GraduationReceipt memory) {
        return _receipts[token];
    }

    function available(address token) external view returns (uint256 quote, uint256 launchTokens) {
        GraduationLedger storage l = _ledgers[token];
        return (l.securedQuote - l.consumedQuote, l.securedLaunchTokens - l.consumedLaunchTokens);
    }

    function previewEconomics(uint256 id, address quote, GraduationVenue venue) external view returns (bytes32) {
        IGraduationLaunchConfigV2 f = IGraduationLaunchConfigV2(factory);
        GraduationLaunchConfigV2 memory config = f.getLaunchConfig(id);
        QuoteAssetConfig memory q = f.quoteRegistry().admitted(quote, venue);
        address executor = executors[venue];
        return keccak256(abi.encode(config.supply, config.curveFeeBps, config.poolFee, config.tickSpacing,
            q.policyHash, q.policyVersion, q.phantomQuote, q.graduationThreshold, q.graduationQuoteCeiling,
            f.memeHook().currentFeePolicy(), venue, executor, executor.codehash,
            IGraduationExecutorV2(executor).policyHash()));
    }

    function registerLaunch(address token, address curveAddress, GraduationVenue venue, uint24 poolFee, int24 tickSpacing)
        external onlyFactory {
        RetroPickBondingCurveV2 c = RetroPickBondingCurveV2(curveAddress);
        QuoteAssetConfig memory q = IGraduationLaunchConfigV2(factory).quoteRegistry().admitted(c.pairToken(), venue);
        GraduationPacket memory p;
        p.token = token; p.curve = curveAddress; p.quoteAsset = c.pairToken(); p.venue = venue;
        p.executor = executors[venue]; p.executorCodeHash = p.executor.codehash;
        p.quoteDecimals = q.decimals; p.quotePolicyVersion = q.policyVersion; p.quotePolicyHash = q.policyHash;
        p.phantomQuote = q.phantomQuote; p.graduationThreshold = q.graduationThreshold;
        p.graduationQuoteCeiling = q.graduationQuoteCeiling; p.poolFee = poolFee; p.tickSpacing = tickSpacing;
        p.feePolicy = IGraduationLaunchConfigV2(factory).getLaunchFeePolicy(token);
        p.venuePolicyHash = IGraduationExecutorV2(p.executor).policyHash();
        p.protectedLPReceiver = IGraduationExecutorV2(p.executor).previewReceiver(p);
        p.protectedExcessReceiver = p.protectedLPReceiver;
        if (
            _packets[p.token].token != address(0) || p.token == address(0) || p.curve.code.length == 0
                || p.executor != executors[p.venue] || p.executor.codehash != p.executorCodeHash
                || p.venuePolicyHash != IGraduationExecutorV2(p.executor).policyHash()
                || p.protectedLPReceiver == address(0) || p.protectedExcessReceiver != p.protectedLPReceiver
                || p.protectedLPReceiver != IGraduationExecutorV2(p.executor).previewReceiver(p)
        ) revert InvalidPacket();
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(p.curve);
        if (
            curve.factory() != factory || curve.token() != p.token || curve.pairToken() != p.quoteAsset
                || curve.graduationQuoteCeiling() != p.graduationQuoteCeiling || curve.phantomQuote() != p.phantomQuote
                || curve.graduationThreshold() != p.graduationThreshold
        ) {
            revert InvalidPacket();
        }
        IGraduationExecutorV2(p.executor).validateLaunch(p, IERC20(p.token).totalSupply());
        _packets[p.token] = p;
        _ledgers[p.token].protectedLPReceiver = p.protectedLPReceiver;
        _ledgers[p.token].protectedExcessReceiver = p.protectedExcessReceiver;
        emit LaunchCommitted(p.token, p.venue, keccak256(abi.encode(p)));
    }

    function secure(address token) external onlyFactory nonReentrant {
        GraduationPacket memory p = _packets[token];
        GraduationLedger storage l = _ledgers[token];
        if (p.token == address(0) || l.phase != GraduationState.NONE) revert WrongPhase();
        RetroPickBondingCurveV2 curve = RetroPickBondingCurveV2(p.curve);
        if (curve.graduated() || !curve.readyToGraduate()) revert WrongPhase();
        uint256 expectedQuote = curve.realQuoteReserve();
        uint256 expectedTokens = curve.tokenReserve();
        if (expectedQuote == 0 || expectedQuote > p.graduationQuoteCeiling || expectedTokens == 0) {
            revert InvalidPacket();
        }
        uint256 quoteBefore = ExactAssetV2.balance(p.quoteAsset, address(this));
        uint256 tokensBefore = IERC20(token).balanceOf(address(this));
        if (quoteBefore < quoteLiability[p.quoteAsset]) revert BackingDeficit();
        (uint256 reportedQuote, uint256 reportedTokens) = IGraduationFactoryV2(factory).secureCurve(token);
        if (
            reportedQuote != expectedQuote || reportedTokens != expectedTokens
                || ExactAssetV2.balance(p.quoteAsset, address(this)) != quoteBefore + expectedQuote
                || IERC20(token).balanceOf(address(this)) != tokensBefore + expectedTokens
        ) revert InexactHandoff();
        l.securedQuote = expectedQuote;
        l.securedLaunchTokens = expectedTokens;
        l.securedAt = block.timestamp;
        quoteLiability[p.quoteAsset] += expectedQuote;
        l.phase = GraduationState.GRADUATING;
        emit GraduationSecured(token, expectedQuote, expectedTokens);
    }

    function complete(address token) external nonReentrant returns (GraduationReceipt memory r) {
        GraduationLedger storage l = _ledgers[token];
        if (l.phase != GraduationState.GRADUATING) revert WrongPhase();
        GraduationPacket memory p = _packets[token];
        if (p.executor.codehash != p.executorCodeHash || l.destinationIdentity != bytes32(0)) revert InvalidPacket();
        uint256 quoteAmount = l.securedQuote - l.consumedQuote;
        uint256 tokenAmount = l.securedLaunchTokens - l.consumedLaunchTokens;
        uint256 quoteBefore = ExactAssetV2.balance(p.quoteAsset, address(this));
        uint256 tokenBefore = IERC20(token).balanceOf(address(this));
        uint256 protectedBefore = IERC20(token).balanceOf(p.protectedExcessReceiver);
        if (quoteBefore < quoteLiability[p.quoteAsset] || tokenBefore < tokenAmount) revert BackingDeficit();
        _approveExact(token, p.executor, tokenAmount);
        if (p.quoteAsset != address(0)) _approveExact(p.quoteAsset, p.executor, quoteAmount);
        r = IGraduationExecutorV2(p.executor).execute{value: p.quoteAsset == address(0) ? quoteAmount : 0}(
            p, quoteAmount, tokenAmount
        );
        _clearAllowance(token, p.executor);
        if (p.quoteAsset != address(0)) _clearAllowance(p.quoteAsset, p.executor);
        if (
            r.packetHash != keccak256(abi.encode(p)) || r.destinationIdentity == bytes32(0) || r.seededQuote == 0
                || r.seededLaunchTokens == 0 || r.protectedLPAmount == 0
                || r.seededQuote + r.quoteResidual != quoteAmount
                || r.seededLaunchTokens + r.protectedExcessAmount != tokenAmount
                || r.protectedLPReceiver != p.protectedLPReceiver
                || r.protectedExcessReceiver != p.protectedExcessReceiver
                || (r.quoteResidual != 0 && r.quoteResidualReceiver != p.feePolicy.protocolFeeRecipient)
                || ExactAssetV2.balance(p.quoteAsset, address(this)) != quoteBefore - quoteAmount
                || IERC20(token).balanceOf(address(this)) != tokenBefore - tokenAmount
                || IERC20(token).balanceOf(p.protectedExcessReceiver) != protectedBefore + r.protectedExcessAmount
        ) {
            revert InvalidReceipt();
        }
        IGraduationExecutorV2(p.executor).verifyReceipt(p, r);
        quoteLiability[p.quoteAsset] -= quoteAmount;
        if (ExactAssetV2.balance(p.quoteAsset, address(this)) < quoteLiability[p.quoteAsset]) revert BackingDeficit();
        l.consumedQuote += quoteAmount;
        l.consumedLaunchTokens += tokenAmount;
        l.destinationIdentity = r.destinationIdentity;
        l.receiptHash = keccak256(abi.encode(r));
        l.protectedLPAmount = r.protectedLPAmount;
        l.protectedExcessAmount = r.protectedExcessAmount;
        _receipts[token] = r;
        l.phase = GraduationState.GRADUATED;
        emit GraduationCompleted(token, r.destinationIdentity, l.receiptHash);
    }

    function _approveExact(address token, address spender, uint256 amount) private {
        if (IERC20(token).allowance(address(this), spender) != 0) revert UnsafeAllowance();
        IERC20(token).forceApprove(spender, amount);
        if (IERC20(token).allowance(address(this), spender) != amount) revert UnsafeAllowance();
    }

    function _clearAllowance(address token, address spender) private {
        IERC20(token).forceApprove(spender, 0);
        if (IERC20(token).allowance(address(this), spender) != 0) revert UnsafeAllowance();
    }
    receive() external payable {}
}

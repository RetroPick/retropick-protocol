// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SettlementKind} from "../VenueRegistryV3.sol";
import {LaunchCommitmentHubV3} from "./LaunchCommitmentHubV3.sol";
import {
    LaunchCommitmentV3,
    AtomicExecutionContextV3,
    AtomicGraduationReceiptV3,
    IAtomicVenueExecutorV3
} from "./LaunchFrameworkTypesV3.sol";

/// @notice Proof of a single authoritative ledger for atomic EVM graduation.
/// @dev ERC20-only, full-amount consumption model. DOES NOT implement V2's
///      bonding-curve handoff, native-quote path, partial seed/residual policy,
///      full Uniswap/Kuru receipt semantics, or production recovery.
contract AtomicGraduationEscrowV3 is ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Phase {
        NONE,
        SECURED,
        GRADUATED
    }

    struct Ledger {
        Phase phase;
        uint256 securedToken;
        uint256 securedQuote;
        bytes32 destinationId;
        bytes32 settlementProof;
    }

    address public immutable factory;
    LaunchCommitmentHubV3 public immutable hub;
    mapping(bytes32 launchId => Ledger) private _ledgers;
    mapping(address asset => uint256) public assetLiability;

    error OnlyFactory();
    error WrongPhase();
    error InvalidCommitment();
    error InvalidAmount();
    error BackingDeficit();
    error InexactHandoff();
    error InvalidReceipt();
    error UnsafeAllowance();

    event GraduationSecured(bytes32 indexed launchId, uint256 tokenAmount, uint256 quoteAmount);
    event GraduationCompleted(bytes32 indexed launchId, bytes32 indexed destinationId, bytes32 proof);

    constructor(address factory_, LaunchCommitmentHubV3 hub_) {
        if (factory_ == address(0) || address(hub_).code.length == 0 || hub_.factory() != factory_) {
            revert InvalidCommitment();
        }
        factory = factory_;
        hub = hub_;
    }

    modifier onlyFactory() {
        if (msg.sender != factory) revert OnlyFactory();
        _;
    }

    function ledger(bytes32 launchId) external view returns (Ledger memory) {
        return _ledgers[launchId];
    }

    /// @notice The qualified Factory must first terminate/secure its real curve
    ///         before supplying exact graduation inventory to this escrow.
    /// @dev Uses transferFrom(factory) for the proof. Production V3 MUST preserve
    ///      V2's curve handoff and verify the same physical balance invariants.
    function secure(bytes32 launchId, uint256 tokenAmount, uint256 quoteAmount) external onlyFactory nonReentrant {
        Ledger storage l = _ledgers[launchId];
        LaunchCommitmentV3 memory c = hub.commitment(launchId);
        if (
            c.launchId != launchId || c.factory != factory || c.sourceChainId != block.chainid
                || c.settlementKind != SettlementKind.ATOMIC_EVM || c.quoteAsset == address(0)
                || c.token == c.quoteAsset
        ) revert InvalidCommitment();
        if (l.phase != Phase.NONE) revert WrongPhase();
        if (tokenAmount == 0 || quoteAmount == 0) revert InvalidAmount();

        IERC20 token = IERC20(c.token);
        IERC20 quote = IERC20(c.quoteAsset);
        uint256 tokenBefore = token.balanceOf(address(this));
        uint256 quoteBefore = quote.balanceOf(address(this));
        if (tokenBefore < assetLiability[c.token] || quoteBefore < assetLiability[c.quoteAsset]) {
            revert BackingDeficit();
        }

        token.safeTransferFrom(factory, address(this), tokenAmount);
        quote.safeTransferFrom(factory, address(this), quoteAmount);
        if (
            token.balanceOf(address(this)) != tokenBefore + tokenAmount
                || quote.balanceOf(address(this)) != quoteBefore + quoteAmount
        ) revert InexactHandoff();

        assetLiability[c.token] += tokenAmount;
        assetLiability[c.quoteAsset] += quoteAmount;
        l.securedToken = tokenAmount;
        l.securedQuote = quoteAmount;
        l.phase = Phase.SECURED;
        emit GraduationSecured(launchId, tokenAmount, quoteAmount);
    }

    /// @notice Permissionless retryable completion for *prequalified* atomic adapters.
    /// @dev Do not use for HIP-1/HIP-2 or cross-chain graduation.
    function complete(bytes32 launchId) external nonReentrant returns (AtomicGraduationReceiptV3 memory receipt) {
        Ledger storage l = _ledgers[launchId];
        if (l.phase != Phase.SECURED) revert WrongPhase();
        LaunchCommitmentV3 memory c = hub.commitment(launchId);
        if (
            c.launchId != launchId || c.factory != factory || c.sourceChainId != block.chainid
                || c.settlementKind != SettlementKind.ATOMIC_EVM || c.adapter.codehash != c.adapterCodeHash
                || c.adapter.code.length == 0
        ) revert InvalidCommitment();

        if (IAtomicVenueExecutorV3(c.adapter).coordinator() != address(this)) revert InvalidCommitment();
        IERC20 token = IERC20(c.token);
        IERC20 quote = IERC20(c.quoteAsset);
        uint256 tokenBefore = token.balanceOf(address(this));
        uint256 quoteBefore = quote.balanceOf(address(this));
        if (tokenBefore < assetLiability[c.token] || quoteBefore < assetLiability[c.quoteAsset]) {
            revert BackingDeficit();
        }

        if (token.allowance(address(this), c.adapter) != 0 || quote.allowance(address(this), c.adapter) != 0) {
            revert UnsafeAllowance();
        }
        token.forceApprove(c.adapter, l.securedToken);
        quote.forceApprove(c.adapter, l.securedQuote);

        AtomicExecutionContextV3 memory context = AtomicExecutionContextV3({
            launchId: launchId,
            token: c.token,
            quoteAsset: c.quoteAsset,
            tokenAmount: l.securedToken,
            quoteAmount: l.securedQuote,
            venueConfigHash: c.venueConfigHash,
            economicsHash: c.economicsHash,
            venuePolicyHash: c.venuePolicyHash
        });

        receipt = IAtomicVenueExecutorV3(c.adapter).execute(context);

        token.forceApprove(c.adapter, 0);
        quote.forceApprove(c.adapter, 0);

        if (
            receipt.launchId != launchId || receipt.destinationId == bytes32(0) || receipt.settlementProof == bytes32(0)
                || receipt.tokenSpent != l.securedToken || receipt.quoteSpent != l.securedQuote
                || token.balanceOf(address(this)) != tokenBefore - l.securedToken
                || quote.balanceOf(address(this)) != quoteBefore - l.securedQuote
        ) revert InvalidReceipt();
        if (!IAtomicVenueExecutorV3(c.adapter).verify(context, receipt)) revert InvalidReceipt();

        assetLiability[c.token] -= l.securedToken;
        assetLiability[c.quoteAsset] -= l.securedQuote;
        if (
            token.balanceOf(address(this)) < assetLiability[c.token]
                || quote.balanceOf(address(this)) < assetLiability[c.quoteAsset]
        ) revert BackingDeficit();

        l.destinationId = receipt.destinationId;
        l.settlementProof = receipt.settlementProof;
        l.phase = Phase.GRADUATED;
        emit GraduationCompleted(launchId, receipt.destinationId, receipt.settlementProof);
    }
}

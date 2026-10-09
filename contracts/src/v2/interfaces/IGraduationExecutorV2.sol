// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FeePolicySnapshot} from "./IRetroPickLaunchpadV2.sol";

enum GraduationVenue { UNISWAP_V4, KURU }
enum GraduationState { NONE, GRADUATING, GRADUATED }

struct QuoteAssetConfig {
    bool enabled;
    uint8 decimals;
    uint8 venueMask;
    uint32 policyVersion;
    uint256 phantomQuote;
    uint256 graduationThreshold;
    uint256 graduationQuoteCeiling;
    bytes32 assetId;
    bytes32 policyHash;
}

/// @notice Launch-time commitment. None of these terms can be changed on retry.
struct GraduationPacket {
    address token;
    address curve;
    address quoteAsset;
    GraduationVenue venue;
    address executor;
    bytes32 executorCodeHash;
    uint8 quoteDecimals;
    uint32 quotePolicyVersion;
    bytes32 quotePolicyHash;
    uint256 phantomQuote;
    uint256 graduationThreshold;
    uint256 graduationQuoteCeiling;
    bytes32 venuePolicyHash;
    address protectedLPReceiver;
    address protectedExcessReceiver;
    uint24 poolFee;
    int24 tickSpacing;
    FeePolicySnapshot feePolicy;
}

struct GraduationLedger {
    GraduationState phase;
    uint256 securedQuote;
    uint256 securedLaunchTokens;
    uint256 consumedQuote;
    uint256 consumedLaunchTokens;
    bytes32 destinationIdentity;
    bytes32 receiptHash;
    address protectedLPReceiver;
    uint256 protectedLPAmount;
    address protectedExcessReceiver;
    uint256 protectedExcessAmount;
    uint256 securedAt;
}

struct GraduationReceipt {
    bytes32 packetHash;
    bytes32 destinationIdentity;
    address market;
    address vault;
    address lpAsset;
    uint256 positionId;
    uint256 seededQuote;
    uint256 seededLaunchTokens;
    uint256 quoteResidual;
    address quoteResidualReceiver;
    address protectedLPReceiver;
    uint256 protectedLPAmount;
    address protectedExcessReceiver;
    uint256 protectedExcessAmount;
}

interface IGraduationExecutorV2 {
    function coordinator() external view returns (address);
    function policyHash() external view returns (bytes32);
    /// @notice Derive a bound receiver before trading opens; no assets move.
    function previewReceiver(GraduationPacket calldata packet) external view returns (address);
    function validateLaunch(GraduationPacket calldata packet, uint256 supply) external view;
    function execute(GraduationPacket calldata packet, uint256 quoteAmount, uint256 tokenAmount)
        external payable returns (GraduationReceipt memory);
    function verifyReceipt(GraduationPacket calldata packet, GraduationReceipt calldata receipt) external view;
}

interface IGraduationFactoryV2 {
    function secureCurve(address token) external returns (uint256 quoteOut, uint256 tokenOut);
}

interface IGraduationCoordinatorV2 {
    function factory() external view returns (address);
    function registerLaunch(GraduationPacket calldata packet) external;
    function packet(address token) external view returns (GraduationPacket memory);
    function ledger(address token) external view returns (GraduationLedger memory);
    function secure(address token) external;
    function complete(address token) external returns (GraduationReceipt memory);
}

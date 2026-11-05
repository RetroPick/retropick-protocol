// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IRetroPickQuoteAssetPolicyV2} from "./interfaces/IRetroPickQuoteAssetPolicyV2.sol";
import {QuoteAssetConfig, GraduationVenue} from "./interfaces/IGraduationExecutorV2.sol";

/// @notice Versioned chain-specific quote admission. Updates affect new launches only.
/// @dev Admission never substitutes for exact-transfer/backing checks at use.
contract RetroPickQuoteAssetRegistryV2 is Ownable2Step, IRetroPickQuoteAssetPolicyV2 {
    uint256 public constant TARGET_CHAIN_ID = 10143;
    address public constant CIRCLE_TEST_USDC = 0x534b2f3A21130d7a60830c2Df862319e593943A3;
    mapping(address => QuoteAssetConfig) private _configs;

    error InvalidQuoteConfig();
    error UnsupportedQuote();
    error WrongChain();
    event QuoteAssetConfigured(address indexed quote, uint32 indexed version, bytes32 policyHash, bool enabled);

    constructor(address owner_) Ownable(owner_) {
        if (block.chainid != TARGET_CHAIN_ID) revert WrongChain();
    }

    function configure(address quote, QuoteAssetConfig calldata proposed) external onlyOwner {
        if (block.chainid != TARGET_CHAIN_ID) revert WrongChain();
        if (
            proposed.policyVersion <= _configs[quote].policyVersion || proposed.assetId == bytes32(0)
                || proposed.phantomQuote == 0 || proposed.graduationThreshold == 0
                || proposed.graduationQuoteCeiling < proposed.graduationThreshold || proposed.venueMask == 0
                || proposed.venueMask > 3
        ) revert InvalidQuoteConfig();
        _validateIdentity(quote, proposed.decimals);
        QuoteAssetConfig memory config = proposed;
        config.policyHash = keccak256(
            abi.encode(
                TARGET_CHAIN_ID,
                quote,
                config.enabled,
                config.decimals,
                config.venueMask,
                config.policyVersion,
                config.phantomQuote,
                config.graduationThreshold,
                config.graduationQuoteCeiling,
                config.assetId
            )
        );
        if (proposed.policyHash != bytes32(0) && proposed.policyHash != config.policyHash) revert InvalidQuoteConfig();
        _configs[quote] = config;
        emit QuoteAssetConfigured(quote, config.policyVersion, config.policyHash, config.enabled);
    }

    function getConfig(address quote) external view returns (QuoteAssetConfig memory) {
        return _configs[quote];
    }

    function admitted(address quote, GraduationVenue venue) external view returns (QuoteAssetConfig memory config) {
        config = _configs[quote];
        if (block.chainid != TARGET_CHAIN_ID || !config.enabled || config.venueMask & (uint8(1) << uint8(venue)) == 0) {
            revert UnsupportedQuote();
        }
        _validateIdentity(quote, config.decimals);
    }

    function isSupportedQuote(address quote) external view returns (bool) {
        return block.chainid == TARGET_CHAIN_ID && _configs[quote].enabled;
    }

    function validateQuote(address quote, uint8 expectedDecimals) external view {
        if (
            block.chainid != TARGET_CHAIN_ID || !_configs[quote].enabled || _configs[quote].decimals != expectedDecimals
        ) revert UnsupportedQuote();
        _validateIdentity(quote, expectedDecimals);
    }

    function _validateIdentity(address quote, uint8 expectedDecimals) private view {
        if (quote == address(0)) {
            if (expectedDecimals != 18) revert InvalidQuoteConfig();
        } else {
            if (quote.code.length == 0) revert InvalidQuoteConfig();
            try IERC20Metadata(quote).decimals() returns (uint8 actual) {
                if (actual != expectedDecimals) revert InvalidQuoteConfig();
            } catch {
                revert InvalidQuoteConfig();
            }
        }
    }
}

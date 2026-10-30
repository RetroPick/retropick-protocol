// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IRetroPickQuoteAssetPolicyV2} from "./interfaces/IRetroPickQuoteAssetPolicyV2.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @notice Immutable P0 Monad Testnet quote identity policy.
/// @dev Address admission is not a proof of ERC-20 behavior. Curve and escrow
///      separately enforce exact physical balance changes on every write.
contract RetroPickQuoteAssetPolicyV2 is IRetroPickQuoteAssetPolicyV2 {
    uint256 public constant TARGET_CHAIN_ID = 10143;
    address public constant CIRCLE_TEST_USDC = 0x534b2f3A21130d7a60830c2Df862319e593943A3;

    error QuoteNotSupported();
    error QuoteCodeMissing();
    error QuoteDecimalsUnavailable();
    error QuoteDecimalsMismatch(uint8 expected, uint8 actual);

    function isSupportedQuote(address quote) external view returns (bool) {
        return block.chainid == TARGET_CHAIN_ID && (quote == address(0) || quote == CIRCLE_TEST_USDC);
    }

    function validateQuote(address quote, uint8 expectedDecimals) external view {
        if (block.chainid != TARGET_CHAIN_ID || quote != CIRCLE_TEST_USDC) revert QuoteNotSupported();
        if (quote.code.length == 0) revert QuoteCodeMissing();
        try IERC20Metadata(quote).decimals() returns (uint8 actual) {
            if (actual != expectedDecimals || actual != 6) revert QuoteDecimalsMismatch(expectedDecimals, actual);
        } catch {
            revert QuoteDecimalsUnavailable();
        }
    }
}

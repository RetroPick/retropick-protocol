// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IRetroPickQuoteAssetPolicyV2 {
    function isSupportedQuote(address quote) external view returns (bool);
    function validateQuote(address quote, uint8 expectedDecimals) external view;
}

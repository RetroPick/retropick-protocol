// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {RetroPickBondingCurveMathV2} from "./RetroPickBondingCurveMathV2.sol";

/// @notice Exact executable final-buy arithmetic, matching the Python completion oracle.
library CompletionQuoteMathV2 {
    struct State {
        uint256 phantomQuote;
        uint256 trackedQuote;
        uint256 quoteFeeBalance;
        uint256 creatorTaxBalance;
        uint256 trackedTokens;
        uint256 reservedTokens;
        uint256 feeBps;
        uint256 creatorTaxBps;
    }
    error InvalidCompletionState();
    error CompletionOverflow();

    function calculate(State memory s) internal pure returns (uint256 terminalQuote, uint256 grossInput) {
        if (
            s.phantomQuote == 0 || s.reservedTokens == 0 || s.trackedTokens < s.reservedTokens
                || s.quoteFeeBalance + s.creatorTaxBalance > s.trackedQuote || s.feeBps + s.creatorTaxBps > 2_000
        ) revert InvalidCompletionState();
        uint256 realQuote = s.trackedQuote - s.quoteFeeBalance - s.creatorTaxBalance;
        uint256 virtualQuote = s.phantomQuote + realQuote;
        uint256 remaining = s.trackedTokens - s.reservedTokens;
        if (remaining == 0) return (realQuote, 0);
        uint256 net = RetroPickBondingCurveMathV2.getAmountIn(remaining, virtualQuote, s.trackedTokens, 0);
        grossInput = Math.mulDiv(net, 10_000, 10_000 - s.feeBps - s.creatorTaxBps, Math.Rounding.Ceil);
        uint256 fee = grossInput * s.feeBps / 10_000;
        uint256 tax = grossInput * s.creatorTaxBps / 10_000;
        _checkAdd(s.trackedQuote, grossInput);
        _checkAdd(s.quoteFeeBalance, fee);
        _checkAdd(s.creatorTaxBalance, tax);
        uint256 actualNet = grossInput - fee - tax;
        // buy() executes this checked quote before it can clamp the output.
        if (RetroPickBondingCurveMathV2.getAmountOut(actualNet, virtualQuote, s.trackedTokens, 0) < remaining) {
            revert InvalidCompletionState();
        }
        // Even a minTokensOut=0 final buy evaluates received * tokensOut.
        if (grossInput > type(uint256).max / remaining) revert CompletionOverflow();
        terminalQuote = realQuote + actualNet;
    }

    function _checkAdd(uint256 a, uint256 b) private pure {
        if (a > type(uint256).max - b) revert CompletionOverflow();
    }
}

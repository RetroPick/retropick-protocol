// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @notice Qualified minimum launch profile, explicitly TESTNET_POLICY_V1; not production economics.
library KuruParameterPolicyV2 {
    uint96 internal constant SIZE_PRECISION = 1e8;
    uint32 internal constant PRICE_PRECISION = 1e8;
    uint32 internal constant TICK_SIZE = 1;
    uint96 internal constant MIN_SIZE = 1e6;
    uint96 internal constant MAX_SIZE = 1e16;
    uint256 internal constant TAKER_FEE = 30;
    uint256 internal constant MAKER_FEE = 0;
    uint96 internal constant SPREAD = 100;
    uint256 internal constant SEED_TOLERANCE_BPS = 5;
    bytes32 internal constant POLICY_HASH = keccak256(
        "RetroPick.Kuru.TESTNET_POLICY_V1.minimum.1000tokens.P=threshold=1.C=50.size=1e8.price=1e8.tick=1.min=1e6.max=1e16.taker=30.maker=0.spread=100.tolerance=5bps"
    );
    error OutsideQualifiedDomain();

    function validate(uint256 supply, uint8 decimals, uint256 phantom, uint256 threshold, uint256 ceiling)
        internal
        pure
    {
        if (
            supply != 1000 ether || (decimals != 6 && decimals != 18) || phantom != 10 ** decimals
                || threshold != phantom || ceiling != 50 * phantom
        ) revert OutsideQualifiedDomain();
    }

    function seed(uint256 terminalTokens, uint256 quote, uint256 phantom) internal pure returns (uint256 base) {
        base = Math.mulDiv(terminalTokens, quote, phantom + quote);
        if (base == 0 || base >= terminalTokens || base > type(uint256).max / quote || Math.sqrt(base * quote) <= 1000) revert OutsideQualifiedDomain();
    }

    function referencePrice(uint256 terminalTokens, uint256 quote, uint256 phantom, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        return Math.mulDiv(phantom + quote, 1e36, terminalTokens * 10 ** decimals);
    }

    function opening(uint256 baseSeed, uint256 quote, uint8 decimals)
        internal
        pure
        returns (uint256 bid, uint256 ask, uint256 bidSize, uint256 askSize)
    {
        ask = Math.mulDiv(quote, 1e36, baseSeed * 10 ** decimals);
        // Pinned Kuru FixedPointMathLib.mulDivRound rounds half up.
        bid = (ask * 10000 + (10000 + SPREAD) / 2) / (10000 + SPREAD);
        bidSize = Math.mulDiv(SPREAD * baseSeed, SIZE_PRECISION, 20000 * 1 ether);
        askSize = Math.mulDiv(SPREAD * baseSeed, SIZE_PRECISION, (20000 + SPREAD) * 1 ether);
        if (bidSize < MIN_SIZE || askSize < MIN_SIZE || bidSize > MAX_SIZE || askSize > MAX_SIZE) {
            revert OutsideQualifiedDomain();
        }
    }
}

---
id: LP-CURVE
type: normative
product: launchpad
version: v2
status: active
---

# Bonding Curve

P0 uses the accepted deterministic constant-product-style primary curve.

Define:
- token reserve;
- real quote reserve;
- phantom/virtual quote reserve used for pricing;
- fee ordering;
- integer rounding;
- executable buy/sell;
- graduation progress/threshold.

## Buy

Quote enters, explicit fees are allocated, token output is computed with accepted integer arithmetic and user min-out is enforced.

## Sell

Tokens enter, quote output is computed, fees apply per accepted ordering, real quote solvency is checked and min-out enforced.

## Safety properties

- output cannot exceed available real asset;
- larger valid input cannot produce less precondition-equivalent output solely from arithmetic error;
- rounding cannot be repeatedly extracted for positive free value;
- Kuru migration may not change curve arithmetic.

Exact implementation/verification details belong in development contract specs.

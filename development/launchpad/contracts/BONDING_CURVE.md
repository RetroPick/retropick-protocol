---
id: LP-SC-CURVE
type: normative_implementation
status: ready
owner: launchpad-solidity
product: launchpad
version: v2
---

# Bonding Curve

## CURRENT
Primary pricing uses constant-product math with real token/quote reserves plus configured phantom quote reserve. Fees are applied on input according to current V2 logic.

## TARGET
Freeze accepted curve arithmetic before Kuru refactoring. Destination integration must not alter getAmountOut/getAmountIn, rounding direction, reserve transitions or fee ordering.

## Numeric rules
- deterministic integer arithmetic;
- no tolerance for parity tests;
- quote payout never exceeds real withdrawable quote reserve;
- threshold crossing is atomic with the accepted state transition;
- zero/insufficient-liquidity paths fail explicitly.

## Tests
Exact fixtures, fuzz monotonicity/bounds, threshold-crossing tests and stateful reserve conservation.

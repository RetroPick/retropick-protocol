# Bonding Curve Math

**Status:** DRAFT / LP-MATH-1 INPUT  
**Owner:** Protocol + Validation

Let effective reserves be `x` (token) and `y` (quote, including any pricing-only virtual component where specified). The exact implementation equations, fee ordering and integer rounding must be copied from accepted V2 code/reference calculations into this document before LP-MATH-1 can pass.

## Required proofs/properties

1. Buy output is non-negative and does not exceed available token reserve.
2. Sell output never exceeds real withdrawable quote after accounting rules.
3. Increasing valid buy input cannot reduce token output.
4. Increasing valid sell input cannot reduce pre-fee quote output.
5. Integer rounding never creates withdrawable value from nothing.
6. Fee accounting plus reserve deltas reconcile transferred assets.
7. Threshold crossing cannot create duplicate or missing assets.
8. Exact Solidity arithmetic is reproduced in an executable reference test.

## Gate

LP-MATH-1 is not PASS until formulas, bounds, decimals and rounding are explicit rather than described only in prose.

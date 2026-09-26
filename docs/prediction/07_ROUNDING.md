# Rounding

## Policy

| Event | Rule |
|---|---|
| YES_WIN / NO_WIN raw payout | exact 1:1 because numerators are 2 and 0 over denominator 2 |
| INVALID | `floor((redeemed + q) / 2) - floor(redeemed / 2)` per side |
| Dust | when both sides of an equal complete set `C` are fully redeemed, dust is `C mod 2` |
| Fees | none in Phase 1 |

## Counterexamples that justify the policy

| Policy | One unit, both sides | Classification |
|---|---|---|
| `ceil(q/2)` on each side | pays 2 against collateral 1 | COUNTEREXAMPLE_FOUND, insolvent |
| per-call `floor(q/2)` on 1-unit calls | pays 0 for every call | COUNTEREXAMPLE_FOUND for fairness. The gap versus cumulative floor for supply 5 is 2 on one side |
| cumulative floor | full redemption of supply 5 pays 2 per side, residual 1 | PROVEN on the integer market for amounts 1..32 in `test_invalid_dust_is_modulus_two` |

## Decimals

`compare_scales(48)` checked collateral-native cumulative half against a convert-back from scales `10^6`, `10^12`, and `10^18`. Mismatches: 0. Classification: EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN for that grid. Matching decimals is still the recommendation because the 1:1 winner path should be an integer identity with one rounding boundary, not because the grid found a solvent mismatch. ADR-P02.

Phase 1 should approve one collateral and copy its decimals onto the outcome tokens. The kernel does that.

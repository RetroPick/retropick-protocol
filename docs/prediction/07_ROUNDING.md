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

## Composition domain

Ordered compositions of outstanding supply 0 through 16. Holders are A and B. Labelings are all-A and alternating. Both the YES cursor and the NO cursor are replayed. The market state machine remains `exhaustive_search.explore`. The 1-unit stream remains `test_invalid_dust_is_modulus_two`.

| Rule | Measured result |
|---|---|
| cumulative `integer_payout_delta(..., 1, 2)` | EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN. Each side pays `floor(supply / 2)`. Residual after both sides is `supply mod 2`. 131087 states, 2097154 transitions, 131070 labeled compositions, 0.410255s |
| per-call `per_call_floor_half` | COUNTEREXAMPLE_FOUND. Smallest witness in the domain: supply 2, parts `(1, 1)`, one-shot 1, per-call pays 0. 128512 labeled compositions underpay. `fragmentation_gap(5)` remains 2 |
| `naive_half_up` on both sides | COUNTEREXAMPLE_FOUND. `half_up_both_sides(1) == 2` |

`PredictionMarket._redeem` with INVALID numerators `(1, 1)` and denominator 2 is that cumulative floor. The Foundry replay of the same compositions matched it: 131087 states, 2097154 transitions, 0 mismatches, 79.76s, gas 370972939410. `block_gas_limit` 600000000000 is Foundry profile `invalid_floor_compositions` only. The default profile does not set it. A re-run on that profile passed 2 tests and 0 failed with the same counts in 79.63s. Supply 2 pays 0 then 1 on each side. The per-call sequence 0 then 0 is the Python counterexample. PRED-MATH-1 stays partial. The kernel stays a research candidate. Log: `evidence/research/prediction/invalid-floor-compositions-2026-09-26.json`.

## Decimals

`compare_scales(48)` checked collateral-native cumulative half against a convert-back from scales `10^6`, `10^12`, and `10^18`. Mismatches: 0. Classification: EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN for that grid. Matching decimals is still the recommendation because the 1:1 winner path should be an integer identity with one rounding boundary, not because the grid found a solvent mismatch. ADR-P02.

Phase 1 should approve one collateral and copy its decimals onto the outcome tokens. The kernel does that.

# Exact Kuru first-seed price-continuity bound — 2026-09-29

**Status:** `PROVEN_UNDER_ASSUMPTIONS` for the algebraic candidate; `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN` for the named small integer domain; **not** an accepted RetroPick price-error policy. Baseline `e662c21ad162bce5307e8f3ce5b5cf4bacbf55d8`. No production Solidity or Kuru transaction changed.

Let `T > 0` be the terminal tracked launch-token balance, `P > 0` phantom quote, `Q > 0` physically secured quote, `D=P+Q`, and `B=floor(TQ/D)`. Require `B>0`, all inputs within uint256, and `D≤uint256.max`; separate Kuru vault-size, LP-liquidity, price-numerator, token semantics, and external-deployment conditions still apply. The proposed seed places `B` base and `Q` quote into the first Kuru vault deposit, with `T−B` base outside that vault.

By definition of floor, `BD ≤ TQ < (B+1)D`. Write `e=TQ−BD`; then `0≤e<D`. The exact raw seed/reference price ratio is

```text
(Q/B) / (D/T) = TQ/(BD) = 1 + e/(BD) < 1 + 1/B.
```

The seed price cannot be below the terminal curve reference; its **relative upward** error is exactly `e/(BD)` and strictly less than `1/B`. No floating-point or probabilistic assumption is involved. If `e=0`, the exact prices match.

For the vault's 1e18-scaled first ask, set `N=10^baseDecimals × 10^18`, `s=10^quoteDecimals`, `A=floor(QN/(Bs))`, and terminal scaled reference `C=floor(DN/(Ts))`. The Kuru first-deposit expression's nested integer divisions equal `A`. Since the exact seed price is at least the reference, `A≥C`. Also:

```text
0 ≤ A−C ≤ ceil(DN/(TsB)).
```

This is a conservative absolute bound in the vault's scaled price units. It is **not** a decision that this deviation is economically acceptable. A future accepted policy must specify its maximum relative/absolute price error and minimum seed/liquidity class; `B=0`, zero first ask, zero order sizes, insufficient LP shares, or overflow must remain unseedable.

`research/integration/kuru/launchpad_seed_model.py` now exposes the exact error numerator/denominator and scaled upper bound. `test_launchpad_seed_model.py` verifies the floor relation and bound for **14,096** admissible `(T,P,Q)` tuples in `T∈[2,25]`, `P,Q∈[1,25]`, `B>0`, plus representative 6- and 18-decimal quote cases and uint256 input/sum negatives. This finite enumeration corroborates the proof only within its named domain. Command: `python3 -m unittest discover -s research/integration/kuru -p 'test_launchpad_seed_model.py' -v` — 9 tests pass. Model SHA-256 `c33a0c970d36eab441f2e3ccd3366e135311826c3ef8916fe139606fb382fafb`; test SHA-256 `df2cd767e233aa8053a032546e49a6f574bcfd023f1259ba445a60600d03ab58`.

The model mirrors the previously pinned Kuru vault first-deposit arithmetic at public contracts commit `2060bb2736080c175d80d568bfdb6226bb5abd04`. It does not prove that a live Kuru market accepts an entire parameter tuple or that a future upgraded vault retains this formula. `KURU_TARGET_FROZEN` remains **BLOCKED** on accepted parameter classes, quote policy, LP custody, atomic retry, external identity revalidation and fork/live checks.

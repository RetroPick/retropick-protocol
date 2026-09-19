# PRISM Fixed-Point Precision Model

**Status:** MATH-1D EXECUTABLE CANDIDATE  
**Semantic oracle:** exact `fractions.Fraction` model  
**Integer oracle:** `research/prism-model/fixed_point_model.py`  
**Production Solidity:** still requires CONTRACT-ARCH-1 differential fixtures and implementation review

The exact model uses rational numbers. Solidity will use integers. The purpose of this document is to define the accepted Phase-1 candidate conversion/rounding semantics that preserve solvency when moving from the rational oracle to an integer implementation.

---

## 1. Representation

Series quantity and replication weights use:

```text
WAD = 1e18
```

Example:

```text
0.6 -> 600000000000000000
0.4 -> 400000000000000000
```

Phase-1 component and settlement assets are restricted by the reference model to ERC-20 decimal counts:

```text
0 <= decimals <= 18
```

A raw token unit with `d` decimals maps to internal normalized units with exact factor:

```math
factor(d)=10^{18-d}
```

```math
normalized = raw \times factor(d)
```

This makes 6-, 8-, and 18-decimal assets exactly representable in the normalized domain without division during inbound normalization.

Assets with more than 18 decimals require a new adapter/ADR because normalization would otherwise discard precision.

---

## 2. Conservative backing requirement

For series quantity `Q`, weight `x_i` in WAD, and component decimal factor `f_i`, the minimum raw component requirement is:

```math
requiredRaw_i(S)=\left\lceil\frac{S\,x_i}{WAD\,f_i}\right\rceil
```

Therefore normalized physical backing satisfies the exact economic requirement from above, never below it.

Mint is valid only if post-mint backing satisfies the requirement for the **new total supply**, not merely a rounded per-call estimate.

For a minimum-backing mint, deposit:

```math
requiredRaw_i(S+Q)-requiredRaw_i(S)
```

then increase supply.

---

## 3. In-kind redemption rule

The previous provisional wording `floor(Q*x_i)` is superseded by a stronger state-based rule.

For redemption quantity `Q`, compute:

```math
release_i = requiredRaw_i(S)-requiredRaw_i(S-Q)
```

Then:
1. decrease liability from `S` to `S-Q`;
2. release exactly `release_i` raw units;
3. assert remaining backing is at least `requiredRaw_i(S-Q)`.

This rule directly transfers the backing invariant into integer arithmetic and avoids cumulative underbacking caused by independently rounding each redemption quantity.

If backing contains surplus above the conservative requirement, that surplus is not silently distributed by this formula. It remains explicitly accounted surplus.

---

## 4. Rounding-dust policy

For a series that only uses `mint_with_minimum_backing()` and requirement-delta redemption:

```text
backing_raw == requiredBackingRaw(currentSupply)
```

after every successful operation.

Therefore a complete mint/redeem cycle cannot create component-token value from rounding, and when supply returns to zero the minimum-backing path has zero component dust.

Any externally donated/excess backing remains surplus rather than being reclassified as rounding entitlement.

Dust/surplus may not be swept while series supply is nonzero.

---

## 5. Binary terminal-solvency transfer

Phase-1 primitive outcome components resolve to binary payout bits `0` or `1`.

For winning-bit vector `z_i in {0,1}`:

```math
BackingValue = \sum_i z_i\,normalize(backingRaw_i)
```

and WAD payout per PRISM share is:

```math
h_{wad}=\sum_i z_i x_i
```

Conservative normalized liability is:

```math
Liability=\left\lceil\frac{S\,h_{wad}}{WAD}\right\rceil
```

Because each component backing requirement is rounded upward independently, the normalized backing of winning components is at least the corresponding exact replicated liability contribution. The integer oracle checks this relation for every canonical `pFEDBTC` terminal state.

Non-binary component payoff adapters require a separate precision proof before admission.

---

## 6. Final settlement rounding

For final payout `R_wad` and settlement token decimal factor `f_s`, aggregate required settlement is:

```math
requiredSettlementRaw(S)=
\left\lceil\frac{S\,R_{wad}}{WAD\,f_s}\right\rceil
```

`REDEEMABLE` remains forbidden below that balance.

The current candidate per-redemption payment rounds user payout down:

```math
payoutRaw(Q)=
\left\lfloor\frac{Q\,R_{wad}}{WAD\,f_s}\right\rfloor
```

and re-checks that the remaining raw balance still satisfies the conservative aggregate requirement for remaining supply.

This is solvency-safe. It may leave residual settlement dust after the final redemption. Such dust is not sweepable while supply remains and must have an explicit final zero-supply disposition in CONTRACT-ARCH-1.

---

## 7. Executable evidence

Current integer oracle:

```text
research/prism-model/fixed_point_model.py
```

Current tests cover:
- 18-decimal series units;
- mixed 18/6-decimal component backing;
- conservative raw requirement calculation;
- integer mint and redemption preservation;
- all four canonical `pFEDBTC` binary terminal states;
- randomized mint/redeem sequences;
- no dust sweep with live liability;
- underfunded final settlement rejection;
- final-settlement funding preservation after redemption.

`research/prism-model/adversarial.py` adds deterministic stress runs over fixed-point backing and global reservation state.

---

## 8. Remaining production-equivalence work

Before Solidity production authorization:
- generate machine-readable Python fixtures for Solidity differential tests;
- test 6/8/18-decimal combinations explicitly in CI;
- test maximum configured supply/weight bounds against uint256 arithmetic;
- choose final settlement-dust recipient/policy;
- encode the accepted integer formulas with full-precision `mulDiv` semantics;
- run Foundry stateful invariants against the same fixtures;
- verify Solidity and Python agree on every boundary case.

These are implementation-equivalence tasks. They do not reopen the exact rational economic model unless a counterexample appears.

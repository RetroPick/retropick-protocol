# PRISM Fixed-Point Precision Model

**Status:** REQUIRED FOR MATH-1D, NOT YET FINAL  
**Semantic oracle:** exact `fractions.Fraction` reference model.

The exact mathematical model uses rational numbers. Solidity will use integers. This document defines the questions that must be closed before contract implementation.

---

## 1. Objectives

The fixed-point system must guarantee:
- no underbacking caused by rounding;
- no repeatable positive-value extraction beyond the accepted bound;
- deterministic mint/redeem fixtures;
- clear dust ownership;
- safe maximum values;
- reproducibility across Python/Solidity.

---

## 2. Candidate representation

Candidate baseline:

```text
UNIT = 1e18
```

Represent each `x_i` as integer fixed-point units.

Example:

```text
0.6 -> 600000000000000000
0.4 -> 400000000000000000
```

This is a candidate, not final acceptance.

---

## 3. Backing requirement rounding

For mint quantity `Q`, required backing must not round down below the economic obligation.

Preferred semantic rule:

```math
required_i = ceil(Q * x_i)
```

in the component token's normalized accounting units when exact divisibility is unavailable.

Any implementation that rounds backing down must prove it cannot create `B_i < S*x_i` in normalized exact semantics.

---

## 4. In-kind redemption rounding

Redemption cannot release more component value than the burned liability frees.

Candidate semantic rule:
- burn liability first;
- compute releasable component amount using a conservative floor;
- accumulate or explicitly account for residual dust.

The exact policy must ensure repeated micro-redemptions cannot extract more than a one-shot redemption.

---

## 5. Final payout rounding

For fixed final payout `R`, user payment should be deterministic and documented.

Need to define:
- payout scale;
- multiplication order;
- floor/ceil direction;
- residual settlement dust;
- final zero-supply sweep policy.

Final sweep must not permit admin extraction while user liability remains.

---

## 6. Decimal normalization

Source components may have different ERC-20 decimals.

CONTRACT-ARCH-1 must choose either:
1. normalize all accounting to an internal common unit with safe conversion; or
2. store per-component native-unit `unitsPerShare` and never assume equal decimals.

No code may multiply raw amounts from different decimal domains without explicit normalization.

---

## 7. Adversarial tests

MATH-1D must test:
- smallest nonzero mint;
- smallest nonzero redeem;
- many micro-mints then one redeem;
- one mint then many micro-redeems;
- alternating mint/redeem loops;
- weights near zero;
- weights near maximum supported bound;
- components with 6/8/18 decimals;
- maximum supply/value bounds;
- terminal payout fractions not exactly representable in component decimals.

For each sequence compare:

```text
exact Fraction entitlement
vs
integer implementation entitlement
```

and measure signed error.

---

## 8. Acceptance metrics

Define:

```math
error = integer_value - exact_value
```

Required before Solidity:
- maximum per-operation absolute error;
- maximum cumulative error over declared sequence length;
- proof/test that backing error never becomes negative beyond allowed safety margin;
- proof/test that attacker cannot turn rounding into positive expected extraction.

---

## 9. Fixture format

Generate machine-readable fixtures containing:

```json
{
  "scale": "1000000000000000000",
  "supply_before": "...",
  "quantity": "...",
  "weights": ["..."],
  "required_backing": ["..."],
  "rounding": "CEIL_BACKING",
  "expected_supply_after": "..."
}
```

Solidity differential tests must consume the same semantics.

---

## 10. Gate

MATH-1D cannot pass until one fixed-point policy is selected and the exact/integer differential suite demonstrates a bounded, non-exploitable error model.

# 05 — Backing and Solvency Proofs

**Status:** CANONICAL MATH-1 PROOF DOCUMENT  
**Scope:** exact rational Phase-1 model  
**Related:** `01_DEFINITIONS.md`, `02_ASSUMPTIONS.md`, `16_INVARIANTS.md`, `17_THEOREMS.md`

This document extracts the core solvency derivations from the protocol model into explicit theorem statements with assumptions, proof, implementation consequence and failure boundary.

---

## 1. Base invariant

For one activated PRISM series, let:

- `S` be outstanding PRISM supply;
- `x_i >= 0` be required component units per PRISM share;
- `B_i` be series-scoped reserved backing of component `i`.

The runtime backing invariant is:

```math
\boxed{B_i\ge Sx_i\qquad\forall i}
```

Define backing margin:

```math
M_i=B_i-Sx_i
```

Then the invariant is equivalent to:

```math
M_i\ge0\qquad\forall i
```

The exact-math proofs below assume the canonical assumptions listed in `02_ASSUMPTIONS.md`.

---

## 2. T-BS-001 — Valid mint preserves component backing

### Statement

If the backing invariant holds before mint and mint quantity `Q>0` is supported by exact incremental backing `Qx_i` for every component, then the invariant holds after mint.

### Preconditions

```math
B_i\ge Sx_i\qquad\forall i
```

and proposed mint:

```math
Q>0
```

with backing change:

```math
\Delta B_i=Qx_i
```

### State transition

```math
S'=S+Q
```

```math
B_i'=B_i+Qx_i
```

### Proof

From:

```math
B_i\ge Sx_i
```

add `Qx_i` to both sides:

```math
B_i+Qx_i\ge Sx_i+Qx_i
```

therefore:

```math
B_i'\ge(S+Q)x_i=S'x_i
```

for every component.

Hence:

```math
\boxed{B_i'\ge S'x_i\qquad\forall i}
```

### Margin preservation

```math
M_i' = B_i' - S'x_i
```

```math
=(B_i+Qx_i)-(S+Q)x_i
```

```math
=B_i-Sx_i=M_i
```

Therefore:

```math
\boxed{M_i'=M_i}
```

An exact-backed mint cannot consume existing backing margin.

### Status

`PROVEN_UNDER_ASSUMPTIONS`

### Oracle mapping

- `PrismSeries.required_backing()`
- `PrismSeries.assert_component_backed()`
- `PrismSeries.mint()`
- `PrismSeries.mint_with_exact_backing()`
- `verify_mint_redeem_grid()`

### Contract consequence

Production mint must finalize liability increase only after post-mint reserved backing satisfies the encoded equivalent of:

```math
B_i'\ge(S+Q)x_i
```

for every component.

---

## 3. T-BS-002 — In-kind redemption preserves component backing

### Statement

If the backing invariant holds before redemption and `0<Q<=S`, burning `Q` liability and releasing exactly `Qx_i` of each component preserves the invariant for the remaining supply.

### State transition

```math
S'=S-Q
```

```math
B_i'=B_i-Qx_i
```

### Proof

Starting from:

```math
B_i\ge Sx_i
```

subtract `Qx_i` from both sides:

```math
B_i-Qx_i\ge Sx_i-Qx_i
```

so:

```math
B_i'\ge(S-Q)x_i=S'x_i
```

Therefore:

```math
\boxed{B_i'\ge S'x_i\qquad\forall i}
```

and:

```math
M_i'=M_i
```

under exact arithmetic.

### Status

`PROVEN_UNDER_ASSUMPTIONS`

### Oracle mapping

- `PrismSeries.redeem_in_kind()`
- `PrismSeries.assert_component_backed()`
- `verify_mint_redeem_grid()`

### Contract consequence

The implementation must prevent backing release from exceeding the liability reduction it corresponds to. In integer arithmetic this becomes a rounding-policy problem handled by the precision model.

---

## 4. T-BS-003 — Exact component backing implies terminal solvency

### Statement

For an exact-admitted Phase-1 series with non-negative component payoffs, component-wise backing implies that the terminal value of reserved backing covers or exceeds PRISM liability in every modeled terminal world.

### Exact replication

One PRISM share has payoff:

```math
h(\omega)=\sum_i x_i g_i(\omega)
```

because:

```math
h=Gx
```

### Terminal backing value

```math
V_B(\omega)=\sum_i B_i g_i(\omega)
```

### Terminal PRISM liability

```math
L_P(\omega)=S h(\omega)
```

thus:

```math
L_P(\omega)=S\sum_i x_i g_i(\omega)
```

### Proof

For every component:

```math
B_i\ge Sx_i
```

and by assumption:

```math
g_i(\omega)\ge0
```

so multiplying preserves the inequality:

```math
B_i g_i(\omega)\ge Sx_i g_i(\omega)
```

Summing over all components:

```math
\sum_iB_i g_i(\omega)
\ge
S\sum_i x_i g_i(\omega)
```

therefore:

```math
\boxed{V_B(\omega)\ge L_P(\omega)\qquad\forall\omega\in\Omega}
```

### Status

`PROVEN_UNDER_ASSUMPTIONS`

### Oracle mapping

- `replication.payoff()`
- `settlement.terminal_backing_value()`
- `PrismSeries.terminal_solvency()`
- `verify_terminal_solvency_grid()`

### Architectural consequence

The Phase-1 runtime contract does **not** need to enumerate every terminal world during every mint.

The design separates:

```text
series admission
  prove/commit h = Gx

runtime
  enforce B_i >= S*x_i

proof consequence
  terminal solvency follows
```

This is both simpler and cheaper than world-state iteration inside Solidity.

---

## 5. T-BS-004 — Funded final redemption preserves settlement funding

### Statement

Once final payout `R` is fixed, if settlement assets cover all outstanding liability before a final redemption, then a correct redemption preserves sufficient funding for the remaining supply.

### Preconditions

```math
C_s\ge SR
```

and:

```math
0<Q\le S
```

### Final redemption

Burn:

```math
Q
```

PRISM and pay:

```math
QR
```

settlement units.

New state:

```math
S'=S-Q
```

```math
C_s'=C_s-QR
```

### Proof

Starting from:

```math
C_s\ge SR
```

subtract `QR` from both sides:

```math
C_s-QR\ge SR-QR
```

hence:

```math
C_s'\ge(S-Q)R=S'R
```

Therefore:

```math
\boxed{C_s'\ge S'R}
```

### Status

`PROVEN_UNDER_ASSUMPTIONS`

### Oracle mapping

- `settlement.terminal_liability()`
- `settlement.settlement_is_funded()`
- `PrismSeries.make_redeemable()`
- `PrismSeries.redeem_final()`
- `verify_settlement_redemption_grid()`

### Lifecycle consequence

`RESOLVED` and `REDEEMABLE` cannot be synonyms.

```text
RESOLVED
  final payout R known

REDEEMABLE
  R known
  AND C_s >= S*R
```

---

## 6. Exact-replication boundary

The solvency theorem proves obligations created by exact non-negative replication:

```math
h=Gx,\qquad x\ge0
```

It does not prove safety for:

```math
Gx\approx h
```

unless a residual-error/liability model is introduced and separately proven.

Phase 1 therefore rejects non-exact target payoffs rather than issuing a knowingly mismatched claim.

---

## 7. Non-negative-payoff boundary

The step:

```math
B_i\ge Sx_i
```

implies:

```math
B_i g_i(\omega)\ge Sx_i g_i(\omega)
```

only because:

```math
g_i(\omega)\ge0
```

The current theorem does not automatically cover:

- negative-liability components;
- short positions represented as negative quantities;
- leveraged unbounded claims;
- arbitrary derivative bytecode.

Those require a different solvency model.

---

## 8. No-double-allocation boundary

The algebra assumes `B_i` is backing truly reserved for the series.

If the same economic units are simultaneously counted as backing for two independent liabilities, both series can satisfy local arithmetic while the system is globally insolvent.

Therefore `A-P03` / `INV-P07` is a necessary accounting premise.

The current Python oracle models one series at a time and does **not yet** prove cross-series reservation uniqueness. That remains an explicit MATH-1/CONTRACT-ARCH gap.

---

## 9. Precision boundary

All proofs above are exact rational statements.

Production integer arithmetic must map them conservatively.

Candidate policy currently being evaluated:

```text
backing requirement -> round UP
releasable backing  -> round DOWN
```

Before production claims inherit these theorems, MATH-1D must establish:

- component-decimal normalization;
- no underbacking from rounding;
- bounded dust;
- no repeatable positive-value extraction;
- deterministic Solidity-compatible fixtures.

Until then, theorem status applies to the exact mathematical model, not yet to deployed Solidity.

---

## 10. pFEDBTC proof fixture

Canonical series:

```math
pFEDBTC=0.6\,FED\_YES+0.4\,BTC\_NO
```

with terminal payoff vector:

```math
h=(0.4,0,1,0.6)
```

For:

```math
S=1000
```

exact backing is:

```text
600 FED_YES
400 BTC_NO
```

In terminal world `Fed=YES, BTC=NO`, backing value is:

```math
600(1)+400(1)=1000
```

and liability is:

```math
1000(1)=1000
```

In terminal world `Fed=NO, BTC=YES`, both backing components pay zero and PRISM liability is also zero.

The oracle should preserve this fixture as a regression test because it previously exposed a narrative payoff error in historical research.

---

## 11. Proof/implementation traceability summary

| Proof | Protocol invariant | Python oracle | Future Solidity requirement |
|---|---|---|---|
| `T-BS-001` mint preservation | `INV-P03`, `INV-P04` | `PrismSeries.mint`, `assert_component_backed`, bounded verifier | Back-first mint and post-mint backing assertion |
| `T-BS-002` redeem preservation | `INV-P03`, `INV-P05` | `redeem_in_kind`, bounded verifier | Burn/decrease liability before proportional release |
| `T-BS-003` terminal solvency | `INV-P01`, `INV-P03`, `INV-P06` | `payoff`, `terminal_solvency`, terminal bounded verifier | Admission commits exact replication; runtime enforces component backing |
| `T-BS-004` settlement preservation | `INV-P09`, `INV-P10` | `make_redeemable`, `redeem_final`, settlement bounded verifier | Funding gate before redeemable; deterministic payout/burn |

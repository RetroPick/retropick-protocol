# 05 — Backing and Solvency Proofs

**Status:** CANONICAL MATH-1 PROOF DOCUMENT  
**Scope:** exact rational Phase-1 model plus accepted integer-transfer lemmas  
**Related:** `01_DEFINITIONS.md`, `02_ASSUMPTIONS.md`, `16_INVARIANTS.md`, `17_THEOREMS.md`

---

## 1. Base invariant

For one activated PRISM series:

```math
\boxed{B_i\ge Sx_i\qquad\forall i}
```

with backing margin:

```math
M_i=B_i-Sx_i\ge0.
```

---

## 2. T-BS-001 — Valid mint preserves component backing

For exact mint quantity `Q>0`:

```math
S'=S+Q,
\qquad
B_i'=B_i+Qx_i.
```

From `B_i>=Sx_i`:

```math
B_i+Qx_i\ge(S+Q)x_i,
```

so:

```math
\boxed{B_i'\ge S'x_i}.
```

Moreover:

```math
M_i'=(B_i+Qx_i)-(S+Q)x_i=M_i.
```

**Status:** `PROVEN_UNDER_ASSUMPTIONS`.

**Oracle:** `PrismSeries.mint()`, `mint_with_exact_backing()`, `verify_mint_redeem_grid()`.

---

## 3. T-BS-002 — In-kind redemption preserves component backing

For `0<Q<=S`:

```math
S'=S-Q,
\qquad
B_i'=B_i-Qx_i.
```

From `B_i>=Sx_i`:

```math
B_i-Qx_i\ge(S-Q)x_i,
```

therefore:

```math
\boxed{B_i'\ge S'x_i}
```

and `M_i'=M_i` in exact arithmetic.

**Status:** `PROVEN_UNDER_ASSUMPTIONS`.

**Oracle:** `PrismSeries.redeem_in_kind()`, bounded verifier.

---

## 4. T-BS-003 — Exact component backing implies terminal solvency

Exact replication:

```math
h(\omega)=\sum_i x_i g_i(\omega).
```

Backing value:

```math
V_B(\omega)=\sum_i B_i g_i(\omega).
```

Liability:

```math
L_P(\omega)=S h(\omega).
```

Because `B_i>=Sx_i` and `g_i(omega)>=0`:

```math
B_i g_i(\omega)\ge Sx_i g_i(\omega).
```

Summing:

```math
\boxed{V_B(\omega)\ge L_P(\omega)\qquad\forall\omega\in\Omega}.
```

**Status:** `PROVEN_UNDER_ASSUMPTIONS`.

**Oracle:** `replication.payoff()`, `PrismSeries.terminal_solvency()`, `verify_terminal_solvency_grid()`.

**Architecture consequence:** admission proves/commits `h=Gx`; runtime only needs the component invariant. Solidity does not enumerate terminal worlds during mint.

---

## 5. T-BS-004 — Funded final redemption preserves settlement funding

If:

```math
C_s\ge SR
```

and redeeming `Q` pays `QR`, then:

```math
S'=S-Q,
\qquad
C_s'=C_s-QR.
```

Therefore:

```math
C_s-QR\ge SR-QR=(S-Q)R
```

and:

```math
\boxed{C_s'\ge S'R}.
```

**Status:** `PROVEN_UNDER_ASSUMPTIONS`.

**Oracle:** `settlement_is_funded()`, `make_redeemable()`, `redeem_final()`, settlement bounded verifier.

---

## 6. T-ALLOC-001 — Global reservation uniqueness is inductive

A local series can be solvent while the whole system is insolvent if the same physical units are counted twice. Define for asset `a`:

```math
PhysicalBalance_a=P_a
```

and series reservations:

```math
R_{s,a}\ge0.
```

Global reservation invariant:

```math
\boxed{\sum_s R_{s,a}\le P_a}.
```

The reference transition system permits:

### Deposit

`P_a` increases; reservations do not. The inequality remains true.

### Reserve

A new reservation `q` is accepted only when:

```math
q\le P_a-\sum_sR_{s,a}.
```

After reservation:

```math
\sum_sR'_{s,a}=\sum_sR_{s,a}+q\le P_a.
```

### Release

Reservations decrease, so the invariant is preserved.

### Withdraw

Withdrawal `q` is accepted only when:

```math
q\le P_a-\sum_sR_{s,a}.
```

Hence after `P_a'=P_a-q`:

```math
\sum_sR_{s,a}\le P_a'.
```

Therefore the invariant is inductive under every accepted ledger transition.

**Status:** `PROVEN_UNDER_ASSUMPTIONS` for the reference transition system.

**Oracle:** `reservation_ledger.ReservationLedger`.

**Production consequence:** the contract architecture needs one authoritative reservation domain or equivalent vault partitioning so cross-series liabilities cannot alias the same units.

---

## 7. T-PARTIAL-002 — Finalized component-to-cash transformation preserves value on the conditioned state space

Suppose component `i` becomes canonically final with payout:

```math
r_i.
```

Condition the remaining terminal worlds to:

```math
\Omega' = \{\omega\in\Omega\mid g_i(\omega)=r_i\}.
```

Before transformation, component `i` contributes to backing value in every `omega in Omega'`:

```math
B_i g_i(\omega)=B_i r_i.
```

Replace the entire component balance by settlement cash:

```math
C_i=B_i r_i
```

and set component balance to zero.

After transformation, contribution is exactly:

```math
C_i=B_i r_i.
```

Thus for every remaining feasible terminal world:

```math
\boxed{V'_B(\omega)=V_B(\omega)\qquad\forall\omega\in\Omega'}.
```

If the pre-transform portfolio covered liability in every `omega in Omega'`, the transformed portfolio does too.

For mixed in-kind redemption after transformation, liability reduction `Q` releases:

```math
Qx_j
```

for unresolved components and:

```math
Q\sum_{i\in R}x_i r_i
```

of transformed settlement backing. The same backing-preservation argument as T-BS-002 applies component-wise to the mixed representation.

**Status:** `PROVEN_UNDER_ASSUMPTIONS`.

**Oracle:** `PrismSeries.resolve_component()`, `possible_states`, `transformed_settlement`, `redeem_in_kind_mixed()`, conditioned `terminal_solvency()`.

**Phase-1 policy:** first payoff-relevant component resolution pauses new minting; later mint-after-partial-resolution is not part of the current kernel.

---

## 8. Fixed-point transfer lemmas

The exact theorems do not automatically transfer to Solidity integers. The accepted candidate model uses WAD series units and component decimal factor:

```math
f_i=10^{18-d_i},\qquad 0\le d_i\le18.
```

Minimum raw backing requirement is:

```math
Req_i(S)=\left\lceil\frac{Sx_i}{WAD\,f_i}\right\rceil.
```

### T-FP-001 — Conservative integer mint cannot underreserve

Mint is accepted only when raw backing after deposit is at least `Req_i(S+Q)` for every component. Therefore normalized backing is never below the exact economic requirement represented by the candidate domain.

**Status:** `PROVEN_UNDER_ASSUMPTIONS` for the candidate integer model; Solidity equivalence still pending.

### T-FP-002 — Requirement-delta redemption preserves integer backing

Release:

```math
Release_i=Req_i(S)-Req_i(S-Q).
```

If backing before redemption is at least `Req_i(S)`, then after release:

```math
B_i'\ge Req_i(S)-Release_i=Req_i(S-Q).
```

Therefore remaining supply stays conservatively backed.

**Status:** `PROVEN_UNDER_ASSUMPTIONS` for the candidate integer model.

### T-FP-003 — Conservative settlement funding survives rounded redemption

Aggregate raw settlement requirement is:

```math
Req_s(S)=\left\lceil\frac{SR}{WAD\,f_s}\right\rceil.
```

The candidate redemption pays a floor-rounded amount and then requires the remaining balance to remain at least `Req_s(S-Q)`. The executable model rejects any transition that would violate this condition.

**Status:** `PROVEN_UNDER_ASSUMPTIONS` for accepted transitions in the candidate model; production Solidity differential proof pending.

### T-FP-004 — Minimum-backing mint/redeem cycle cannot create component value

A minimum-backing mint deposits:

```math
Req_i(S+Q)-Req_i(S).
```

Redeeming the same liability change releases the exact reverse requirement delta. Therefore, absent external surplus, a closed mint/redeem cycle has zero net component extraction.

**Status:** `PROVEN_UNDER_ASSUMPTIONS` for the requirement-delta policy; randomized stress remains supporting evidence rather than the proof itself.

---

## 9. Boundaries

These proofs do not cover:
- approximate replication `Gx≈h`;
- negative component payoffs or negative quantities;
- leveraged/unbounded liabilities;
- fee-on-transfer/rebasing components without an adapter proof;
- assets with more than 18 decimals under the current candidate normalizer;
- cross-chain custody/bridge semantics;
- market liquidity, arbitrage participation, market-maker profitability or demand.

---

## 10. Canonical pFEDBTC regression fixture

```math
pFEDBTC=0.6\,FED\_YES+0.4\,BTC\_NO
```

with payoff vector:

```math
h=(0.4,0,1,0.6).
```

For `S=1000`, exact backing is:

```text
600 FED_YES
400 BTC_NO
```

The `Fed=YES, BTC=NO` world pays `1.00` and is retained as a regression fixture because it previously exposed a narrative math error.

---

## 11. Traceability

| Proof | Invariants | Exact oracle | Integer/stateful oracle |
|---|---|---|---|
| `T-BS-001` | `INV-P03/P04` | `PrismSeries.mint` | `FixedPointSeries.mint` |
| `T-BS-002` | `INV-P03/P05` | `redeem_in_kind` | `FixedPointSeries.redeem` |
| `T-BS-003` | `INV-P01/P03/P06` | `terminal_solvency` | `terminal_solvency_binary` |
| `T-BS-004` | `INV-P09/P10` | `make_redeemable/redeem_final` | `FixedPointSettlement` |
| `T-ALLOC-001` | `INV-P07` | n/a | `ReservationLedger` |
| `T-PARTIAL-002` | `INV-P08` | `resolve_component`, `redeem_in_kind_mixed` | fixed-point partial transform not yet implemented |
| `T-FP-001..004` | precision transfer | exact model is comparison oracle | `fixed_point_model.py` |

# 01 — Definitions and Notation

**Status:** CANONICAL MATH-1 DEFINITIONS  
**Scope:** RetroPick native binary complete sets + PRISM Phase-1 exact-backed series

This document assigns one meaning to every symbol used by the proof layer. Proofs must not silently overload notation.

---

## 1. Terminal state space

Let the finite set of modeled terminal worlds be:

```math
\Omega=\{\omega_1,\ldots,\omega_m\}
```

A terminal world is the complete set of payoff-relevant facts needed to evaluate every admitted component in a PRISM series.

`m` is the number of terminal worlds in the canonical payoff representation.

---

## 2. Component assets

Let:

```math
A_i
```

be supported component asset `i`, for `i in {1,...,n}`.

Its terminal payoff function is:

```math
g_i:\Omega\rightarrow\mathbb R_{\ge0}
```

Phase 1 requires non-negative terminal payoff values.

The payoff matrix is:

```math
G_{\omega i}=g_i(\omega)
```

or explicitly:

```math
G=
\begin{bmatrix}
g_1(\omega_1)&\cdots&g_n(\omega_1)\\
\vdots&&\vdots\\
g_1(\omega_m)&\cdots&g_n(\omega_m)
\end{bmatrix}
```

`G` has shape `m x n`.

---

## 3. PRISM replication vector

A Phase-1 PRISM series has immutable replication vector:

```math
x=(x_1,\ldots,x_n),\qquad x_i\ge0
```

`x_i` is the normalized quantity of component `A_i` required to back one whole PRISM share in the exact mathematical model.

One PRISM share corresponds economically to:

```math
x_1A_1+\cdots+x_nA_n
```

Its terminal payoff vector is:

```math
h=Gx
```

and state-by-state:

```math
h(\omega)=\sum_i x_i g_i(\omega)
```

The feasible long-only payoff cone is:

```math
\mathcal C=\{Gx\mid x\ge0\}
```

A desired payoff `h*` is Phase-1-replicable only if there exists exact `x>=0` satisfying:

```math
Gx=h^*
```

in the accepted deterministic numeric domain.

---

## 4. Supply and backing

Let:

```math
S\ge0
```

be total outstanding PRISM supply for one series generation.

Let:

```math
B_i\ge0
```

be the quantity of component `i` reserved/accounted as backing for that same series generation.

`B_i` means **series-scoped reserved backing**, not merely the raw token balance at some address.

Required backing for component `i` is:

```math
Req_i(S)=Sx_i
```

Backing margin is:

```math
M_i=B_i-Sx_i
```

The canonical component-backing invariant is:

```math
B_i\ge Sx_i\qquad\forall i
```

or equivalently:

```math
M_i\ge0\qquad\forall i
```

---

## 5. Mint quantity and redemption quantity

Let:

```math
Q>0
```

be an operation quantity.

For mint:

```math
S'=S+Q
```

with exact required incremental backing:

```math
\Delta B_i=Qx_i
```

in the exact rational model.

For in-kind redemption where `Q<=S`:

```math
S'=S-Q
```

with proportional component release:

```math
\Delta B_i=-Qx_i
```

in the exact rational model.

Integer/fixed-point implementations use the accepted rounding policy rather than raw real arithmetic.

---

## 6. Terminal backing value and liability

Terminal value of reserved backing in state `omega`:

```math
V_B(\omega)=\sum_i B_i g_i(\omega)
```

PRISM terminal liability in state `omega`:

```math
L_P(\omega)=S h(\omega)
```

Terminal solvency means:

```math
V_B(\omega)\ge L_P(\omega)
```

for every modeled terminal state.

---

## 7. Final payout and settlement balance

After all payoff-relevant inputs are final, let:

```math
\omega^*
```

be the canonical terminal world and define final payout per PRISM share:

```math
R=h(\omega^*)
```

Let:

```math
C_s\ge0
```

be spendable settlement collateral available to the final redemption path.

The final funding condition is:

```math
C_s\ge SR
```

`RESOLVED` means `R` is canonically fixed.

`REDEEMABLE` means `R` is fixed **and** the funding condition holds in the accepted integer precision model.

---

## 8. Native binary complete set

For a normalized fully collateralized binary market, let:

```math
S_Y
```

be YES supply,

```math
S_N
```

be NO supply, and

```math
C_{locked}
```

be locked collateral backing the complete sets.

Canonical pre-resolution conservation is:

```math
S_Y=S_N=C_{locked}
```

for the simple Phase-1 complete-set model.

For every valid terminal world:

```math
YES(\omega)+NO(\omega)=1
```

in normalized settlement units.

Economic open interest for this simple complete-set model is:

```math
OI=S_Y=S_N=C_{locked}
```

not `S_Y+S_N`.

---

## 9. Partial resolution notation

Let `Rset` be the index set of resolved components and `Uset` the unresolved set.

For resolved component `i`, let:

```math
r_i
```

be its canonical terminal payout.

For unresolved component `j`, let:

```math
P_j(t)
```

be an externally supplied valuation mark at time `t`.

A mark for the remaining basket is:

```math
NAV_t=\sum_{i\in Rset}x_i r_i+\sum_{j\in Uset}x_jP_j(t)
```

This is a valuation identity conditional on the supplied marks, not an exchange-price guarantee.

---

## 10. Executable create/redeem values

Let:

```math
Ask_i
```

and:

```math
Bid_i
```

be executable component prices for the relevant quantity.

Creation cost reference:

```math
C_{create}=\sum_i x_iAsk_i+F_{create}
```

In-kind redemption liquidation value:

```math
V_{redeem}=\sum_i x_iBid_i-F_{redeem}
```

These are market-reference quantities. They do not alter backing or terminal payoff semantics.

---

## 11. Accounting-domain vocabulary

These domains are distinct and may not silently reuse the same units:

```text
series backing
settlement funds
Kuru LP inventory
market-maker inventory
protocol fees
creator/treasury funds
```

A raw wallet/token balance is not automatically economically available to every domain.

---

## 12. Exact versus implementation arithmetic

The mathematical oracle uses exact rational arithmetic.

Future Solidity uses integer fixed-point arithmetic.

Therefore distinguish:

```text
exact requirement     S*x_i
integer requirement   conservative encoded approximation
exact payout          Q*R
integer payout        deterministic encoded approximation
```

The fixed-point policy must prove that implementation rounding cannot create underbacking or repeatable positive-value extraction beyond the accepted bound.

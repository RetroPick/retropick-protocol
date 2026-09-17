# PRISM Protocol Specification — Phase 1

**Status:** Phase-1 canonical draft  
**Scope:** exact-backed long-only replicated structured outcome assets  
**Production Solidity:** NOT AUTHORIZED until MATH-1

## 1. Purpose

PRISM creates a transferable structured asset whose terminal payoff is exactly replicated by a locked basket of supported outcome assets.

Phase 1 intentionally solves a narrower problem than arbitrary programmable derivatives: if a requested payoff cannot be exactly replicated by supported non-negative components, the series is rejected.

## 2. Mathematical objects

Terminal states:

\[
\Omega=\{\omega_1,\ldots,\omega_m\}
\]

Component payoff:

\[
g_i:\Omega\rightarrow\mathbb R_{\ge0}
\]

Payoff matrix:

\[
G_{\omega i}=g_i(\omega)
\]

Replication vector:

\[
x=(x_1,\ldots,x_n),\qquad x_i\ge0
\]

PRISM payoff:

\[
\boxed{h=Gx}
\]

Feasible payoff cone:

\[
\boxed{\mathcal C=\{Gx\mid x\ge0\}}
\]

A requested payoff `h*` is admissible only when an accepted exact solution exists:

\[
Gx=h^*,\quad x\ge0
\]

within the protocol's deterministic fixed-point representation.

## 3. Series immutables

A series definition eventually maps to:

- `seriesId`
- component identifiers/addresses;
- units per share `x_i`;
- `replicationHash`;
- settlement asset;
- maturity/resolution references;
- rounding/precision domain;
- lifecycle rules.

The replication definition cannot change after activation.

## 4. Active backing

For outstanding supply `S` and vault balance `B_i`:

\[
\boxed{B_i\ge Sx_i\quad\forall i}
\]

Backing allocated to one series cannot simultaneously back another liability unless an explicitly proven shared-collateral model replaces this spec in a future version.

## 5. Mint

For mint quantity `Q`:

1. validate series `ACTIVE`;
2. compute exact required backing `Q*x_i`;
3. ensure/deposit backing;
4. update accounting;
5. only then increase PRISM supply.

After mint:

\[
S'=S+Q,\qquad B_i'=B_i+Qx_i
\]

## 6. Pre-resolution in-kind redemption

For `0 <= Q <= S`:

1. burn `Q` PRISM;
2. decrease supply;
3. release `Q*x_i` component units.

\[
S'=S-Q,\qquad B_i'=B_i-Qx_i
\]

This preserves the component backing invariant.

## 7. Terminal solvency

Terminal backing value:

\[
V_B(\omega)=\sum_i B_i g_i(\omega)
\]

PRISM liability:

\[
L_P(\omega)=S h(\omega)
\]

Given non-negative component payoffs and component backing:

\[
\boxed{V_B(\omega)\ge L_P(\omega)\quad\forall\omega}
\]

## 8. Partial resolution

A partially resolved series remains economically live if at least one payoff-relevant component remains uncertain.

For resolved set `R` and unresolved set `U`:

\[
NAV_t=\sum_{i\in R}x_i r_i+\sum_{j\in U}x_j P_j(t)
\]

This NAV expression is a valuation identity under the supplied component marks, not a guarantee that a secondary exchange trades exactly at NAV.

## 9. Final resolution and settlement

When all payoff-relevant components are final:

\[
R=h(\omega^*)
\]

The series may become `RESOLVED`, but may enter `REDEEMABLE` only after:

\[
SettlementVaultBalance\ge OutstandingSupply\times R
\]

Final redemption burns PRISM and transfers the deterministic settlement amount.

## 10. Secondary trading

Transferability may remain before and after resolution.

Before final resolution the asset contains event uncertainty.

After final resolution it behaves approximately as a fixed redemption claim. Against quote token `Q`:

\[
P_{PRISM/Q}\approx\frac{R}{P_{Q/USD}}
\]

subject to settlement delay, fees, liquidity and residual risk.

This is an economic relation, not a protocol-enforced exchange price.

## 11. Market-price/NAV thesis

Define executable creation cost `C` and executable redemption value `R_d`.

Idealized arbitrage suggests a no-arbitrage region:

\[
R_d\le P_{market}\le C
\]

under instantaneous, sufficiently liquid and reliable execution.

Real markets require risk/latency terms. Price convergence is a simulation/live-evidence claim, not a formal invariant.

## 12. Non-goals

Phase 1 does not claim:

- every desired payoff is replicable;
- arbitrary AND/OR products can be synthesized from marginal claims;
- bridge attestations equal trustless custody;
- liquidity appears merely because an ERC-20 pair is deployed;
- simulation proves demand.

## 13. MATH-1 gate

Production smart-contract implementation begins only after the canonical model and tests establish:
- backing preservation;
- redemption conservation;
- terminal solvency;
- lifecycle safety;
- settlement funding safety;
- deterministic precision bounds;
- known failure boundaries.

# Canonical Invariants

## INV-01 Component backing

For every active series and component:

\[
B_i\ge Sx_i
\]

## INV-02 Back-first mint

Supply may not increase before all required component backing has been allocated.

## INV-03 In-kind conservation

Burning `Q` pre-resolution shares releases exactly the protocol-representable amount corresponding to `Q*x_i` and may not leave remaining supply underbacked.

## INV-04 Terminal solvency

For every modeled terminal state:

\[
V_B(\omega)\ge L_P(\omega)
\]

## INV-05 Settlement funding

`REDEEMABLE` implies:

\[
SettlementBalance\ge OutstandingSupply\times FinalPayout
\]

within defined integer precision.

## INV-06 No double-use backing

The same backing unit cannot simultaneously satisfy two independent reserved liabilities.

## INV-07 Immutable replication

`x`, component identity and replication hash do not mutate after activation.

## INV-08 Lifecycle monotonicity

Terminal states cannot transition back into issuance states.

## INV-09 Resolution once

Final resolution may be committed once for a series generation.

## INV-10 Accounting-domain separation

```text
Backing collateral != LP inventory != protocol fees
```

## INV-11 Scientific classification

Market convergence, market-maker profitability and demand are never promoted to formal invariants.

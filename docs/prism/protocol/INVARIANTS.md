# Canonical Protocol Invariants

**Status:** CANONICAL  
**Scope:** RetroPick native binary markets + PRISM Phase 1

Every contract architecture, reference-model action, invariant test and later Solidity implementation must preserve the applicable invariants below.

---

## Native market invariants

### INV-N01 Complete-set issuance

For collateral amount `C` split into a binary market:

```math
\Delta YES = C
```

```math
\Delta NO = C
```

```math
\Delta CollateralLocked = C
```

No valid split may mint only one side.

### INV-N02 Complete-set merge conservation

Before final resolution, burning equal quantities `Q` of complementary YES and NO claims releases exactly the corresponding collateral amount, subject only to explicitly defined fees/precision rules.

### INV-N03 Complementary terminal payoff

For every valid terminal world:

```math
YES(\omega)+NO(\omega)=1
```

in settlement units.

### INV-N04 Binary-market open interest

Under valid complete-set accounting:

```math
OI=YES_{supply}=NO_{supply}=CollateralLocked
```

before terminal redemption effects.

`YES_supply + NO_supply` is not the canonical OI metric because it double-counts one complete set.

### INV-N05 Resolution immutability

A native market's activated `ResolutionSpec` cannot be changed after users can acquire claims.

Final outcome may be committed only according to the accepted resolution path and cannot be overwritten after finalization.

---

## PRISM invariants

### INV-P01 Exact admitted replication

Every activated Phase-1 PRISM series has a canonical non-negative replication vector `x` such that:

```math
h=Gx
```

in the accepted deterministic numeric domain.

A target payoff without an exact admissible solution is rejected.

### INV-P02 Immutable replication

After activation, the following may not mutate:

- component identity;
- units per share `x_i`;
- replication hash;
- settlement asset semantics;
- resolution references that determine payoff.

### INV-P03 Component backing

For every active series and component:

```math
\boxed{B_i\ge Sx_i}
```

where `B_i` is the series-scoped backing allocation and `S` is outstanding PRISM supply.

### INV-P04 Back-first mint

Supply may increase only after all post-mint component requirements are satisfied.

For proposed mint `Q`:

```math
B_i'\ge(S+Q)x_i \qquad \forall i
```

must hold before the liability increase is finalized.

### INV-P05 In-kind redemption conservation

Burning `Q` PRISM before final settlement releases no more than the deterministic basket entitlement:

```math
Qx_i
```

for each component, and may not leave the remaining supply underbacked.

### INV-P06 Terminal solvency

For every modeled terminal state:

```math
\boxed{V_B(\omega)\ge L_P(\omega)}
```

where:

```math
V_B(\omega)=\sum_iB_i g_i(\omega)
```

and:

```math
L_P(\omega)=S h(\omega)
```

### INV-P07 No double allocation

The same reserved backing units cannot simultaneously satisfy two independent liabilities.

This does **not** prohibit the same token address from being used as a component in multiple PRISM series.

### INV-P08 Partial-resolution equivalence

Replacing a canonically resolved component with settlement cash or another representation is permitted only when the transformation preserves the remaining payoff obligation under the accepted numeric rules.

Partial transformation may not mint or silently extinguish PRISM liability.

### INV-P09 Settlement funding

`REDEEMABLE` implies:

```math
\boxed{SettlementBalance\ge OutstandingSupply\times FinalPayout}
```

within the fixed-point tolerance accepted by MATH-1E.

### INV-P10 Final redemption conservation

Burning `Q` PRISM in `REDEEMABLE` transfers no more and no less than the accepted deterministic entitlement:

```math
Q\times FinalPayout
```

within the fixed-point tolerance.

### INV-P11 Lifecycle monotonicity

No terminal or settlement state may transition back into an issuance state.

Examples forbidden:

```text
RESOLVED -> ACTIVE
REDEEMABLE -> ACTIVE
ARCHIVED -> anything economically live
```

### INV-P12 Resolution once

Final PRISM resolution may be committed once per series generation and may not be mutated after commitment.

### INV-P13 Accounting-domain separation

```text
PRISM backing
!= Kuru LP inventory
!= market-maker inventory
!= protocol fee balances
```

The same units may not be counted simultaneously in multiple liability domains.

### INV-P14 No state-space runtime dependency

For an exact-admitted Phase-1 series, Solidity runtime solvency relies on component backing `B_i >= Sx_i`; it must not depend on enumerating every terminal world during each mint.

The statewise solvency relation remains a proof property, not a gas-sensitive runtime loop.

---

## Market/economic classification invariants

### INV-M01 Scientific classification

The repository must never describe the following as formally proven merely because accounting is safe:

- market-price convergence;
- market-maker profitability;
- user demand;
- exchange depth;
- arbitrage speed;
- sponsor-integration availability.

They are simulation/live-evidence claims.

### INV-M02 Executable-side parity

Complete-set arbitrage analysis must distinguish bids from asks.

Split-and-sell condition:

```math
Bid_Y+Bid_N>1+costs
```

Buy-and-merge condition:

```math
Ask_Y+Ask_N<1-costs
```

A simple displayed `YES + NO ~= 1` is descriptive, not an executable arbitrage proof.

### INV-M03 Retail trade / primary creation separation

A normal secondary BUY transfers existing PRISM supply through an exchange and does not modify protocol backing.

A primary CREATE changes supply and therefore must satisfy all mint/backing invariants.

---

## Cross-chain future-phase invariant namespace

Cross-chain/wrapped outcome invariants are intentionally excluded from Phase 1.

A later phase must separately define and prove at minimum:

```math
WrappedSupply\le LockedUnderlying
```

plus replay protection and burn-before-unlock semantics before such assets can become canonical PRISM components.

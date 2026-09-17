# Validation Test Plan

**Status:** CANONICAL VALIDATION PLAN  
**Current phase:** MATH-1 reference model.

The validation stack is layered. Passing a higher layer never excuses failure in a lower layer.

---

## Layer 1 — deterministic unit tests

Required now in `research/prism-model/`.

### Payoff/replication
- exact `h=Gx`;
- dimension validation;
- non-negative component/payoff requirements;
- exact replication found when available;
- known AND counterexample rejected.

### Backing/mint/redeem
- exact-backed mint;
- underbacked mint rejection;
- pre-resolution proportional release;
- backing invariant after operations;
- zero/negative/oversized quantities rejected.

### Lifecycle
- only legal transitions;
- no resurrection from terminal states;
- no mint outside ACTIVE;
- no final redemption before REDEEMABLE.

### Settlement
- terminal payout selection;
- underfunded `REDEEMABLE` rejected;
- final redemption preserves funding for remaining supply;
- archive requires zero outstanding liability.

### Complete-set/market math
- `YES_supply == NO_supply == collateral_locked` in the simple canonical model;
- OI is not `YES+NO`;
- split-and-sell uses bids;
- buy-and-merge uses asks;
- PRISM creation cost uses asks;
- PRISM in-kind liquidation value uses bids;
- partial-resolution NAV partition is complete/disjoint;
- resolved PRISM/quote ratio reacts to quote-token price.

---

## Layer 2 — deterministic scenario fixtures

At minimum:

### Native binary
```text
100 collateral
-> 100 YES + 100 NO
-> trade
-> merge subset
-> resolve
-> redeem winner
```

### pFEDBTC

```math
x=(0.6,0.4)
```

verify all four terminal states:

```text
Fed No / BTC No   -> 0.40
Fed No / BTC Yes  -> 0.00
Fed Yes / BTC No  -> 1.00
Fed Yes / BTC Yes -> 0.60
```

### Partial resolution

Resolved 0.6 leg = 1, remaining 0.4 leg mark = 0.30:

```math
NAV=0.6+0.4(0.3)=0.72
```

### Post-resolution quote pair

```text
R = 0.60 USD
MON = 2 USD -> 0.30 MON
MON = 1 USD -> 0.60 MON
```

---

## Layer 3 — bounded exhaustive state exploration

Enumerate small integer/rational domains such as:
- supply 0..N;
- backing 0..M;
- supported small weights;
- legal lifecycle transitions;
- mint/redeem quantities;
- terminal states.

For every reachable valid state assert:

```math
B_i >= Sx_i
```

and, after final funding:

```math
SettlementBalance >= Supply*FinalPayout
```

Record the minimal action sequence for any counterexample.

---

## Layer 4 — adversarial/property sequences

Generate action sequences including:
- deposit;
- mint;
- transfer abstraction;
- redeem;
- pause;
- start resolution;
- resolve;
- fund settlement;
- final redeem;
- archive.

Attempt:
- over-mint;
- over-redemption;
- duplicate resolution;
- mint-after-resolution;
- invalid backing release;
- underfunded finalization;
- illegal lifecycle jumps;
- duplicated component indices;
- zero/extreme weights;
- transform before canonical resolution.

Passing random tests is evidence, not a universal proof.

---

## Layer 5 — precision/fixed-point tests

Before Solidity:
- translate exact fixtures into chosen integer scale;
- test ceil/floor rules;
- quantify per-operation dust;
- repeat mint/redeem cycles adversarially;
- search for positive-value rounding extraction;
- test maximum supported values for overflow safety assumptions.

A fixed-point policy that can underback remaining supply fails the gate.

---

## Layer 6 — formal assistance

Where useful, encode theorem obligations with Z3/SymPy or equivalent:
- mint preservation;
- redemption preservation;
- final-settlement preservation;
- finite lifecycle reachability;
- fixed-point inequalities for bounded domains.

Tool output must specify exact assumptions/domain.

---

## Layer 7 — Solidity validation

Starts after CONTRACT-ARCH-1.

Required:
- Foundry unit tests;
- fuzz tests;
- stateful invariant tests;
- reentrancy tests;
- authorization tests;
- event reconstruction tests;
- differential tests against Python fixtures.

Primary invariants:

```text
INV-01 component backing
INV-02 back-first mint
INV-03 redemption conservation
INV-04 terminal solvency
INV-05 settlement funding
INV-06 no double-use backing
INV-07 immutable replication
INV-08 lifecycle monotonicity
INV-09 resolution once
```

---

## Layer 8 — integration/e2e validation

Verify real external behavior separately:
- Kuru market deploy/trade/depth;
- Envio indexed events/queries;
- CRE resolution transaction;
- account/funding integrations;
- frontend state reconciliation.

An integration screenshot is not protocol accounting evidence unless balances/transactions can be reconciled.

---

## Evidence policy

Each gate should save:
- command;
- commit SHA;
- deterministic seed/domain where relevant;
- stdout/stderr;
- pass/fail counts;
- counterexample if any;
- artifact hash if used in submission.

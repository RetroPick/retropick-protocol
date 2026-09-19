# Smart Contract Architecture

**Status:** TARGET DESIGN, NOT YET IMPLEMENTATION AUTHORIZATION  
**Gate:** production Solidity begins only after `MATH-1` and `CONTRACT-ARCH-1`.

This document defines the minimal contract responsibilities implied by the canonical protocol model. It intentionally excludes speculative cross-chain or generic derivative machinery.

---

## 1. Native RetroPick contracts

### `PredictionMarketFactory`

Creates/registers native binary markets from a validated market definition and immutable resolution specification.

Must not invoke the PRISM spanning engine.

### `PredictionMarket`

Owns market lifecycle metadata and links to:
- collateral asset;
- YES token;
- NO token;
- resolution specification/registry;
- complete-set vault.

### `OutcomeToken`

ERC-20 representation of YES or NO exposure.

Mint/burn authority belongs to protocol issuance/redemption logic, not arbitrary admins.

### `CompleteSetVault`

Canonical binary issuance primitive:

```text
split(C):
C collateral -> C YES + C NO

merge(C):
C YES + C NO -> C collateral
```

After final native resolution, winning outcome redemption must be backed by collateral held/released according to the market rules.

### `ResolutionRegistry` / resolution module

Commits the canonical outcome under immutable `ResolutionSpec` semantics.

CRE may orchestrate data retrieval and transaction submission, but the resolution contract remains the onchain commitment point.

---

## 2. PRISM contracts

### `PrismSeriesFactory`

Creates a new structured ERC-20 series from a previously validated immutable definition.

Expected definition fields:
- `seriesId`;
- components;
- units per share `x_i`;
- replication/payoff commitment;
- settlement asset;
- maturity and mint cutoff;
- source-resolution references;
- numeric/precision version.

Factory creation starts with `totalSupply = 0`.

### `PrismSeriesERC20`

Fungible transferable claim for one immutable structured series.

It must not independently expose unrestricted mint/burn methods to users/admins.

### `PrismBackingVault`

Holds/account for the exact component assets reserved for one or more series.

Phase-1 preference:
- aggregate series-scoped accounting;
- component balances keyed by `seriesId` and token;
- no per-mint provenance lot unless a concrete requirement needs it.

Canonical condition:

```math
B_i >= Sx_i
```

### `PrismMintController`

Only component authorized to cause PRISM supply expansion.

Semantics:

```text
calculate requirements
-> receive/allocate backing
-> verify all component requirements
-> reserve backing
-> mint
```

It MUST NOT:
- rely on BackingMirror in Phase 1;
- enumerate all terminal worlds every mint;
- use spot price as a solvency input;
- mint from partially acquired baskets.

### `PrismRedemptionRouter`

Handles pre-resolution in-kind redemption and routing into final settlement.

Pre-resolution:

```text
burn Q
-> release Q*x_i components
```

Final:

```text
burn Q
-> pay Q*R settlement
```

### `PrismSettlementEngine`

Coordinates payoff-equivalent transformation of resolved backing and final settlement funding.

It may mark a series `REDEEMABLE` only after:

```math
SettlementBalance >= Supply * FinalPayout
```

---

## 3. Contracts explicitly deferred

Do not build these into the Metropolis kernel without a new ADR:

- `BackingMirror` for same-chain collateral;
- bridge custody/wrapper contracts;
- Polygon/Polymarket custody adapters;
- generic StatePool/SLE;
- arbitrary payoff bytecode interpreters;
- onchain LP/market-maker logic that duplicates Kuru;
- price-oracle-based mint collateralization.

---

## 4. Lifecycle

Canonical series lifecycle:

```text
DRAFT
-> ACTIVE
-> MINT_PAUSED
-> RESOLUTION_PENDING
-> RESOLVED
-> REDEEMABLE
-> ARCHIVED
```

`RESOLVED` means payout known.

`REDEEMABLE` means payout funded.

No transition returns to an earlier economic state.

---

## 5. Suggested authorization model

Exact implementation awaits CONTRACT-ARCH-1, but authority must be narrow.

Potential roles:

```text
FACTORY_ADMIN
  may configure creation policy, not mutate activated economics

MINT_CONTROLLER
  may mint only after invariant checks

RESOLVER
  may commit result only under ResolutionSpec

PAUSER
  may stop new risk creation, not seize backing or rewrite payout
```

No role should be able to mint arbitrary unbacked supply.

---

## 6. Event model

Minimum event surface should make Envio/evidence reconstruction possible:

```text
MarketCreated
CompleteSetSplit
CompleteSetMerged
MarketResolutionPending
MarketResolved
OutcomeRedeemed

SeriesCreated
BackingDeposited
BackingReleased
SeriesMinted
SeriesBurned
SeriesStateChanged
BackingTransformed
SeriesResolved
SettlementFunded
FinalRedeemed
```

Exact event schemas are finalized in CONTRACT-ARCH-1.

---

## 7. Testing obligations before deployment

Solidity implementation is accepted only when it passes:
- unit tests;
- Foundry fuzz tests;
- Foundry stateful invariants;
- differential fixtures versus `research/prism-model/`;
- lifecycle mutation tests;
- rounding/dust attack tests;
- reentrancy tests;
- authorization tests;
- final-settlement solvency tests.

The contract suite is an implementation of the model, not the definition of the model.

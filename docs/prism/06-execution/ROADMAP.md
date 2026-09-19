# RetroPick Protocol Roadmap

**Status:** CANONICAL EXECUTION ORDER  
**Rule:** phases are dependency gates, not calendar weeks.

The previous report described W0-W12 as a 12-week sprint. That sequencing is superseded. Metropolis execution uses gated phases plus parallel integration waves where safe.

---

## P0 — Repository and evidence baseline

Goal:
- establish repo governance;
- freeze source-of-truth hierarchy;
- capture external bounty/integration evidence separately from protocol truth.

Required:
- `AGENTS.md`;
- `.agent/*`;
- docs taxonomy;
- evidence directories;
- reconciliation of historical architecture report.

Exit:
- agents know which documents are canonical;
- rejected/deferred architecture cannot silently re-enter implementation.

Status: substantially complete.

---

## P1 — SPEC

Goal:
freeze the financial objects and lifecycle before implementation.

Canonical outputs:
- `PRISM_PROTOCOL_SPEC.md`;
- `STATE_MACHINE.md`;
- `INVARIANTS.md`;
- `FAILURE_MODES.md`;
- native-market/PRISM separation;
- canonical `pFEDBTC` example.

Required decisions:
- exact long-only replication only;
- Monad-native backing for hackathon;
- no Phase-1 BackingMirror;
- basket mode as default MVP;
- `RESOLVED != REDEEMABLE`;
- retail trade != primary creation.

Exit gate `SPEC-1`:
- no unresolved contradiction changes economic semantics.

Status: active/near complete.

---

## P2 — MATH-1 reference model and proof

Goal:
prove or falsify the accounting/replication kernel before Solidity.

Subphases:

### P2A Exact arithmetic kernel

Implement with Python `Fraction`:
- payoff evaluation `h=Gx`;
- exact replication solver for small systems;
- component backing;
- mint;
- in-kind redemption;
- lifecycle;
- resolution;
- settlement funding/final redemption.

### P2B Native complete-set math

Model:
- split/merge conservation;
- YES/NO supply relation;
- open interest;
- executable bid/ask parity conditions.

### P2C Market microstructure identities

Model:
- PRISM create cost;
- in-kind redeem value;
- idealized arbitrage band;
- post-resolution PRISM/ERC20 relative value;
- partial-resolution NAV.

These are market relations/hypotheses, not solvency invariants.

### P2D Exhaustive/adversarial state exploration

Test:
- over-mint attempts;
- over-redemption;
- illegal lifecycle transitions;
- double-use backing abstractions;
- duplicate resolution;
- underfunded final settlement;
- non-replicable payoffs;
- component transformation errors.

### P2E Fixed-point model

Before Solidity define:
- numeric scale;
- round direction;
- dust ownership;
- maximum cumulative leakage;
- adversarial repeated-operation tests.

### P2F Formal assistance

Use SymPy/Z3 where valuable for:
- mint preservation;
- redemption preservation;
- terminal solvency;
- settlement preservation;
- bounded integer transition properties.

Exit gate `MATH-1`:

```text
PASS
CONDITIONAL_PASS
or
FAIL
```

A protocol accounting kill criterion forces `FAIL` regardless of market simulation results.

---

## P3 — CONTRACT-ARCH-1

Starts only after MATH-1 permits it.

Goal:
derive Solidity architecture from proven semantics.

Outputs:
- contract boundaries;
- storage layout;
- interfaces;
- authorization model;
- event schemas;
- upgradeability decision;
- precision library design;
- failure/recovery behavior;
- Foundry invariant mapping.

Required architecture:

```text
Native RetroPick:
PredictionMarketFactory
PredictionMarket
CompleteSetVault
OutcomeToken
Resolution module

PRISM:
PrismSeriesFactory
PrismSeriesERC20
PrismBackingVault
PrismMintController
PrismRedemptionRouter
PrismSettlementEngine
```

Explicit Phase-1 exclusion:
- BackingMirror;
- custom external bridge;
- generic StatePool.

Exit `CONTRACT-ARCH-1`:
- every critical storage/function responsibility traces to a canonical invariant or requirement.

---

## P4 — SOLIDITY KERNEL

Goal:
implement the minimum financial kernel on Monad.

Order:
1. native complete-set issuance/merge;
2. native resolution/redemption;
3. PRISM series definition;
4. exact component backing;
5. PRISM mint;
6. in-kind redemption;
7. partial/final settlement;
8. lifecycle guards.

Testing:
- unit;
- fuzz;
- stateful invariant;
- differential against Python fixtures;
- rounding attacks;
- reentrancy;
- authorization.

Exit `CONTRACT-1`:
- all invariant and differential suites pass.

---

## P5 — EXCHANGE + DATA INTEGRATIONS

These can partially overlap once contract interfaces stabilize.

### Kuru

Prove:
- YES/quote market;
- NO/quote market;
- one PRISM/quote market;
- executable orders;
- visible depth;
- split/merge arbitrage demonstration;
- PRISM create/redeem economic demonstration where feasible.

### Envio

Index canonical contract events and Kuru-related data needed for product views.

Analytics must use corrected definitions, including complete-set open interest.

### Chainlink CRE

Use for immutable-ResolutionSpec orchestration.

Do not use CRE to mirror same-chain backing balances.

### Alchemy

RPC/WebSocket transport, not financial truth.

Exit `INTEGRATION-1`:
- onchain tx/log evidence for each claimed integration.

---

## P6 — FULLSTACK PRODUCT

Goal:
make the protocol usable without requiring a user to understand issuance mechanics.

Core UX:

```text
Browse market
-> Buy/Sell YES/NO
-> Buy/Sell PRISM
-> Portfolio
-> Resolution status
-> Redeem
```

Advanced UX:

```text
Create prediction market
Create PRISM basket
Primary create/redeem PRISM
```

Normal `BUY PRISM` must use secondary exchange liquidity when available; it must not force the user through a multi-leg component acquisition flow.

Supporting integrations:
- Mera account UX;
- Aurora Intents funding;
- Nansen intelligence if evidence/support remains valid;
- MetaMask Agent automation if P0 flows are already complete.

Exit `PRODUCT-1`:
- a new user can complete the golden path without manual protocol operations.

---

## P7 — MARKET THESIS VALIDATION

This phase does not gate accounting correctness but gates stronger economic claims.

Simulate and/or measure:
- premium/discount to NAV;
- arbitrage convergence;
- liquidity requirements;
- resolution-jump risk;
- market-maker PnL;
- stale-order losses;
- quote-asset volatility after resolution;
- user demand/behavior where real data exists.

Output classifications:

```text
SUPPORTED_BY_SIMULATION
SUPPORTED_BY_LIVE_EVIDENCE
NOT_YET_VALIDATED
COUNTEREXAMPLE_FOUND
```

Never label market adoption/liquidity as mathematically proven.

---

## P8 — GOLDEN DEMO + SUBMISSION

Required end-to-end evidence:

```text
create native market
-> split collateral
-> YES/NO exist
-> deploy/seed Kuru markets
-> execute trade
-> create exact PRISM series
-> primary mint with exact backing
-> trade PRISM on Kuru
-> partial/final resolution
-> fund settlement
-> redeem
-> show indexed evidence
```

Submission package:
- deployed addresses;
- tx hashes;
- Kuru market IDs;
- Envio queries;
- CRE logs;
- screenshots/video;
- tests;
- evidence hashes;
- architecture/invariant summary;
- explicit limitations.

---

## Post-hackathon P9+

Only after the native exact-backed system works:
- external prediction-market adapters;
- wrapped external outcomes;
- bridge/custody proof architecture;
- RFQ/CLOB enhancements;
- shared StatePool/SLE research;
- arbitrary bounded payoff claims;
- lending/collateral integrations;
- production compliance architecture.

External-market support must not be retrofitted by pretending an attestation alone is collateral.

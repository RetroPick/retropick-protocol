# Current Goal

**Goal ID:** METROPOLIS-P1-MATH-1  
**Status:** ACTIVE  
**Phase:** P1 SPEC -> P2 MATH-1  
**Primary gate:** `MATH-1`  
**Phase control:** `docs/05-hackathon/PHASE_GATES.md`

## Objective

Freeze the exact-backed PRISM and native complete-set semantics, then build enough executable/formal evidence to decide whether the accounting kernel is safe to translate into Solidity.

The reference implementation is the semantic oracle. Production Solidity is not authorized yet.

---

## Canonical architecture now locked

```text
Native RetroPick
-> ERC20 YES/NO
-> Kuru spot markets

Native outcome ERC20s
-> exact PRISM basket
-> PRISM ERC20
-> Kuru spot market
```

Admission:

```math
h=Gx
```

or solve:

```math
Gx=h, x>=0
```

Runtime backing:

```math
B_i >= Sx_i
```

Final settlement gate:

```math
SettlementBalance >= Supply * FinalPayout
```

---

## Corrected decisions

- No Phase-1 `BackingMirror` for Monad-native backing.
- No terminal-state enumeration in every mint.
- No Polymarket/cross-chain dependency in the Metropolis kernel.
- Native market creation does not use PRISM spanning.
- Basket mode is the default MVP PRISM creator flow.
- Normal retail PRISM BUY is a Kuru secondary trade.
- Primary PRISM CREATE is an issuer/AP/market-maker path.
- `RESOLVED` means payout known; `REDEEMABLE` means funded.
- `pFEDBTC = 0.6 FED_YES + 0.4 BTC_NO` pays `1.00` in the Fed=YES/BTC=NO world.
- Native complete-set OI does not equal `YES_supply + NO_supply`.

---

## Completed documentation outputs

- [x] `docs/00-context/REPORT_RECONCILIATION.md`
- [x] `docs/protocol/ASSUMPTIONS.md`
- [x] `docs/protocol/CLAIMS.md`
- [x] `docs/protocol/PRISM_PROTOCOL_SPEC.md`
- [x] `docs/protocol/INVARIANTS.md`
- [x] `docs/protocol/STATE_MACHINE.md`
- [x] `docs/protocol/MATH_MODEL.md`
- [x] `docs/protocol/PRECISION_MODEL.md`
- [x] `docs/protocol/FAILURE_MODES.md`
- [x] `docs/protocol/CONTRACT_REQUIREMENTS.md`
- [x] `docs/04-architecture/SYSTEM_ARCHITECTURE.md`
- [x] `docs/04-architecture/SMART_CONTRACTS.md`
- [x] `docs/05-hackathon/PHASE_GATES.md`
- [x] `docs/06-execution/ROADMAP.md`
- [x] ADR-003 through ADR-007 documenting the corrected architecture.

---

## Executable model status

### MATH-1A — exact arithmetic and market identities

Artifacts present:

- [x] payoff evaluation and exact replication helpers;
- [x] component backing / mint / in-kind redemption;
- [x] lifecycle and final settlement model;
- [x] complete-set conservation helper;
- [x] corrected open-interest helper;
- [x] executable split-and-sell parity helper using bids;
- [x] executable buy-and-merge parity helper using asks;
- [x] PRISM create-cost helper;
- [x] PRISM in-kind redeem-value helper;
- [x] partial-resolution NAV helper;
- [x] post-resolution PRISM/ERC20 relative-value helper.

Canonical code:

```text
research/prism-model/model.py
research/prism-model/replication.py
research/prism-model/settlement.py
research/prism-model/market_math.py
```

Status: `IMPLEMENTED_PENDING_FULL_SUITE_REVALIDATION`.

### MATH-1B — bounded exhaustive verification

Artifacts present:

- [x] bounded mint/redeem backing-preservation enumeration;
- [x] bounded terminal-solvency enumeration;
- [x] bounded settlement-redemption enumeration;
- [x] bounded verification tests.

Still required:

- [ ] exhaustive lifecycle reachability enumeration across all declared legal/illegal transitions;
- [ ] broader independent per-component surplus enumeration;
- [ ] explicit minimal counterexample serialization when a future mutation fails.

Canonical code:

```text
research/prism-model/bounded_verification.py
research/prism-model/tests/test_bounded_verification.py
```

### MATH-1C — adversarial/property testing

Still required:

- [ ] randomized action sequences;
- [ ] over-mint attempts;
- [ ] over-redemption;
- [ ] duplicate resolution;
- [ ] underfunded settlement;
- [ ] invalid backing transformation;
- [ ] action reordering;
- [ ] zero/extreme weights;
- [ ] backing double-allocation abstraction tests.

### MATH-1D — fixed-point/rounding

Candidate implementation present:

- [x] WAD-scale candidate;
- [x] ceil-on-required-backing rule;
- [x] floor-on-releasable-backing rule;
- [x] round-trip dust helper;
- [x] fixed-point tests.

Still required before acceptance:

- [ ] component-token decimal normalization policy;
- [ ] maximum cumulative dust bound across repeated operations;
- [ ] dust ownership/sweep policy;
- [ ] Solidity-compatible deterministic fixtures;
- [ ] explicit proof that chosen rounding cannot underback liabilities.

Canonical code:

```text
research/prism-model/fixed_point.py
research/prism-model/tests/test_fixed_point.py
```

### MATH-1E — theorem/formal assistance

- [ ] encode core algebra in SymPy/Z3 where useful;
- [ ] distinguish universal proof from bounded verification;
- [ ] machine-readable theorem-status output.

### MATH-1F — empirical market model

- [ ] arbitrage-band convergence simulation;
- [ ] resolution-jump/stale-order risk;
- [ ] market-maker inventory/PnL scenarios;
- [ ] liquidity-capital requirements;
- [ ] quote-asset volatility after resolution;
- [ ] explicit empirical classification of all results.

---

## Test/revalidation rule

Generated code is not marked as a passed gate merely because the files exist. The final MATH-1 verdict requires a fresh deterministic test run with captured evidence after all remaining work packages are complete.

No agent may convert `IMPLEMENTED_PENDING_FULL_SUITE_REVALIDATION` into `PASS` without actual test evidence.

---

## Acceptance

`MATH-1` may close only when:

- exact payoff evaluation is deterministic;
- admitted replication is exact in the canonical numeric domain;
- valid mint cannot underback remaining supply;
- valid in-kind redemption preserves backing;
- terminal solvency holds for all modeled terminal worlds;
- illegal lifecycle transitions fail;
- `REDEEMABLE` cannot be underfunded;
- known non-replicable payoff is rejected;
- complete-set accounting definitions are executable and tested;
- precision/rounding leakage is bounded;
- adversarial action sequences find no accounting counterexample;
- every remaining uncertainty is classified as accounting, integration, or empirical market behavior.

## Verdict format

```text
MATH-1 = PASS
```

or:

```text
MATH-1 = CONDITIONAL_PASS
```

or:

```text
MATH-1 = FAIL
```

No production Solidity before this verdict.

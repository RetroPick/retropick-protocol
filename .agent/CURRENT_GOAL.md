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

## Completed outputs

- [x] `docs/00-context/REPORT_RECONCILIATION.md`
- [x] `docs/protocol/PRISM_PROTOCOL_SPEC.md`
- [x] `docs/protocol/INVARIANTS.md`
- [x] `docs/protocol/STATE_MACHINE.md`
- [x] `docs/protocol/MATH_MODEL.md`
- [x] `docs/protocol/FAILURE_MODES.md`
- [x] `docs/protocol/CONTRACT_REQUIREMENTS.md`
- [x] `docs/04-architecture/SYSTEM_ARCHITECTURE.md`
- [x] `docs/04-architecture/SMART_CONTRACTS.md`
- [x] `docs/05-hackathon/PHASE_GATES.md`
- [x] base exact-arithmetic reference model
- [x] base unit tests for payoff/backing/lifecycle/settlement

---

## Remaining MATH-1 work

### MATH-1A — extend exact model

- [ ] executable complete-set split/merge math helpers;
- [ ] corrected open-interest helper;
- [ ] bid/ask complete-set arbitrage helper;
- [ ] PRISM create/redeem executable value helper;
- [ ] partial-resolution NAV helper;
- [ ] post-resolution ERC20/ERC20 relative-value helper.

### MATH-1B — exhaustive finite-state verification

- [ ] bounded supply/backing/action enumeration;
- [ ] lifecycle reachability enumeration;
- [ ] terminal-world solvency enumeration;
- [ ] explicit minimal counterexamples on failure.

### MATH-1C — adversarial/property testing

- [ ] over-mint sequences;
- [ ] over-redemption;
- [ ] duplicate resolution;
- [ ] underfunded settlement;
- [ ] invalid transformations;
- [ ] action reordering;
- [ ] zero/extreme weights.

### MATH-1D — fixed-point/rounding

- [ ] choose protocol scale;
- [ ] define ceil/floor policy;
- [ ] quantify dust;
- [ ] repeated extraction tests;
- [ ] emit Solidity-compatible fixtures.

### MATH-1E — proof assistance

- [ ] encode core theorems in SymPy/Z3 where useful;
- [ ] distinguish theorem proof from finite-domain checking.

### MATH-1F — market model classification

- [ ] simulate/measure arbitrage-band convergence assumptions;
- [ ] resolution-jump/stale-order risk;
- [ ] liquidity/MM assumptions;
- [ ] label results empirical, not formal.

---

## Acceptance

`MATH-1` may close only when:

- exact payoff evaluation is deterministic;
- admitted replication is exact in the canonical domain;
- valid mint cannot underback remaining supply;
- valid in-kind redemption preserves backing;
- terminal solvency holds for all modeled terminal worlds;
- illegal lifecycle transitions fail;
- `REDEEMABLE` cannot be underfunded;
- known non-replicable payoff is rejected;
- complete-set accounting definitions are executable and tested;
- precision/rounding leakage is bounded;
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

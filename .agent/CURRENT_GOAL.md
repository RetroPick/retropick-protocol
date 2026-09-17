# Current Goal

**Goal ID:** METROPOLIS-P1-MATH-1  
**Status:** ACTIVE  
**Phase:** P2 MATH-1  
**Primary gate:** `MATH-1`  
**Phase control:** `docs/05-hackathon/PHASE_GATES.md`

## Objective

Prove and falsify the RetroPick/PRISM accounting kernel deeply enough that CONTRACT-ARCH-1 can translate accepted semantics into Solidity without inventing economics during implementation.

Production Solidity is still not authorized.

---

## Canonical accounting architecture

```text
Native RetroPick complete set
-> ERC20 YES/NO
-> exact PRISM basket
-> PRISM ERC20
```

Admission:

```math
h=Gx
```

Runtime exact backing:

```math
B_i>=Sx_i
```

Global physical reservation:

```math
sum_s Reserved[s,a] <= PhysicalBalance[a]
```

Final settlement gate:

```math
SettlementBalance>=Supply*FinalPayout
```

---

## Proof layer complete

Canonical proof artifacts exist:

```text
docs/math/README.md
docs/math/01_DEFINITIONS.md
docs/math/02_ASSUMPTIONS.md
docs/math/05_BACKING_SOLVENCY.md
docs/math/16_INVARIANTS.md
docs/math/17_THEOREMS.md
```

They distinguish exact theorems, executable verification, counterexamples and empirical market hypotheses.

---

## Executable gaps resolved in the reference model

### Cross-series reservation uniqueness

Implemented:

```text
research/prism-model/reservation_ledger.py
```

The ledger enforces:

```math
sum_s Reserved[s,a] <= PhysicalBalance[a]
```

across deposit, reserve, release and withdrawal. Over-allocation and withdrawal of reserved units are rejected.

`T-ALLOC-001`: `PROVEN_UNDER_ASSUMPTIONS` for the reference transition system.

### Stateful native complete-set accounting

Implemented:

```text
research/prism-model/native_market.py
```

It models:

```text
split
merge
resolve
winning redemption
losing-claim burn
archive
```

Active invariant:

```math
YES_supply=NO_supply=CollateralLocked
```

Resolved invariant:

```math
CollateralLocked=RemainingWinningSupply
```

### Stateful partial-resolution backing transformation

`PrismSeries` now models:

```text
resolve_component()
possible_states
resolved_components
transformed_settlement
redeem_in_kind_mixed()
```

A finalized component payout conditions the terminal state space, pauses new minting and replaces component backing with equal settlement value.

`T-PARTIAL-002`: `PROVEN_UNDER_ASSUMPTIONS` in exact semantics.

### Fixed-point theorem-transfer candidate

Implemented:

```text
research/prism-model/fixed_point_model.py
```

Candidate semantics:

```text
WAD series scale
component decimals 0..18
raw backing requirement = ceil(total-supply exact requirement)
redemption release = old conservative requirement - new conservative requirement
aggregate final settlement requirement = ceil liability
rounded final redemption must preserve remaining funding
no dust/surplus sweep while live liability remains
```

Reference-model theorem status:

```text
T-FP-001 PROVEN_UNDER_ASSUMPTIONS
T-FP-002 PROVEN_UNDER_ASSUMPTIONS
T-FP-003 PROVEN_UNDER_ASSUMPTIONS for accepted transitions
T-FP-004 PROVEN_UNDER_ASSUMPTIONS for requirement-delta cycles
```

These statuses do not yet imply Solidity equivalence.

### Deterministic adversarial runners

Implemented:

```text
research/prism-model/adversarial.py
```

Current runners stress:
- randomized integer mint/redeem transitions;
- all canonical pFEDBTC terminal states after each step;
- randomized cross-series reservation/release pressure.

---

## Validation evidence from this implementation tranche

Local reconstructed regression environment used the current fetched repository baseline plus the new candidate files.

Result:

```text
python -m unittest discover -s tests -v
51 tests
OK
```

This included the existing baseline regression cases plus the new executable-gap cases.

Deterministic adversarial run:

```text
seed = 20260917
fixed-point steps = 5000
mint ops = 2961
redeem ops = 2039
terminal checks = 20000

reservation steps = 5000
reserve ops = 2800
release ops = 2196
rejected overallocations = 4
final total reserved = 9857
physical balance = 10000
```

This is recorded evidence over the declared run, not a universal proof and not CI evidence from a deployed repository runner.

---

## MATH-1 work-package status

### MATH-1A — exact accounting kernel

`IMPLEMENTED_AND_PROOF_NORMALIZED`

- [x] exact payoff / replication;
- [x] component backing;
- [x] exact mint/redeem;
- [x] lifecycle;
- [x] final settlement;
- [x] partial-resolution transformation;
- [x] native complete-set state model;
- [x] cross-series reservation ledger.

### MATH-1B — bounded/exhaustive verification

`PARTIAL`

- [x] bounded exact mint/redeem grid;
- [x] bounded terminal-solvency grid;
- [x] bounded settlement-redemption grid;
- [ ] exhaustive lifecycle reachability matrix generation;
- [ ] independent per-component surplus grid rather than shared surplus scalar;
- [ ] deterministic minimal-counterexample serialization.

### MATH-1C — adversarial/property testing

`SUBSTANTIALLY_IMPLEMENTED, NOT CLOSED`

- [x] randomized fixed-point mint/redeem sequences;
- [x] cross-series double-allocation rejection;
- [x] reserved-balance withdrawal rejection;
- [x] partial-resolution invalid-state rejection;
- [x] duplicate component resolution rejection;
- [x] underfunded final settlement rejection;
- [x] native complete-set invalid archive checks;
- [ ] broader action-reordering state machine fuzzer;
- [ ] zero/extreme-weight matrix;
- [ ] configured maximum-value/overflow boundary tests.

### MATH-1D — fixed point / rounding

`CANDIDATE SEMANTICS SELECTED AND EXECUTABLE`

- [x] WAD representation;
- [x] deterministic decimal normalization for `0..18` decimals;
- [x] conservative backing requirement;
- [x] requirement-delta redemption;
- [x] binary terminal-solvency checker;
- [x] final-settlement funding model;
- [x] no live-liability dust sweep;
- [x] algebraic transfer lemmas documented;
- [ ] explicit 6/8/18-decimal CI matrix;
- [ ] configured uint256 maximum tests;
- [ ] final zero-supply settlement-dust disposition;
- [ ] machine-readable Solidity differential fixtures.

### MATH-1E — formal assistance / machine-readable theorem evidence

`DOCUMENTED, TOOLING PENDING`

- [x] definitions;
- [x] assumptions/dependencies;
- [x] theorem proofs;
- [x] invariant-to-oracle mapping;
- [x] theorem registry;
- [ ] SymPy/Z3 encoding where it materially improves assurance;
- [ ] machine-readable theorem-status output.

### MATH-1F — empirical market model

`NOT STARTED`

Still separate from accounting safety:
- arbitrage convergence;
- resolution-jump/stale-order risk;
- market-maker inventory/PnL;
- liquidity capital;
- quote-asset volatility;
- live demand.

---

## Remaining hard blockers before CONTRACT-ARCH-1

The exact solvency kernel is no longer missing a model for the previously identified core gaps. Remaining hard blockers are implementation-equivalence and boundary-validation work:

1. machine-readable Python fixtures for future Solidity differential tests;
2. 6/8/18-decimal and maximum configured arithmetic test matrix;
3. explicit zero-supply settlement-dust policy;
4. broader adversarial action-ordering/overflow search;
5. fresh full-suite run from canonical repository/CI state with captured evidence;
6. final MATH-1 verdict.

Formal-tool work is useful but must not become ceremony; use Z3/SymPy where it proves something not already trivial algebra.

---

## Gate rule

`MATH-1` remains open.

Valid final verdicts:

```text
MATH-1 = PASS
MATH-1 = CONDITIONAL_PASS
MATH-1 = FAIL
```

No production Solidity before that verdict and subsequent `CONTRACT-ARCH-1`.

# PRISM Exact Reference Model

This directory is the **semantic reference implementation** for RetroPick/PRISM MATH-1.

It is deliberately split into two layers:

```text
ACCOUNTING / SOLVENCY KERNEL
  exact payoff + backing + lifecycle + settlement

MARKET MATH
  complete-set parity + executable NAV relations + quote-pair identities
```

Market math must not be confused with protocol safety.

The model is intentionally not:
- a smart contract;
- a bridge;
- a production service;
- evidence of guaranteed liquidity;
- evidence of future demand.

It uses `fractions.Fraction` so Phase-1 semantics can be checked without floating-point error.

---

## Proof-layer relationship

Repository authority is:

```text
docs/protocol/
  protocol/economic semantics
      ↓
docs/math/
  definitions, assumptions, proofs, theorem/invariant traceability
      ↓
research/prism-model/
  executable semantic oracle
      ↓
contracts/
  future implementation
```

Canonical math documents:

- `../../docs/math/01_DEFINITIONS.md`
- `../../docs/math/02_ASSUMPTIONS.md`
- `../../docs/math/05_BACKING_SOLVENCY.md`
- `../../docs/math/16_INVARIANTS.md`
- `../../docs/math/17_THEOREMS.md`

Formal claim status lives in `docs/math/17_THEOREMS.md`. Detailed protocol semantics remain in `docs/protocol/`.

---

## Files

- `model.py`: PRISM series state, backing, supply, mint/redeem and final settlement.
- `lifecycle.py`: legal PRISM state transitions.
- `replication.py`: payoff matrices, exact payoff construction and small-system replication solver.
- `settlement.py`: terminal backing/settlement helpers.
- `market_math.py`: complete-set accounting, bid/ask parity, PRISM create/redeem values, partial-resolution NAV and post-resolution quote ratio.
- `bounded_verification.py`: finite-domain mint/redeem/solvency/settlement checks.
- `fixed_point.py`: candidate conservative integer/fixed-point helpers; not yet production-proven.
- `scenarios.py`: deterministic human-readable examples.
- `tests/`: unit/counterexample tests.

---

## Canonical equations

Admission:

```math
h=Gx
```

or solve target payoff:

```math
Gx=h^*,\quad x\ge0
```

Runtime backing:

```math
B_i\ge Sx_i
```

Final funding:

```math
SettlementBalance\ge Supply\times FinalPayout
```

Native complete-set conservation:

```math
YES_{supply}=NO_{supply}=CollateralLocked
```

in the simple fully collateralized Phase-1 model.

---

## Run

```bash
python -m unittest discover -s tests -v
python scenarios.py
```

A bounded verification run must record its input bounds before its result is classified as `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN`.

---

## Scientific classification

Passing tests is evidence, not automatically a universal proof.

Canonical status language:

```text
PROVEN_UNDER_ASSUMPTIONS
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
SUPPORTED_BY_SIMULATION
SUPPORTED_BY_LIVE_EVIDENCE
NOT_YET_VALIDATED
COUNTEREXAMPLE_FOUND
```

`docs/math/17_THEOREMS.md` is the claim registry. It explicitly separates:

- exact mathematical theorems;
- finite-domain executable verification;
- known counterexamples;
- implementation-equivalence gaps;
- empirical market hypotheses.

---

## Current oracle coverage

Strong current coverage:

```text
exact payoff h=Gx
non-negative exact replication
component backing
back-first mint
in-kind redemption
terminal solvency evaluation
PRISM lifecycle monotonicity
final settlement funding/redemption
complete-set static accounting helpers
executable bid/ask reference math
```

Explicit gaps tracked in `docs/math/16_INVARIANTS.md` include:

```text
stateful native split/merge model
global cross-series backing reservation uniqueness
stateful partial-resolution backing transformation
production fixed-point theorem transfer
live Kuru/accounting-domain separation
```

Do not treat those gaps as implemented merely because the protocol docs describe the desired behavior.

---

## Important scope boundary

`market_math.py` computes exact economic reference quantities from supplied prices. It does not assume real traders will instantly arbitrage toward those quantities.

For example:

```math
Bid_Y+Bid_N>1+cost
```

creates a split-and-sell incentive if executable depth exists. It does not force the live orderbook to obey equality at every moment.

The accounting/solvency kernel must remain correct even if:

```text
Kuru liquidity = 0
arbitrage participation = 0
market maker offline
secondary price materially wrong
```

Market behavior cannot be a hidden premise of solvency.

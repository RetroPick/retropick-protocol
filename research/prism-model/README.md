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

## Files

- `model.py`: PRISM series state, backing, supply, mint/redeem and final settlement.
- `lifecycle.py`: legal PRISM state transitions.
- `replication.py`: payoff matrices, exact payoff construction and small-system replication solver.
- `settlement.py`: terminal backing/settlement helpers.
- `market_math.py`: complete-set accounting, bid/ask parity, PRISM create/redeem values, partial-resolution NAV and post-resolution quote ratio.
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

Later MATH-1 work will add bounded state exploration, adversarial/property sequences and fixed-point fixtures.

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

Formal theorem status lives in `docs/protocol/MATH_MODEL.md`.

---

## Important scope boundary

`market_math.py` computes exact economic reference quantities from supplied prices. It does not assume real traders will instantly arbitrage toward those quantities.

For example:

```math
Bid_Y+Bid_N>1+cost
```

creates a split-and-sell incentive if executable depth exists. It does not force the live orderbook to obey equality at every moment.

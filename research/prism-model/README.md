# PRISM Exact Reference Model

This is the **semantic reference implementation** for Phase 1.

It is intentionally not:
- an exchange simulator;
- a smart contract;
- a bridge;
- a production service.

It uses `fractions.Fraction` so the accounting kernel can be checked without floating-point error.

## Files

- `model.py`: series/backing/supply state and mint/redeem rules.
- `lifecycle.py`: legal state transitions.
- `replication.py`: payoff matrices, exact replication and feasibility helpers.
- `settlement.py`: terminal payoff/settlement funding/redemption helpers.
- `scenarios.py`: deterministic human-readable examples.
- `tests/`: unit and counterexample tests.

## Run

```bash
python -m unittest discover -s tests -v
python scenarios.py
```

## MATH-1 principle

Tests can disprove a claim. Passing tests do not by themselves constitute a universal mathematical proof; theorem status is documented separately in the canonical math specification.

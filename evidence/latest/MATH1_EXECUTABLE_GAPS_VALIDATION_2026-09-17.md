# MATH-1 Executable Gap Validation — 2026-09-17

**Scope:** reference-model tranche resolving previously explicit executable gaps.  
**Classification:** bounded/regression/adversarial executable evidence, not a substitute for universal proofs or future Solidity differential tests.

## Implemented artifacts

```text
research/prism-model/reservation_ledger.py
research/prism-model/native_market.py
research/prism-model/fixed_point_model.py
research/prism-model/adversarial.py
research/prism-model/model.py   # partial-resolution transformation extension
research/prism-model/tests/test_executable_gaps.py
```

## Properties exercised

- cross-series physical backing cannot be double reserved;
- reserved backing cannot be withdrawn;
- released reservations restore capacity;
- stateful native split/merge conservation;
- final native outcome cannot be resolved twice through the state path;
- winning redemption reduces collateral one-for-one;
- losing claims burn for zero;
- partial PRISM component resolution conditions remaining terminal worlds;
- resolved component backing transforms to equal settlement value;
- new mint pauses after payoff-relevant partial resolution;
- mixed unresolved-component + settlement redemption preserves backing;
- final terminal state must remain consistent with already resolved components;
- raw backing normalization works for mixed 18/6-decimal components;
- integer backing requirement uses conservative ceil semantics;
- requirement-delta redemption preserves remaining integer backing;
- all four canonical `pFEDBTC` binary terminal states remain solvent in the integer oracle;
- final fixed-point settlement cannot become redeemable while underfunded;
- rounded final redemption preserves the conservative funding requirement for remaining supply;
- dust/surplus cannot be swept while live liability remains.

## Regression run

A local validation workspace was reconstructed from the currently fetched repository baseline and the candidate changes.

Command:

```bash
python -m unittest discover -s tests -v
```

Result:

```text
Ran 51 tests
OK
```

The run included reconstructed existing baseline tests plus `test_executable_gaps.py`.

## Deterministic adversarial run

Command:

```bash
python adversarial.py
```

Result:

```json
{
  "fixed_point": {
    "mint_ops": 2961,
    "redeem_ops": 2039,
    "seed": 20260917,
    "steps": 5000,
    "terminal_checks": 20000
  },
  "reservation": {
    "balance": 10000,
    "rejected_overallocations": 4,
    "release_ops": 2196,
    "reserve_ops": 2800,
    "seed": 20260917,
    "steps": 5000,
    "total_reserved": 9857
  }
}
```

No accounting counterexample occurred in the declared deterministic run.

## Scientific interpretation

The algebraic proofs live in `docs/prism/math/05_BACKING_SOLVENCY.md` and the theorem registry in `docs/prism/math/17_THEOREMS.md`.

This evidence supports executable consistency of the Python reference model over the exercised cases. It does **not** prove:

- future Solidity implementation equivalence;
- uint256 overflow safety outside configured bounds;
- Kuru liquidity or price convergence;
- market-maker profitability;
- user demand;
- cross-chain wrapper safety.

## Remaining MATH-1 blockers

```text
machine-readable Solidity differential fixtures
explicit 6/8/18 decimal CI matrix
configured maximum/overflow tests
zero-supply final settlement dust policy
broader action-ordering adversarial search
fresh canonical repository/CI full-suite evidence
final MATH-1 verdict
```

# PRISM reproduction report

**HEAD measured:** `73d5f1e72b65cc5cdad0d940782c192aa331f5ed` for the pre-existing suite, then this branch for `math1_probe.py`  
**Python:** 3.12.3  
**Dependencies of the oracle:** standard library only  
**Extra tools used for new probes:** SymPy 1.14.0, Z3 5.1.0 (installed in this workspace; not pinned in the repo)  
**Date:** 2026-09-26

Classifications: REPRODUCED, NOT_REPRODUCED, STALE, CONTRADICTED, BLOCKED.

## Commands

```bash
cd research/prism-model
python3 -m unittest discover -s tests -v
python3 adversarial.py
python3 scenarios.py
python3 math1_probe.py
```

First three commands were run on the baseline commit before this branch added tests. After `test_math1_probe.py` was added, discovery reported `Ran 60 tests` / `OK`.

| Command | Result | Classification of the historical claim |
|---|---|---|
| unittest on baseline HEAD | 55 tests, OK, 0.031s | The 2026-09-17 note said 51 tests. That count is STALE. The suite itself ran. |
| `adversarial.py` seed 20260917, 5000 steps | JSON matched the 2026-09-17 note exactly | REPRODUCED |
| `scenarios.py` | exit 0, AND replication `None` | REPRODUCED |
| unittest after the new probe tests | 60 tests, OK, 0.328s | MEASURED_LOCAL on this branch |

`evidence/latest/MATH1_EXECUTABLE_GAPS_VALIDATION_2026-09-17.md` does not pin HEAD `73d5f1e`. Its adversarial section is REPRODUCED. Its test count is STALE.

## Existing theorem rows

| Claim | Fresh classification |
|---|---|
| `T-REPL-001` exact `h=Gx` for admitted baskets | REPRODUCED by `test_replication.py` and `test_model.py` |
| `T-BS-001`..`T-BS-004` backing, redeem, terminal solvency, funded redemption | REPRODUCED by the existing unit tests. Not re-proven in a theorem prover for every dimension |
| `T-ALLOC-001` reservation sum | REPRODUCED, including the 5000-step seed |
| `T-PARTIAL-002` component transformation | REPRODUCED by `PartialResolutionTests` |
| `T-NATIVE-001` complete-set conservation while the reduced oracle is ACTIVE | REPRODUCED for that reduced machine. The reduced machine is not the canonical lifecycle. See baseline contradiction 2 |
| `T-NATIVE-002` YES+NO=1, invalid separate | REPRODUCED as a statement that invalid is unspecified. The new prediction model specifies INVALID separately |
| `T-LC-001`, `T-LC-002` PRISM lifecycle | REPRODUCED |
| `T-FP-001`..`T-FP-004` component integer backing | REPRODUCED by existing tests. A new 200-sample round trip (seed 20260926) found 0 mismatches. Round-trip equality is also true by construction of the requirement delta |
| `T-FP-003` funding guard | REPRODUCED as a funding statement. It does not claim holder-fair payout. See counterexample below |
| `CX-REPL-001` AND not replicated | REPRODUCED. Z3 5.1.0 also found the system with a constant column unsat |
| `H-MKT-001`, `H-MKT-002`, `H-LIQ-001`, `H-ADOPT-001` | NOT_REPRODUCED as theorems, correctly left `NOT_YET_VALIDATED`. No new market-demand evidence was collected. BLOCKED for live Kuru depth |
| Z3/SymPy artifacts in the 2026-09-17 "outside the boundary" list | Previously absent. This run produced them. The old "not yet run" sentence is STALE |

## New counterexample

`CX-FP-SETTLEMENT-001`. Classification: COUNTEREXAMPLE_FOUND.

`FixedPointSettlement` funds `ceil(supply * payout / D)` and pays `floor(q * payout / D)` per call.

Measured case, settlement decimals 18 so `D = 10^18`:

| Quantity | Value |
|---|---|
| supply | 2 |
| payout_wad | `10^18 - 1` |
| required raw | 2 |
| one-shot floor | 1 |
| two 1-unit redemptions | 0 |
| `sweepable_dust()` | 2 |

Holders receive 0. The sweepable balance is 2, which is larger than the one-shot residual of 1. The contract remains funded, so this does not falsify the narrower funding-guard claim. It falsifies holder-fair settlement and any reading of MATH-1D that treats per-call floor as safe under fragmented balances.

## Candidate repair, not accepted

Cumulative floor pays the delta of `floor(R * payout / D)`. Total paid equals the one-shot floor. Against exact ceil funding, dust is `ceil(n) - floor(n)`, which is 0 or 1 for integer division. A 240-point grid (`supply` 1..40 and six payouts) had worst dust 1 and zero mismatches against the one-shot floor. Classification of the identity: PROVEN_UNDER_ASSUMPTIONS. Classification of the grid: EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN. This is a proposal. It is not substituted into `fixed_point_model.py`.

## Other fresh probes

| Probe | Result | Classification |
|---|---|---|
| Independent two-component surplus grid, supply 0..3, extra 0..2 | 162 cases, no backing failure | EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN |
| Fixed-point and reservation stress, seeds 1, 7, 20260917, 20260926, 200 steps | no accounting exception | SUPPORTED_BY_SIMULATION. Smaller than the original 5000-step run |
| Payoff evaluation 200 iterations for shapes 2/4, 4/4, 4/16, 8/16, 16/16 | 0.0028s to 0.0531s | MEASURED_LOCAL. Sample size is not enough for p99 |
| SymPy gap identity for two components | rewritten gap equals 0 | PROVEN_UNDER_ASSUMPTIONS |
| Z3 two-component one-state solvency | negation unsat | PROVEN_UNDER_ASSUMPTIONS |

## MATH-1 verdict

**FAIL** for the current settlement payout rule (MATH-1D).

The exact-fraction accounting tests and the component requirement-delta path did not produce an insolvency counterexample in this run. That is not a PASS of the gate. Phase gates say an accounting failure fails the gate, and MATH-1D is release-blocking. Per-call settlement floor plus sweepable dust is that failure.

Production PRISM Solidity remains unauthorized. No settlement contract was added.

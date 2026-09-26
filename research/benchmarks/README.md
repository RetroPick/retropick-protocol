# Benchmarks

Measurements from this workspace on 2026-09-26. No service-level objective is implied. The payoff loops are one timed loop each. The replication, exhaustive, and telescope rows below are five local samples. Their median is the middle sample, not a service percentile. A one-run gas figure is not labeled p50.

## Environment

| Item | Value |
|---|---|
| Git base at the start of the program | `73d5f1e72b65cc5cdad0d940782c192aa331f5ed` |
| Python | 3.12.3 |
| Foundry | 1.8.3 (`cae51ad458`) |
| solc | 0.8.26 |
| optimizer | true, 200 runs |
| RPC | none |
| Seeds | prediction exhaustive is deterministic; PRISM stress seeds are in the probe output |

## Reference payoff loops

Command: `python3 math1_probe.py` inside `research/prism-model`. Each row is 200 iterations of `payoff()` on a 0/1 matrix with equal weights `1/components`.

| Components / states | Runtime seconds | Classification |
|---|---|---|
| 2/4 | 0.002785 | MEASURED_LOCAL |
| 4/4 | 0.004483 | MEASURED_LOCAL |
| 4/16 | 0.015734 | MEASURED_LOCAL |
| 8/16 | 0.028532 | MEASURED_LOCAL |
| 16/16 | 0.053079 | MEASURED_LOCAL |

Raw: `evidence/research/prism/math1-probe-2026-09-26.json` after it is copied from `/tmp/math1-probe.json`.

Limitations: one process, no warmup protocol beyond the loop itself, not an exhaustive replication search. 16/16 exhaustive state search was not run.

## Prediction exhaustive search

`max_unit = 3`, 208 states, 522 transitions, 0 failures, 0.086862 seconds. `research/prediction-model/outputs/exhaustive_summary.json`.

## Foundry test gas

`research/contract-kernels/.gas-snapshot`. These are whole-test gas figures from Foundry 1.8.3, not isolated function traces. Fuzz medians move slightly between runs. The snapshot file is one run.

## Replication solve

Command: `python3 research/benchmarks/time_reference_models.py`. The solver is `minimum_cost_exact_replication`. Each supported shape was solved five times. The target is `G` times the all-ones vector on binary state-index columns, with unit costs 1. Returned vectors were re-checked equal. 16/16 is outside the 8-component cap and was not run.

| Components / states | Min s | Median s | Max s | Status |
|---|---|---|---|---|
| 2/4 | 0.000080 | 0.000084 | 0.000158 | EXACT |
| 4/4 | 0.000273 | 0.000275 | 0.000297 | EXACT |
| 4/16 | 0.000549 | 0.000553 | 0.000573 | EXACT |
| 8/16 | 0.013886 | 0.013973 | 0.014117 | EXACT |
| 16/16 | | | | NOT_RUN |

Raw: `research/benchmarks/raw/reference-model-timings-2026-09-26.json`.

## Prediction operation gas

One Foundry test. Assembly `gas()` around `CALL` or `CREATE`. Optimizer 200, solc 0.8.26. Kernel SHA `c0af8e584137fa35ef4d71b4d8a46d260798deb4`. The whole test is 6578687 gas and includes deployment. Use the rows below.

| Operation | Gas |
|---|---|
| market deploy, including two internal outcome tokens | 2438030 |
| split 100 | 206722 |
| merge 40 | 37041 |
| resolve YES | 48909 |
| redeem YES winner, 60 units, pays 60 | 34979 |
| redeem INVALID, `redeemYes(5)`, pays 2 | 37779 |

Report: `research/benchmarks/reports/prediction-operation-gas-2026-09-26.md`.

Standalone outcome-token CREATE stays the earlier measurement, 534243. It was not rerun. There is no protocol factory contract, so factory deployment was not run.

## Repeated reference timings

Prediction `explore(max_unit=3)`, five samples: 208 states, 522 transitions, 0 failures, min 0.083795s, median 0.084142s, max 0.085207s. The committed `exhaustive_summary.json` single run of 0.086862s was not rewritten.

Candidate telescope check, five samples: min 0.011266s, median 0.011724s, max 0.268256s. The maximum is one slower call. Classifications were unchanged. Canonical MATH-1 stays FAIL.

## Not measured

Protocol factory deployment. Replication solve at 16/16. Kuru inclusion latency. Monad conflict rates. p50/p90/p95/p99.

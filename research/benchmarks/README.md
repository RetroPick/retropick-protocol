# Benchmarks

Measurements from this workspace on 2026-09-26. No service-level objective is implied. Percentiles are omitted because the sample counts below are one timed loop each, not a latency distribution.

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

## Not measured

Clone versus full-ERC-20 deployment gas. PRISM Solidity gas. Kuru inclusion latency. Monad conflict rates. p50/p90/p95/p99.

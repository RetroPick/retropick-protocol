# Benchmark Methodology

Every benchmark specifies benchmark_id, question, system under test, environment, preconditions, workload/dataset, warmup, samples, independent variables, metrics, failure criteria, raw evidence format, reproduction command and confounders.

Report p50/p90/p95/p99 only when sample size supports the statistic.

Cadence:
- PR_FAST
- NIGHTLY
- STAGING_MANUAL
- RELEASE_CANDIDATE
- LIVE_OBSERVATION

Destructive production chaos tests require explicit authorization.

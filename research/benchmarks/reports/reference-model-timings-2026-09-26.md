# Reference-model timings

Declared instances only. Not live markets. Not an SLO. Five local samples when each run was under 2 seconds. Min, median, and max are those five samples. They are not service percentiles.

Command: `python3 research/benchmarks/time_reference_models.py`  
Kernel SHA: `c0af8e584137fa35ef4d71b4d8a46d260798deb4`  
Raw: `evidence/research/benchmarks/reference-model-timings-2026-09-26.json` and `research/benchmarks/raw/reference-model-timings-2026-09-26.json`.

## Replication solve

`minimum_cost_exact_replication`. Matrix entries are binary indicators of the state-index bits. The target is `G` times the all-ones vector. Unit costs are 1. Every returned vector had `rechecked_equal` true.

| Components / states | Sample | Min s | Median s | Max s | Bases | Cost | Status |
|---|---|---|---|---|---|---|---|
| 2/4 | 5 | 0.000080 | 0.000084 | 0.000158 | 1 | 2 | EXACT |
| 4/4 | 5 | 0.000273 | 0.000275 | 0.000297 | 6 | 2 | EXACT |
| 4/16 | 5 | 0.000549 | 0.000553 | 0.000573 | 1 | 4 | EXACT |
| 8/16 | 5 | 0.013886 | 0.013973 | 0.014117 | 70 | 4 | EXACT |
| 16/16 | 0 | | | | | | NOT_RUN |

16/16 was not run. The solver domain is 16 states and 8 components. The cap was not raised.

The older payoff-loop table in `README.md` is a different measurement (`payoff()` for 200 iterations). It was not rerun.

## Prediction exhaustive search

`explore(max_unit=3)` from `research/prediction-model/exhaustive_search.py`. Five samples. 208 states, 522 transitions, 0 failures. Min 0.083795s, median 0.084142s, max 0.085207s.

`research/prediction-model/outputs/exhaustive_summary.json` was not rewritten. That earlier single run remains 0.086862 seconds.

## Candidate telescope check

`candidate_telescope_proof.run`. Five samples. Min 0.011266s, median 0.011724s, max 0.268256s. The maximum is one slower call in the same process. Global-cursor classification stayed PROVEN_UNDER_ASSUMPTIONS. The per-holder cursor stayed COUNTEREXAMPLE_FOUND. Canonical MATH-1 stays FAIL.

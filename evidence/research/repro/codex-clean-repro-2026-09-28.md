# Codex clean-checkout financial research reproduction — 2026-09-28

Source SHA: `bbbfaa2ea28c3f08e89b8ff9f80ce449df55a137` on `codex/financial-contract-qualification-v2`. Commands: `bash research/benchmarks/scripts/repro_clean.sh default` and `bash research/benchmarks/scripts/repro_clean.sh research`. Each command cloned that commit into a different temporary checkout, initialized submodules, and installed `research/requirements-formal.txt` into a new virtual environment. The source checkout stayed clean. Python 3.12.3, SymPy 1.14.0, Z3 5.1.0, Foundry 1.8.3; the kernel Foundry profile uses solc 0.8.26, optimizer runs 200, viaIR off. Local host only; not CI or production evidence.

| Profile | Check | Result |
| --- | --- | --- |
| default and research | Prediction Python unit suite | 31 passed |
| default and research | PRISM Python unit suite | 111 passed |
| default and research | kernel `forge build` | compiler succeeded |
| default and research | kernel `forge test` | 166 passed, 0 failed, 1 skipped across 107 suites |
| research | legacy per-call attack, holder-fairness attack, candidate telescope | all commands exited 0; the attacks reproduce counterexamples, not a safety pass |
| research | named PRISM exhaustive domain and five fixture generators | all commands exited 0 |
| research | reference-model timing | five local samples per shape; output identifies source SHA and explicitly is not a service percentile |
| research | Prediction INVALID composition profile | 2 passed, 0 failed; 115.10 seconds; first test is skipped under the default gas limit |

The test suites and generators rewrote 23 tracked JSON artifacts **inside each temporary clone** (mainly runtimes and regenerated fixtures). The reproducibility script prints their paths and retains logs at the printed temporary location; none were copied back to the source checkout. Re-running the commands does not license overwriting historical evidence. The one skipped Foundry test is accounted for by the separately passing long composition profile.

This verifies that the committed test harness reproduces locally. It does **not** resolve the global-cursor holder-allocation counterexample, accept ADR-R03, prove collateral admission, or upgrade `MATH-1`, `PRED-CONTRACT-1`, or `CONTRACT-1`.

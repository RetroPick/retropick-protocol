# Evidence index and reproducibility

Clean-room reproduction of the whole repository image was not performed. The commands below were run in this workspace from the committed tree after Foundry 1.8.3 was installed and, for the prover probes, after `sympy` 1.14.0 and `z3-solver` 5.1.0 were installed with pip. Those two Python packages are not in a repo lockfile. The PRISM oracle itself imports only the Python 3.12 standard library.

## Install

```bash
# Foundry, if forge is absent
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Optional, only for MATH-1E probes
python3 -m pip install --user sympy==1.14.0 z3-solver==5.1.0
```

solc 0.8.26 is downloaded by Forge on the first online build. `forge test --offline` fails before that download. That happened once and is recorded in the baseline.

## Reference models

```bash
cd research/prism-model
python3 -m unittest discover -s tests -v
python3 adversarial.py
python3 scenarios.py
python3 math1_probe.py
python3 cumulative_settlement_attack.py

cd ../prediction-model
python3 -m unittest discover -s tests -v

cd ../integration/kuru
node calculate_precisions.mjs

cd ../../prism-model
python3 generate_candidate_fixtures.py
python3 market_microstructure.py
python3 candidate_telescope_proof.py
```

On 2026-09-26 the prism-model suite was 63 tests, OK. A later prediction-model run was 11 tests, OK, including `test_invariants`. The cumulative attack reported 378530 states, 2542061 transitions, 2.973316 seconds, and no new counterexample. `forge test` in the kernel was 24 tests, OK, including invariant runs 256, 128000 calls, 48023 handler reverts. A later prism-model discovery was again 63 tests, OK. The candidate fixture generator wrote 7 cases. `forge test --match-path test/prism/*` was 3 tests, OK. After the synthetic market module and the telescope check, prism-model discovery was 69 tests, OK. Prediction-model discovery stayed 11 tests, OK. `forge test --match-path test/prediction/*` was 38 tests, OK, including the new differential tests and an invariant run of 256 runs, 128000 calls, 46694 handler reverts. That revert count is this command's run. The earlier full-suite figure remains 48023.

Fixture files are committed under `research/prediction-model/fixtures/`. The tests rewrite them to the same JSON. A hash comparison is `sha256sum research/prediction-model/fixtures/*.json` before and after the unittest.

## Foundry kernel

```bash
cd research/contract-kernels
forge test
forge snapshot
forge coverage --report summary --fuzz-runs 256 --exclude-tests
forge test --match-contract OutcomeTokenGasTest -vv
forge test --match-path "test/prism/*" -vv
forge test --match-path "test/prediction/*"
```

Recorded result: Foundry 1.8.3. The coverage run kept invariant runs 256, depth 500, 128000 calls, 0 reverts, and fuzz runs 256. Optimizer settings were disabled by the coverage tool. Deployment gas used a separate optimized build.

## Not reproduced

- `pnpm test:web` (no `node_modules`)
- Kuru testnet or fork
- echidna, medusa, halmos, mythril, semgrep
- a second clone of the repository in an empty directory

## Evidence paths

| Path | Contents |
|---|---|
| `evidence/research/baseline/` | baseline unittest, adversarial, scenarios, Doorway Forge summary |
| `evidence/research/prism/math1-probe-2026-09-26.json` | probe output |
| `evidence/research/prediction/operation-gas-2026-09-26.txt` | one Foundry run of prediction CALL and market CREATE gas |
| `research/benchmarks/reports/prediction-operation-gas-2026-09-26.md` | gas rows, SHA, optimizer, and the one-run limitation |
| `evidence/research/benchmarks/reference-model-timings-2026-09-26.json` | five-sample replication, exhaustive, and telescope timings |
| `research/benchmarks/raw/reference-model-timings-2026-09-26.json` | same timing output |
| `evidence/research/prediction/kernel-forge-2026-09-26.txt` | kernel test log |
| `evidence/research/prediction/kernel-coverage-2026-09-26.txt` | earlier forge coverage summary, branches 30.56% (11/36) |
| `evidence/research/prediction/kernel-coverage-fuzz64-2026-09-26.txt` | remeasured coverage. PredictionMarket branches 94.44% (34/36). Fuzz runs 64. Invariant runs 256 |
| `evidence/research/prediction/unreachable-branches-2026-09-26.json` | Underfunded and LiveLiability classified PROVEN_UNDER_ASSUMPTIONS. Coverage not re-run |
| `evidence/research/prediction/unreachable-branches-2026-09-26.txt` | prediction unit test for that classification |
| `evidence/research/prism/unittest-minimum-cost-2026-09-26.txt` | prism-model unittest, 85 tests OK |
| `evidence/research/prism/minimum-cost-replication-2026-09-26.json` | exact minimum-cost replication. AND with constant 1 is PRODUCT_NOT_REPLICABLE |
| `evidence/research/prism/storage-layout-2026-09-26.json` | forge storage layouts. Isolation conclusion is INFERRED |
| `docs/prism/04-architecture/STORAGE_ISOLATION.md` | slots `split` and `mint` touch. Not a Monad throughput claim |
| `evidence/research/prism/candidate-settlement-ri08-2026-09-26.txt` | candidate settlement Foundry log, 3 tests passed, including R-I08 |
| `evidence/research/prism/unittest-partial-resolution-2026-09-26.txt` | prism-model unittest after the transform tests |
| `evidence/research/prism/partial-resolution-forge-2026-09-26.txt` | payoff-transform Foundry log |
| `evidence/research/prism/partial-resolution-fixtures-2026-09-26.txt` | transform fixture generator log |
| `research/prism-model/fixtures/partial_resolution.json` | payoff-equivalent transform integers |
| `evidence/research/prediction/branch-coverage-forge-2026-09-26.txt` | reject-branch Foundry log, 14 prediction tests passed, combined with the backing suite |
| `evidence/research/prism/backing-kernel-forge-2026-09-26.txt` | backing-kernel Foundry log, 4 tests passed, same combined run |
| `evidence/research/prism/backing-fixtures-2026-09-26.txt` | backing fixture generator log |
| `evidence/research/prism/unittest-backing-kernel-2026-09-26.txt` | prism-model unittest, 70 tests OK |
| `research/prism-model/fixtures/backing_kernel.json` | FixedPointSeries and ReservationLedger integers |
| `evidence/research/prediction/outcome-token-gas-2026-09-26.txt` | full ERC-20 versus ERC-1167 CREATE gas |
| `evidence/research/prism/cumulative-floor-attack-2026-09-26.json` | candidate settlement attack. Compositions through supply 12 |
| `evidence/research/prism/cumulative-floor-supply16-2026-09-26.json` | compositions through supply 16 on 18 decimals. 917612 states, 7340046 transitions, clean |
| `evidence/research/prism/backing-domain-2026-09-26.json` | PrismSeries backing grid. 81 states, 2187 transitions, clean |
| `evidence/research/prism/extended-domains-2026-09-26.txt` | those two tests, exit 0 |
| `evidence/research/prism/r-theorem-1-2026-09-26.json` | SymPy discharge of R-THEOREM-1 / T-REPL-001. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/r-theorem-1-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/r-theorem-5-2026-09-26.json` | SymPy and Z3 discharge of R-THEOREM-5 / T-BS-004. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/r-theorem-5-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/r-theorem-6-2026-09-26.json` | Z3 and ledger discharge of R-THEOREM-6 / T-ALLOC-001. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/r-theorem-6-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-partial-002-2026-09-26.json` | SymPy and Z3 discharge of T-PARTIAL-002. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-partial-002-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prism/t-fp-001-2026-09-26.json` | Z3 discharge of T-FP-001. PROVEN_UNDER_ASSUMPTIONS |
| `evidence/research/prism/t-fp-001-2026-09-26.txt` | that test, exit 0 |
| `evidence/research/prediction/invariant-ids-2026-09-26.txt` | P-I01..P-I10 Python and Forge logs |
| `evidence/research/prism/invariant-coverage-2026-09-26.txt` | R-I02, remaining R-I11 edges, and R-I12. 3 tests, exit 0 |
| `research/prism-model/tests/test_invariant_ids.py` | those three checks on the existing exact model |
| `evidence/research/prediction/kuru/` | outcome-token Kuru worksheet and helper output |
| `evidence/research/prism/kuru/` | series-token Kuru worksheet and helper output |
| `docs/prism/04-architecture/PHASE1_CANDIDATE_SERIES.md` | proposed PRISM architecture. Candidate settlement kernel is separate and is not this series |
| `evidence/research/prism/candidate-settlement-forge-2026-09-26.txt` | candidate kernel Foundry log, 3 tests passed |
| `evidence/research/prism/candidate-settlement-gas-2026-09-26.txt` | raw fund and redeem gas log |
| `evidence/research/prism/candidate-fixtures-2026-09-26.txt` | fixture generator log |
| `evidence/research/prism/unittest-candidate-kernel-2026-09-26.txt` | prism-model unittest, 63 tests OK |
| `research/prism-model/fixtures/candidate_cumulative_settlement.json` | Python candidate integers |
| `evidence/research/prism/kuru/source-pass-2026-09-26.json` | second Kuru source pass. PRED-KURU-1 stays blocked |
| `evidence/research/prediction/differential-forge-2026-09-26.txt` | prediction Foundry path, 38 tests passed |
| `evidence/research/prediction/unittest-differential-2026-09-26.txt` | prediction-model unittest, 11 tests OK |
| `evidence/research/prism/unittest-math1f-2026-09-26.txt` | prism-model unittest, 69 tests OK |
| `evidence/research/prism/market-microstructure-2026-09-26.json` | MATH-1F synthetic quotes. Not solvency |
| `evidence/research/prism/candidate-telescope-proof-2026-09-26.json` | SymPy 1.14.0 and Z3 5.1.0 cursor check |
| `docs/prism/04-architecture/SOURCE_ASSET_INTERFACE.md` | proposed, not frozen |
| `evidence/research/prediction/slither-2026-09-26.txt` | earlier Slither log, including IR errors |
| `evidence/research/prediction/slither-focused-2026-09-26.txt` | focused Slither 0.11.6 rerun, exit 255, 14 results |
| `evidence/research/prediction/slither-legacy-ast-2026-09-26.txt` | `--solc-force-legacy-json` under Foundry. `_redeem` still has no IR. Exit 255 |
| `evidence/research/prediction/slither-solc-legacy-2026-09-26.txt` | solc framework rejects legacy JSON on 0.8.26. Exit 1 |
| `evidence/research/prediction/solhint-2026-09-26.txt` | solhint 5.2.0, exit 0, 42 warnings, 0 errors |
| `evidence/research/repro/repro-local-2026-09-26.txt` | local rerun: 12 and 85 unit tests OK, Foundry 63 passed |
| `research/benchmarks/scripts/repro_local.sh` | rerun script. Not a fresh clone or virtualenv |
| `research/prediction-model/outputs/exhaustive_summary.json` | 208-state search |
| `research/contract-kernels/.gas-snapshot` | one gas snapshot |

## Classifications used

PROVEN_UNDER_ASSUMPTIONS, EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN, SUPPORTED_BY_SIMULATION, SUPPORTED_BY_LIVE_EVIDENCE, MEASURED_LOCAL, MEASURED_TESTNET, INFERRED, RECOMMENDATION, NOT_YET_VALIDATED, COUNTEREXAMPLE_FOUND, BLOCKED.  
No MEASURED_TESTNET claim was made.

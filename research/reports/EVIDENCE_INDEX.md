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
```

On 2026-09-26 the prism-model suite was 63 tests, OK. A later prediction-model run was 11 tests, OK, including `test_invariants`. The cumulative attack reported 378530 states, 2542061 transitions, 2.973316 seconds, and no new counterexample. `forge test` in the kernel was 24 tests, OK, including invariant runs 256, 128000 calls, 48023 handler reverts.

Fixture files are committed under `research/prediction-model/fixtures/`. The tests rewrite them to the same JSON. A hash comparison is `sha256sum research/prediction-model/fixtures/*.json` before and after the unittest.

## Foundry kernel

```bash
cd research/contract-kernels
forge test
forge snapshot
forge coverage --report summary --fuzz-runs 256 --exclude-tests
forge test --match-contract OutcomeTokenGasTest -vv
```

Recorded result: Foundry 1.8.3. The coverage run kept invariant runs 256, depth 500, 128000 calls, 0 reverts, and fuzz runs 256. Optimizer settings were disabled by the coverage tool. Deployment gas used a separate optimized build.

## Not reproduced

- `pnpm test:web` (no `node_modules`)
- Kuru testnet or fork
- echidna, medusa, halmos, mythril, semgrep, solhint
- a second clone of the repository in an empty directory

## Evidence paths

| Path | Contents |
|---|---|
| `evidence/research/baseline/` | baseline unittest, adversarial, scenarios, Doorway Forge summary |
| `evidence/research/prism/math1-probe-2026-09-26.json` | probe output |
| `evidence/research/prediction/kernel-forge-2026-09-26.txt` | kernel test log |
| `evidence/research/prediction/kernel-coverage-2026-09-26.txt` | forge coverage summary |
| `evidence/research/prediction/outcome-token-gas-2026-09-26.txt` | full ERC-20 versus ERC-1167 CREATE gas |
| `evidence/research/prism/cumulative-floor-attack-2026-09-26.json` | candidate settlement attack |
| `evidence/research/prediction/invariant-ids-2026-09-26.txt` | P-I01..P-I10 Python and Forge logs |
| `evidence/research/prediction/kuru/` | outcome-token Kuru worksheet and helper output |
| `evidence/research/prism/kuru/` | series-token Kuru worksheet and helper output |
| `docs/prism/04-architecture/PHASE1_CANDIDATE_SERIES.md` | proposed PRISM architecture, no Solidity |
| `docs/prism/04-architecture/SOURCE_ASSET_INTERFACE.md` | proposed, not frozen |
| `evidence/research/prediction/slither-2026-09-26.txt` | Slither log, including IR errors |
| `research/prediction-model/outputs/exhaustive_summary.json` | 208-state search |
| `research/contract-kernels/.gas-snapshot` | one gas snapshot |

## Classifications used

PROVEN_UNDER_ASSUMPTIONS, EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN, SUPPORTED_BY_SIMULATION, SUPPORTED_BY_LIVE_EVIDENCE, MEASURED_LOCAL, MEASURED_TESTNET, INFERRED, RECOMMENDATION, NOT_YET_VALIDATED, COUNTEREXAMPLE_FOUND, BLOCKED.  
No MEASURED_TESTNET claim was made.

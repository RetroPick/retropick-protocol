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

cd ../prediction-model
python3 -m unittest discover -s tests -v
```

Fixture files are committed under `research/prediction-model/fixtures/`. The tests rewrite them to the same JSON. A hash comparison is `sha256sum research/prediction-model/fixtures/*.json` before and after the unittest.

## Foundry kernel

```bash
cd research/contract-kernels
forge test
forge snapshot
```

Recorded result: 10 tests passed, Foundry 1.8.3, including invariant runs 256, depth 500, 128000 calls, 0 reverts.

## Not reproduced

- `pnpm test:web` (no `node_modules`)
- Kuru testnet or fork
- echidna, medusa, halmos, mythril, semgrep, solhint
- a second clone of the repository in an empty directory
- `forge coverage`

## Evidence paths

| Path | Contents |
|---|---|
| `evidence/research/baseline/` | baseline unittest, adversarial, scenarios, Doorway Forge summary |
| `evidence/research/prism/math1-probe-2026-09-26.json` | probe output |
| `evidence/research/prediction/kernel-forge-2026-09-26.txt` | kernel test log |
| `evidence/research/prediction/slither-2026-09-26.txt` | Slither log, including IR errors |
| `research/prediction-model/outputs/exhaustive_summary.json` | 208-state search |
| `research/contract-kernels/.gas-snapshot` | one gas snapshot |

## Classifications used

PROVEN_UNDER_ASSUMPTIONS, EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN, SUPPORTED_BY_SIMULATION, SUPPORTED_BY_LIVE_EVIDENCE, MEASURED_LOCAL, MEASURED_TESTNET, INFERRED, RECOMMENDATION, NOT_YET_VALIDATED, COUNTEREXAMPLE_FOUND, BLOCKED.  
No MEASURED_TESTNET claim was made.

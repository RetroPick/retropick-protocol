# Codex financial qualification V2 baseline

Recorded at: 2026-09-28T08:11:30Z (UTC). The working tree was clean before this record.

## Repository provenance

| Ref | SHA |
|---|---|
| Working branch `codex/financial-contract-qualification-v2` | `915241615ee3e3742d683e3900aa72741dd39bad` |
| Fetched `origin/main` | `915241615ee3e3742d683e3900aa72741dd39bad` |
| Historical `origin/cursor/finance-qualification-bbd4` | `2aeb8d8daf72f06db6c91533b5df06b9ed4ff63f` |
| Merge-base of those remote refs | `dd7bfb5dc99dd72486649a4cbbcb26f172a1a34f` |

The Cursor branch is provenance, not the integration base. `git diff --stat` over `research/`, `docs/prism/`, `docs/prediction/`, `decisions/`, and `evidence/research/` between the historical branch and fetched main was empty. Main additionally contains post-Cursor web and architecture-documentation work.

## Environment before research dependency setup

| Item | Observed value |
|---|---|
| Host | WSL2 Linux 6.18.33.2, x86_64, Intel Core i7-1260P, 16 logical CPUs |
| Python / pip | 3.12.3 / 24.0 |
| Node / pnpm | v24.11.0 / 11.25.0 |
| Forge, Cast, Anvil | 1.8.3, commit `cae51ad458f6abb64852b7709eb784352429825d` |
| Research kernel compiler | Solidity 0.8.26 from `research/contract-kernels/foundry.toml` and a successful Forge compilation; standalone `solc` is absent |
| Research kernel settings | Cancun, optimizer on, 200 runs, viaIR off; invariant defaults 256 runs, depth 500, fail-on-revert false |
| Production contracts settings | Solidity 0.8.26, Cancun, optimizer on, 200 runs, viaIR on |
| forge-std submodule | `bf647bd6046f2f7da30d0c2bf435e5c76a780c1b` (v1.16.2), initialized |
| Formal Python imports | SymPy absent; Z3 Python bindings absent |
| Security tools | Slither 0.11.6; Aderyn 0.6.8; Semgrep 1.177.0; solhint 6.2.4; `crytic-compile` CLI absent; Echidna, Medusa, Halmos, Mythril absent |

`.cursor/install.sh` bootstraps pnpm, submodules, and Foundry, but its standard-library-only Python comment does not cover the formal scripts, which import SymPy and Z3. Historical evidence records SymPy 1.14.0 and z3-solver 5.1.0. No formal dependency was installed for this baseline.

## Focused reproduction before setup

| Check | Result |
|---|---|
| `python3 -m unittest tests.test_cumulative_settlement -v` in `research/prism-model` | 3 passed; canonical per-call counterexample preserved; candidate bounded attack clean in its declared domain |
| `forge test --match-contract CandidateCumulativeSettlementDifferentialTest --match-test test_matches_python_fixtures -vv` in `research/contract-kernels` | 1 passed; compiled with Solc 0.8.26 |
| `python3 -m unittest tests.test_candidate_telescope -v` | `BLOCKED_TOOL`: missing SymPy |
| Prediction model unittest discovery | 31 tests run with one import error, caused by missing SymPy; no gate upgrade |

The Prediction discovery test rewrote only two tracked runtime fields. They were restored to their original values immediately; the working tree was clean after that check. Future reproduction must isolate or suppress fixture writes and verify a clean tree.

## Inherited gate state

`PRED-MATH-1=partial`; `PRED-CONTRACT-1=not_pass`; `PRISM MATH-1D=fail`; `PRISM MATH-1=fail`; `SOURCE-ASSET-INTERFACE-FREEZE=proposed_not_frozen`; `X-I01..X-I07=not_yet_validated`; `MODULE-ADMISSION-FINANCE-1=not_met`. These are inherited classifications, not claims established by this focused rerun. The canonical per-call settlement rule still has `CX-FP-SETTLEMENT-001`.

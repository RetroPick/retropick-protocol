# Validation Report

**Report date:** 2026-11-09
**Immutable audit baseline:** `main@ccad6e32109d03337b560c3c876848665d9d157a`
**Change scope:** Documentation, tracked-path census, read-only inventory tooling, tooling tests, and an additive GitHub Actions test step.

This report qualifies the **maintenance changes themselves**, not the complete launchpad or the deployed Solidity protocol. The full monorepo rehabilitation remains open work.

## Evidence-backed checks

| Check | Status | Evidence |
| --- | --- | --- |
| Authenticated GitHub access and branch isolation | **PASS** | Branch created at exactly the audited main SHA; no changes to `main` |
| Complete tracked Git-tree census | **PASS** | Recursive Git tree returned `truncated=false`; 15,333 blobs, 2 gitlinks |
| Per-path source identity | **PASS (provisional)** | [TRACKED_FILE_CENSUS.tsv](TRACKED_FILE_CENSUS.tsv) records path, SHA, type, bytes, provisional class and unverified references |
| Canonical ownership consistency | **PASS (doc-level)** | `apps/retro-ui` is canonical; `apps/web` remains zero-write; frozen V2 deployment remains under `contracts/legacy-v2` |
| Inventory generator syntax | **PASS** | `python3 -m py_compile` on generator and tests (local Python 3.13) |
| Inventory generator regression tests | **PASS: 2/2** | `python3 -m unittest discover -s tests -p 'test_*.py' -v` on a mirrored local test fixture; special paths, gitlink, deterministic outputs, workspace edges, read-only behavior |
| Historical documentation link resolution | **PASS (static)** | 87 relative links resolved against baseline Git tree and added docs across eight Markdown files; zero unresolved in the previous branch scan |
| Full-tree clone and generator replay on RetroPick | **NOT RUN** | No network-capable full clone available in this execution environment |
| Changed source / contract / deployment files | **NONE** | No edits to app code, Solidity, ABI, deployment manifests, contract libraries, release records, secrets or licenses |
| CI integration | **COMMITTED, NOT YET RUN** | Added maintenance unit tests before `pnpm install` in existing [V2 workflow](../../.github/workflows/v2-liquidity.yml) |

The local test fixture is *not* a substitute for running those tests in a real RetroPick checkout and GitHub Actions. This section deliberately avoids claiming validation that has not occurred.

## Release-level checks still outstanding

| Gate | Baseline | Branch | Blocker |
| --- | --- | --- | --- |
| `pnpm install --frozen-lockfile` | **NOT RUN** | **NOT RUN** | No network-capable checkout/dependency installation |
| `pnpm check:app` | **NOT RUN** | **NOT RUN** | Repository dependencies unavailable |
| `pnpm check:services` | **NOT RUN** | **NOT RUN** | Node 24+ services and dependencies unavailable |
| Canonical frontend Playwright E2E | **NOT RUN** | **NOT RUN** | Browser runtime/complete checkout unavailable |
| `forge fmt --check` and `forge build --sizes` | **NOT RUN** | **NOT RUN** | Foundry/submodules unavailable |
| V2 Foundry unit, fuzz, stateful invariant, integration suites | **NOT RUN** | **NOT RUN** | Foundry/dependency checkout unavailable |
| Frozen deployed-source verifiers | **NOT RUN** | **NOT RUN** | Full checkout and Git provenance unavailable |
| Fork-dependent and live RPC gates | **NOT RUN** | **NOT RUN** | Qualified fork RPC and pinned block unavailable |
| Public frontend smoke and deployment verification | **NOT RUN** | **NOT RUN** | Separate production release qualification needed |
| Storage, ABI, CREATE2, code-size compatibility | **NOT REQUIRED FOR THIS DIFF; NOT PROVEN FOR FUTURE REFACTORS** | **NOT RUN** | No Solidity/ABI/source changes on this branch |

## Historical CI evidence (not a current-main result)

GitHub Actions [V2 liquidity qualification](../../.github/workflows/v2-liquidity.yml) previously reported:

- [Run 42233851106, November 6](https://github.com/RetroPick/retropick-protocol/actions/runs/42233851106): `deterministic-fullstack` **FAILED** in `verify_liquidity.py --browser`; `solidity-v2` **SUCCEEDED**.
- [Run 42180279136, November 6](https://github.com/RetroPick/retropick-protocol/actions/runs/42180279136): `deterministic-fullstack` **SUCCEEDED**; `solidity-v2` **FAILED** at stateful invariants and result qualification.

Those are different commits. They cannot establish a known current-`main` failure without reproduction. The baseline also had a successful Vercel status context; that alone does not prove all tests pass.

## Pull-request policy and decision

**Eligible for draft documentation/tooling PR after scoped static and local fixture checks. Not qualified for merge.** Opening a draft PR lets existing CI run against the actual branch and exposes missing checks for reviewers. Require successful applicable GitHub Actions and explicit maintainer review before marking it ready. No automatic merge.

**Not authorized:** deletions of unverified files, financial refactoring, legacy archive modifications, production configuration changes, release approval, or claims of completed whole-monorepo rehabilitation.

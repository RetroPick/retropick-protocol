# RetroPick repository hygiene audit and phased consolidation

**Audit date:** 2026-11-06
**Immutable baseline:** `main@5cb1c5cda1d7999225f8597896b946cdbdbb0641`
**Target:** `RetroPick/retropick-protocol`
**Status:** PARTIAL READ-ONLY INVENTORY + PHASE-1 NON-DESTRUCTIVE FIXES; NOT A RELEASE QUALIFICATION
**Method:** authenticated GitHub repository metadata, targeted file reads and code searches; no complete recursive Git tree, local checkout, dependency installation, runtime test execution or deployment access.

## Executive decision

Do **not** flatten RetroPick into a fresh skeleton and do **not** delete entire `apps/`, `contracts/`, `evidence/`, `research/` or `docs/` subtrees. The dominant verified maintenance problem is a mismatch between the canonical implementation, developer entry points, old release proofs and aspirational architectural documents.

The current platform includes a Monad Testnet V2 launchpad with historical Kuru graduation proof. `apps/retro-ui` is the canonical product frontend. `apps/web` is explicitly read-only. The deployed V2 frozen snapshot under `contracts/legacy-v2` is required for bytecode provenance and must remain intact. Prediction and PRISM remain independent research tracks; `.agent/STATE.json` records PRISM MATH-1 as FAIL, so directory cleanup does not authorize its production Solidity.

## Verified observations

| ID | Evidence from baseline | Assessment | Priority |
| --- | --- | --- | --- |
| F-01 | Root `package.json` routes `dev:web`, `build:web`, `lint:web`, `typecheck:web`, `test:web` to `@retropick/web`; `apps/README.md` calls these stale aliases | Developer commands can select a forbidden historical frontend | P0 |
| F-02 | `.agent/steering/structure.md` describes `apps/web` as the target frontend; `.agent/STATE.json`, `apps/README.md` and the fixed frontend decision identify `apps/retro-ui` | Cross-agent direction conflict | P0 |
| F-03 | `apps/retro-ui` vs `apps/example-ui-ux`: **7/8 sampled matching relative paths have identical Git blob SHAs**; `playwright.config.ts` differs; manifests substantially overlap | Confirmed sampled code/test duplication, but no complete tracked-file census yet. Donor remains active per UI renovation goal | P1 |
| F-04 | `contracts/src/v2/`, `contracts/legacy-v2/`, experimental V2, V3 research, and Prediction/PRISM research coexist | Necessary lifecycle separation, not proof of removable duplication | P1 |
| F-05 | `docs/metropolis/execution/FRONTEND_SOURCE_OF_TRUTH.md` records a 2026-10-11 public-deployment mismatch; the current README describes later live frontend status | Historical documents should be dated and distinguished from verified current deployment status | P1 |
| F-06 | `.agent/CURRENT_GOAL.md` includes active Oct campaigns and older qualification blockers alongside later runtime success statements | Goal/status reconciliation needs owner-approved validation; never silently rewrite gates | P1 |
| F-07 | Search results include extensive checked-in `evidence/**` logs and dated browser/test receipts | Retention, storage and evidence-indexing policy needed; historical evidence may be indispensable | P1 |
| F-08 | GitHub repository metadata reports `size=666539` (GitHub's approximate repository-size field, in KB) | Size investigation required; does **not** establish current worktree size or bytes safely deletable | P2 |
| F-09 | `pnpm-workspace.yaml` broadly includes `apps/*` and `packages/*`; no `turbo.json` present at baseline | Explicit package roles and dependency/CI boundaries matter before moving folders | P1 |
| F-10 | V3 venue-neutral graduation ADR-024 is marked PROPOSED; `contracts/README.md` distinguishes current development from frozen deployed V2 | Reorganization must not turn proposed designs into accepted authority | P0 |

## Lifecycle map (current as observed)

| Class | Examples | Default action |
| --- | --- | --- |
| CURRENT | `apps/retro-ui`, `packages/launchpad-sdk`, `apps/indexer`, `apps/abi`, `apps/media-service`, `apps/referral-service` | Maintain, test, make ownership discoverable |
| ACTIVE DEVELOPMENT / RELEASE-GATED | `contracts/src/v2` | Keep in place; verify ABI, invariants, deployment gates before changing |
| FROZEN DEPLOYED PROVENANCE | `contracts/legacy-v2`, `deployments/monad-testnet/v2.json`, source-verification records | Keep immutable and verifiable |
| READ-ONLY REFERENCE | `apps/web`, relevant legacy contract sources | Keep unchanged until a separately approved archival/cutover plan |
| ACTIVE DESIGN DONOR | `apps/example-ui-ux` | Keep until current UI-renovation campaign confirms donor no longer needed |
| RESEARCH / NOT RELEASE-AUTHORIZED | `docs/prism`, `research/prism*`, V3/experimental contracts | Clearly segregate; do not promote into runtime |
| HISTORICAL EVIDENCE | `evidence/**`, hackathon receipts, build/test logs | Classify/index/measure before any retention or externalization action |

## Phase 1 — safe maintenance fixes (this branch)

1. Add canonical `pnpm dev/build/lint/typecheck/test` at the root for `@retropick/retro-ui`.
2. Route ambiguous `*:web` aliases to the canonical UI; keep explicit `*:legacy-web` read-only reproduction aliases.
3. Add `pnpm check:app`, `pnpm check:services` and `pnpm check` for a reproducible maintainer verification entry point.
4. Correct stale agent structure steering without changing accepted ADRs or financial authority.
5. Add `CONTRIBUTING.md` and this inventory.

**What remains NOT RUN:** clean install, pnpm command execution, typechecks, tests, production build, browser E2E, Solidity/Foundry suites, CI, external deployment checks. The GitHub connector could read/write files but did not provide a local clone or execution runner; this PR must be verified by CI or a maintainer before merge.

**Compatibility caveat:** Any external deployment still invoking root `build:web` or `dev:web` will now target `retro-ui`. Verify Vercel and other build-root settings before merging. This branch does not change `apps/web/**`, deployment configuration or lockfiles.

## Phase 2 — measured, reversible cleanup (separate PRs)

**2A. Repository census and ownership matrix.** Use a clean clone to inventory tracked files, size by subtree, largest committed blobs, Git submodules, all `package.json` workspaces, import/reference edges and deployment roots. Write JSON + Markdown evidence. Do not run history-rewrite tools.

```bash
git ls-files | wc -l
git ls-files -z | xargs -0 -r du -b 2>/dev/null | sort -nr | head -50
git submodule status --recursive
git status --short
pnpm -r list --depth -1
rg -n 'apps/web|apps/example-ui-ux|contracts/legacy-v2|build:web|dev:web' --glob '!pnpm-lock.yaml' .
```

**2B. Frontend donor diff.** Preliminary GitHub blob comparison found identical SHA for `src/main.tsx`, `src/routes.tsx`, `src/lib/live/performance.ts`, `e2e/helpers/network-guard.ts`, `e2e/tools/mcp-handshake.mjs`, `tests/terminal.test.mjs`, and `vite.config.ts`; `playwright.config.ts` differs. This is seven exact matches among eight sampled paths, **not** proof of whole-tree identity. Compare `apps/example-ui-ux` with `apps/retro-ui` using `git diff --no-index`, tracked file hashes and import/asset graph. Maintain one canonical product frontend; only retire donor if the active renovation goal has closed and all dependent tooling/fixtures are accounted for. Preserve third-party design licenses and provenance.

**2C. Documentation taxonomy.** Make `docs/platform` the product router; `docs/launchpad` the qualified Launchpad specification; `docs/prism` research authority; `docs/engineering` maintainer guides. Introduce dated `historical` labels in old reports rather than rewriting source evidence. Reconcile `.agent/CURRENT_GOAL.md` with actual owners and evidence, leaving all state-machine gates unchanged unless authorized.

**2D. Evidence retention.** Generate a content-addressed manifest of each historical evidence run, its base SHA, execution environment, reported gate and retained artifacts. Keep immutable proof and third-party notices; move reproducible bulky generated logs off the ordinary development path only after an approved retention policy, mirrored verified storage and link integrity checks. Do not rewrite Git history as an ordinary cleanup operation.

**2E. Contracts.** Inventory onchain imports, Foundry remappings, deployed bytecode reproducibility, CI references and archive metadata before considering any path move. Deployed V2 cannot be reduced to a renamed current contract. V3 venue-neutral research and PRISM mathematical proposals are not release decisions.

**2F. CI and deployment contract.** Add jobs/checks for app, SDK, services and applicable Solidity lanes. Confirm pnpm cache, immutable lockfile, Node 24 service requirements, Foundry/submodule pinning, testnet/fork availability, artifact retention, forbidden-path guard and deployment target root. Require green status and external runtime verification before changing release defaults.

## Exit criteria for repository quality

- One unambiguous canonical frontend and owner for every runtime domain.
- Every package has a documented lifecycle: active, reference, frozen, research or generated.
- No obsolete root command silently launches a legacy application.
- From a clean clone, documented bootstrap succeeds and required scoped checks pass.
- No deployment manifest, historical source hash, license or release evidence is lost.
- Existing testnet behavior, contract bytecode and ABI boundaries are unchanged by cleanup-only PRs.
- GitHub Actions protect the active app and forbidden legacy paths.
- Measured before/after tracked-file, clone-size, build-time and CI-time metrics; **no invented savings**.
- Each cleanup batch is independently reviewable, reversible, and linked to evidence.

## References

- `README.md`, `apps/README.md`, `pnpm-workspace.yaml`, root `package.json`
- `AGENT_GUIDE.md`, `AGENTS.md`, `.agent/STATE.json`, `.agent/CURRENT_GOAL.md`
- `docs/metropolis/execution/FRONTEND_SOURCE_OF_TRUTH.md`
- `contracts/README.md`, `contracts/legacy-v2/README.md`
- `decisions/ADR-024-modular-venue-registry-and-chain-aware-graduation.md` (**PROPOSED**)

**Explicit nonclaims:** This is not a complete file-level audit, a passing CI report, proof of clean Git history, a comprehensive security audit, a fresh deployment check or approval to perform economic contract changes.

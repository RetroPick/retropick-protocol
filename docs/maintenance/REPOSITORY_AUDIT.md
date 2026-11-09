# Repository Audit: Monorepo Rehabilitation

**Audit date:** 2026-11-09
**Immutable baseline:** `main@ccad6e32109d03337b560c3c876848665d9d157a`
**Branch:** `refactor/monorepo-rehabilitation`
**Scope:** Entire tracked Git tree, plus targeted source/manifests/documentation/CI reads.
**Status:** Git-tree census COMPLETE; runtime-reference graph, code/security audit and execution qualification INCOMPLETE.

This is a point-in-time assessment, **not** an independent Solidity audit, a production-readiness certificate or authorization to delete files. It supersedes the coverage limitation in the [November 6 hygiene audit](../engineering/REPOSITORY_HYGIENE_AUDIT.md) only for tracked-tree enumeration. Earlier decisions and release records remain valid evidence.

## Inventory method and artifact

The GitHub API returned the **complete, non-truncated recursive tree** at the exact baseline commit. The tree has **16,578 objects**: **15,333 blobs**, **1,243 directory trees** and **2 Git submodule entries**. The committed blob sizes total **1,922,005,775 bytes** (sum of paths; not an on-disk Git checkout size). The two submodules are `contracts/lib/forge-std` and `contracts/lib/v4-deployment-periphery`.

[TRACKED_FILE_CENSUS.tsv](TRACKED_FILE_CENSUS.tsv) lists **all 15,335 tracked file and gitlink paths**, Git identity, committed size, provisional lifecycle classification, and `NOT_VERIFIED` reference status. This classification is path-based. It **does not** establish absence of imports, deployment references, production consumers or dynamic loading. No file is labeled safely dead by this census.

| Subtree | Tracked blobs | Sum of committed bytes | Disposition |
| --- | ---: | ---: | --- |
| `evidence/` | 12,740 | 1,860,281,513 | Historical proofs; retention review required |
| `apps/` | 769 | 28,419,392 | Several distinct lifecycle roles |
| `docs/` | 346 | 16,544,136 | Normative, historical and research docs coexist |
| `contracts/` | 481 | 6,223,934 | Active, frozen, experiments and vendored sources |
| `research/` | 464 | 2,515,666 | Research, not automatically production |
| `packages/` | 52 | 460,152 | Shared package boundary |

About **96.8%** of committed path bytes are under `evidence/`. This is a storage and discoverability concern, **not** evidence that the folder is unneeded. Some paths contain large browser screenshots, JSON qualification receipts and traces.

## Canonical source and deployment boundaries

| Component | Current source of truth according to checked repo controls | Rule |
| --- | --- | --- |
| Product frontend | `apps/retro-ui/`, Vite/React | Maintain and qualify; root pnpm commands target it |
| Historical Next.js frontend | `apps/web/` | Explicit **zero-write** reference |
| UI design donor | `apps/example-ui-ux/` | Reference, not a second production app |
| ABI catalog | `apps/abi/` | Derived interface artifact; no hand edits |
| Typed onchain SDK | `packages/launchpad-sdk/` | Shared wallet / chain boundary |
| Read-only event indexer | `apps/indexer/` | Monad event journal and read API |
| Offchain services | `apps/media-service/`, `apps/referral-service/` | No authority to sign users' economic writes |
| Active V2 Solidity | `contracts/src/v2/` | Financial semantics frozen unless independently proven safe |
| Deployed hackathon V2 | `contracts/legacy-v2/` | Preserve source/bytecode provenance |
| Deployment manifests | `deployments/monad-testnet/` | Do not modify for cleanup |
| Prediction + PRISM | `docs/prism/` and `research/prism*/` | Independent research gates |
| V2/V3 experiments | `contracts/src/*-research-experiment/` | Not automatically release-authorized |

Source of these boundaries: [apps/README.md](../../apps/README.md), [CONTRIBUTING.md](../../CONTRIBUTING.md), [frontend source-of-truth decision](../metropolis/execution/FRONTEND_SOURCE_OF_TRUTH.md), [contract guardrails](../../contracts/AGENTS.md), and [agent state](../../.agent/STATE.json). The last records PRISM MATH-1 as **FAIL** and expressly does not authorize production Solidity.

**Architecture caution:** supplied older V1/Base Sepolia architecture references must not override this repo's checked Monad/V2 control plane. The canonical frontend is **not** `apps/web`; the historical Kuru-deployed snapshot must not be conflated with all ongoing V2/V3 work.

## Exact-blob duplication: UI donor

The baseline contains **299** blobs under `apps/retro-ui/` and **290** under `apps/example-ui-ux/`. Across matching relative paths, **251** have identical Git blob SHA and **34** differ; **5** paths exist only in the donor and **14** only in the canonical UI. Identical blobs can still serve meaningful separate release, design or test roles. No deduplication is authorized before Vite, Playwright, deployment, import and donor-reference checks.

## Workspace and operational map

Root `package.json` pins `pnpm@11.25.0`; `pnpm-workspace.yaml` includes `apps/*` and `packages/*`. Node minimum is `>=22.13.0` at the root, while the indexer and services require Node 24+. Root `pnpm dev`, `pnpm build` and `pnpm check:app` target the canonical UI; `pnpm check:services` targets the SDK, indexer, media and referral packages.

Existing CI contains `.github/workflows/v2-liquidity.yml` and `v3-framework-research.yml`. The former includes Foundry unit, fuzz and invariant gates plus a frontend/browser qualification; its historical failure evidence is described in [VALIDATION_REPORT.md](VALIDATION_REPORT.md). Do not infer full current-main CI success from earlier fork or PR runs.

GitHub's repository tree provides exact path inventory and blob SHA comparisons, but this pass **did not** read all 15,333 file bodies, execute a complete static import graph, or establish live RPC/deployment state.

## Findings and priorities

| ID | Priority | Finding | Disposition |
| --- | --- | --- | --- |
| R-01 | P0 | No executable baseline for the current `main` established in this session | Hold financial/runtime refactor |
| R-02 | P0 | Frozen deployed artifacts coexist with evolving source | Preserve immutable boundaries |
| R-03 | P1 | Significant UI donor overlap; 251 exact shared relative-path blobs | Reference trace and donor QA before any consolidation |
| R-04 | P1 | 12,740 evidence files dominate Git-path footprint | Propose index/retention plan, no destructive cleanup |
| R-05 | P1 | Normative docs, research docs, and dated hackathon evidence coexist | Add lifecycle navigation and status labels |
| R-06 | P1 | Historical V2 qualification failures exist on PR commits | Diagnose before claiming green baseline |
| R-07 | P1 | Full dependency/import graph and deployed ABI/storage comparisons not performed | Required before code/contract edits |
| R-08 | P2 | Root README prioritizes hackathon judging over developer orientation | Reorganize onboarding without removing proof links |

## Required work before safe deletions or contract changes

1. Run `pnpm install --frozen-lockfile`, `pnpm check` and canonical Playwright fixture smoke from a clean, correctly pinned environment; preserve logs and SHA.
2. Run Foundry format/build/unit/fuzz/invariant gates and both frozen-source verification programs as specified by [contracts/README.md](../../contracts/README.md). Fork-dependent gates must record provider, block and outcome.
3. Trace import graphs (static/dynamic), CI jobs, Vercel build roots/rewrites, deployment scripts, ABI publishers, release manifests, docs backlinks and submodule references.
4. Compare any Solidity change against deployed source and storage/ABI/selector/bytecode compatibility, accounting and custody invariants; do not silently migrate upgrades.
5. For any proposed deletion, record evidence, owners, expected consumers, tests, rollback path and exact Git diff in [CLEANUP_DECISIONS.md](CLEANUP_DECISIONS.md).

No files were deleted by this phase.

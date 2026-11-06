# Repository structure steering

> Current observed paths, not a prospective architecture diagram.
> Baseline: `main@5cb1c5cda1d7999225f8597896b946cdbdbb0641`, audited 2026-11-06.
> Accepted ADRs and module gates remain authoritative if this map becomes stale.

## Source-of-truth hierarchy

| Purpose | Authority |
| --- | --- |
| Product and shared-platform architecture | `docs/platform/` |
| Launchpad financial semantics | `docs/launchpad/` + accepted `decisions/` |
| Prediction and PRISM research semantics | `docs/prism/` + accepted `decisions/` |
| Implementation plans (not release authority) | `development/`, `goals/` |
| Release/qualification receipts | `evidence/` and deployment manifests |
| Agent routing, active work and restrictions | `.agent/`, `AGENT_GUIDE.md`, local `AGENTS.md` |

## Actual workspace ownership

| Path | Ownership and lifecycle |
| --- | --- |
| `apps/retro-ui/` | **Canonical** end-user frontend; Vite/React. Product UI changes belong here |
| `apps/web/` | **Read-only legacy reference**; zero-write guard applies. Not a development target |
| `apps/example-ui-ux/` | Design donor/reference for the active UI renovation; not the canonical product |
| `apps/abi/` | Derived deployed ABI catalog; regenerate via the approved export process |
| `packages/launchpad-sdk/` | Shared typed chain/read/write-preparation boundary |
| `apps/indexer/` | Indexed, non-authoritative read model; does not decide economic state |
| `apps/media-service/` | Media service |
| `apps/referral-service/` | Referral service |
| `contracts/src/v2/` | Current development V2 Solidity; changes require the owning gates and tests |
| `contracts/legacy-v2/` | **Immutable deployed-source archive**, not a deletion/rename candidate |
| `contracts/src/v2-research-experiment/` | Experimental V2 research, not a release target |
| `docs/prism/` + `research/prism*/` | Prediction/PRISM incubation; independent mathematical/security gates |

Contract subtrees, downstream package consumers, and deployment configs must be re-inventoried before any move.

## Repository cleanup rules

1. Keep *current runtime*, *historical deployment archive*, *research*, and *generated evidence* separate by lifecycle; a path being old does not mean it is disposable.
2. Preserve the deployed V2 source identity, bytecode/settings provenance, recorded addresses, evidence manifests and third-party license notices.
3. Never edit `apps/web/**` while the zero-write guard is in force; fix aliases and documentation at the root instead.
4. Before consolidating `apps/example-ui-ux`, prove the donor is no longer used by the current UI-renovation goal and compare imports/assets and E2E fixtures.
5. Before changing `pnpm-workspace.yaml` or contract paths, check all workspace dependencies, CI jobs, deploy build roots, scripts, submodules, and historical reproduction commands.
6. Do not promote Prediction/PRISM or experimental V3 modules into the release lane by reorganizing directories.
7. Use a separate PR per cleanup category; require baseline verification and a rollback path.

The earlier prospective layout that used `apps/web` as the *target* frontend is obsolete. See `apps/README.md`, `docs/metropolis/execution/FRONTEND_SOURCE_OF_TRUTH.md` and `.agent/STATE.json` for the fixed canonical frontend decision.

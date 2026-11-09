# Cleanup Decisions

**Date:** 2026-11-09
**Audit baseline:** `main@ccad6e32109d03337b560c3c876848665d9d157a`

Decisions below apply **only** to `refactor/monorepo-rehabilitation`. Every entry separates an approved low-risk action from a deferred proposal. No cleanup decision authorizes changing financial semantics or production deployment.

| ID | Decision | Status | Evidence / gate |
| --- | --- | --- | --- |
| D-001 | Record a complete immutable tracked-tree census with provisional per-path classification | **EXECUTED** | [TRACKED_FILE_CENSUS.tsv](TRACKED_FILE_CENSUS.tsv), 15,335 paths |
| D-002 | Preserve `apps/web/**` unchanged | **HARD GUARDRAIL** | [frontend source-of-truth](../metropolis/execution/FRONTEND_SOURCE_OF_TRUTH.md) |
| D-003 | Treat `apps/retro-ui` as canonical UI; `apps/example-ui-ux` remains reference | **HARD GUARDRAIL** | [apps/README.md](../../apps/README.md), donor overlap census |
| D-004 | Keep `contracts/legacy-v2`, deployment manifests, licenses, attribution and verification records unchanged | **HARD GUARDRAIL** | [contracts/README.md](../../contracts/README.md) |
| D-005 | Do not delete exact-duplicate files merely because their SHA matches | **DEFERRED** | No consumer/import/deployment trace |
| D-006 | Keep `evidence/**` intact until reproduction, provenance, ownership and retention review | **DEFERRED** | 12,740 blobs / 1.86 GB |
| D-007 | Preserve current contract ABI, selectors, CREATE2 derivations, storage, venue behavior and solvency rules | **HARD GUARDRAIL** | No runtime verification or differential proof |
| D-008 | Do not promote Prediction/PRISM research into active Solidity | **HARD GUARDRAIL** | `.agent/STATE.json` records MATH-1 FAIL |
| D-009 | Add maintenance documentation and make contributor navigation clearer | **APPROVED DOC-ONLY** | No application, deployment or contract edits |
| D-010 | Defer frontend/backend dead-code removal and dependency normalization | **DEFERRED** | Requires reproducible baseline and graph of consumers |
| D-011 | Do not open a ready-to-merge PR until required validation is documented | **REQUIRED** | [VALIDATION_REPORT.md](VALIDATION_REPORT.md) |

## Deletion/change evidence template

Before removing or moving an item, record:

- **Path and Git blob SHA** at the audited base;
- **Classification:** canonical / historical / generated / redundant / uncertain;
- **Reference proof:** imports, runtime loaders, CI, deployment roots, documentation, archive/reproduction scripts;
- **Ownership and release status:** which module and supported version uses it;
- **Validation before/after:** exact commands, logs, environment and result;
- **Reversibility:** recovery commit and links to preserved provenance;
- **Approval:** maintainer for non-financial changes, protocol security/release owner for financial changes.

**Default for uncertainty: retain in place and document.** A directory move is a functional change if build, path resolution, import, ABI source, release scripts or evidence references depend on its current path.

## Out-of-scope until separate approval

No force push, history rewriting, license deletion, contract redeployment, mainnet authorization, secrets copying, governance/keeper operation, Vercel cutover, ABI regeneration, automatic merging or active DEX venue change.

## Candidate follow-up patches (not executed)

1. Add deterministic local inventory/reference-tracing tooling and validate against a clean clone.
2. Audit UI donor as a differential PR with a clear allowed-delete list, if any.
3. Index key historical evidence by campaign and release commit; consider off-repo storage only with durable verified hashes and maintainer approval.
4. Improve CI coverage for canonical services and replayable frontend smokes **after** current baseline is known.
5. Address Solidity security findings only as isolated, independently tested patches, never as a cosmetic monorepo rename.

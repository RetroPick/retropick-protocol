# Launchpad Frontend Agent

## Mission
Build the browser product against shared domain/SDK/API/indexer contracts.

## Read first
- `docs/launchpad/PRODUCT.md`
- `docs/launchpad/USER_FLOWS.md`
- `development/launchpad/frontend/README.md`
- `development/launchpad/shared/DOMAIN_MODEL.md`

## Own
- `apps/web/**`
- `packages/ui/**`

## Read-only dependencies
- `contracts/**`
- `apps/api/**`
- `apps/indexer/**`

## Do not
- invent canonical economic state
- duplicate ABI/domain enums
- route normal economic writes through backend signing
- use JS number for onchain integer values

## Verification
- lint/typecheck/unit/build/browser smoke and owning E2E

## Handoff
Web build, route inventory, stable E2E selectors and transaction fixtures to QA.

## Universal output contract
Every delivery identifies requirement IDs, assumptions, changed files, exact verification, evidence, residual blockers and downstream artifacts.

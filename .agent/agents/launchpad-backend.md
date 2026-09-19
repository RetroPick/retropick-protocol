# Launchpad Backend Agent

## Mission
Build the non-custodial metadata/search/ranking/read API.

## Read first
- `development/launchpad/backend/README.md`
- `development/launchpad/backend/API_SPEC.md`
- `development/launchpad/shared/DOMAIN_MODEL.md`
- `development/launchpad/indexing/QUERY_CONTRACT.md`

## Own
- `apps/api/**`

## Read-only dependencies
- `contracts/**`
- `apps/indexer/**`
- `apps/web/**`

## Do not
- sign normal user trades
- custody launch reserves
- declare graduation
- redefine chain state

## Verification
- lint/typecheck/unit/integration/OpenAPI contract tests

## Handoff
OpenAPI schema, generated client, auth/error semantics and API test report to frontend/QA.

## Universal output contract
Every delivery identifies requirement IDs, assumptions, changed files, exact verification, evidence, residual blockers and downstream artifacts.

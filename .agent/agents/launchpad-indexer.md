# Launchpad Indexer Agent

## Mission
Build a reconstructible event-derived read model with freshness/reorg semantics.

## Read first
- `development/launchpad/indexing/README.md`
- `development/launchpad/indexing/EVENT_MODEL.md`
- `development/launchpad/indexing/ENTITY_SCHEMA.md`
- `development/launchpad/shared/DOMAIN_MODEL.md`

## Own
- `apps/indexer/**`

## Read-only dependencies
- `contracts/**`
- `apps/api/**`
- `apps/web/**`

## Do not
- become financial authority
- invent state not derivable from defined inputs
- hide sync lag

## Verification
- event mapping
- deterministic rebuild
- duplicate/idempotency
- reorg
- sync-health/query tests

## Handoff
Entity schema, typed query contract and sync-health semantics to API/frontend.

## Universal output contract
Every delivery identifies requirement IDs, assumptions, changed files, exact verification, evidence, residual blockers and downstream artifacts.

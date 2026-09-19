# Backend Architecture

**Status:** DRAFT  
**Owner:** Backend  
**Authority:** System architecture

## Purpose

Keep the backend useful but non-custodial and non-authoritative for launch economics.

## Requirements

- Own metadata, search, ranking, analytics, cached launch summaries, image handling, moderation metadata, anti-spam and optional notifications.
- Derive economic data from contracts/indexer and expose freshness/source metadata.
- Use idempotent jobs for event-derived enrichment and retries.
- Keep transaction writes in user wallets unless a narrowly specified operational transaction requires a dedicated actor.

## Non-goals

- No reserve custody.
- No hidden price calculation authority.
- No offchain graduation declaration.

## Acceptance criteria

- Backend outage cannot corrupt onchain lifecycle.
- API contracts identify source/cache semantics.

## Evidence required

- API tests and outage/fallback E2E.

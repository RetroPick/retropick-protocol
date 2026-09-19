# API Contracts

**Status:** DRAFT  
**Owner:** Backend + Frontend

## Read domains

- `GET /launches`: discover/filter/sort launch summaries.
- `GET /launches/:address`: launch metadata plus indexed state and freshness.
- `GET /creators/:address`: launches and activity.
- `GET /portfolio/:address`: derived holdings/activity where indexing supports it.
- `GET /activity`: paginated protocol/user events.
- `GET /protocol/stats`: derived aggregate metrics.
- `GET /quote-assets`: supported UI list backed by canonical configuration.

## Contract for each endpoint

Document request, response schema, authoritative source, cache TTL, freshness field, error semantics, pagination and fallback. Economic write actions remain wallet transactions, not hidden backend commands.

## Acceptance

Frontend types are generated/shared where practical; schema breaking changes are versioned; tests cover stale cache and indexer unavailability.

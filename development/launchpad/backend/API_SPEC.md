---
id: LP-BE-API
type: normative_implementation
status: ready
owner: launchpad-backend
product: launchpad
version: v2
---

# API Specification

Initial contract domains:
- `GET /v1/launches` discovery with cursor pagination/filter/sort;
- `GET /v1/launches/:token` metadata + indexed summary + freshness;
- `GET /v1/creators/:address`;
- `GET /v1/activity`;
- `GET /v1/portfolio/:address` when derivable;
- `GET /v1/quote-assets`;
- `GET /v1/protocol/stats`;
- auth nonce/verify for offchain profile/metadata writes;
- metadata create/update where authorized.

For each implemented endpoint, OpenAPI must define auth, params, request/response/error schema, pagination, cache semantics, authoritative source and rate limit. Generate clients/types; do not duplicate them manually in web.
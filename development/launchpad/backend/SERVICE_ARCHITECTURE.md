---
id: LP-BE-ARCH
type: normative_implementation
status: ready
owner: launchpad-backend
product: launchpad
version: v2
---

# Service Architecture

CANDIDATE: TypeScript HTTP service + PostgreSQL, with typed validation/OpenAPI. Exact framework/ORM/storage choices require ADR.

Reads contract-derived state through the indexer/query layer. Direct RPC is limited to defined fallback/verification paths.
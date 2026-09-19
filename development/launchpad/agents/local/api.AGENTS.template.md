# apps/api Agent Contract

WHY: provide metadata/search/ranking/read APIs.
WHERE: own `apps/api/**`.
WHAT: non-custodial API using shared domain schemas and indexer query contract.
WHAT NOT: do not sign user trades, custody reserves, declare graduation, or redefine chain state.
VERIFY: lint, typecheck, unit, integration, OpenAPI contract tests.
HANDOFF: OpenAPI schema + generated client + error/auth semantics to frontend.

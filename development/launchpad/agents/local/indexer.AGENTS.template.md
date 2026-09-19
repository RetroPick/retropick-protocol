# apps/indexer Agent Contract

WHY: create a reconstructible, freshness-aware read model from onchain events.
WHERE: own `apps/indexer/**`.
WHAT NOT: never become financial authority.
VERIFY: schema tests, deterministic rebuild, reorg, lag/sync-health tests.
HANDOFF: entity schema + typed query contract + sync-health semantics.

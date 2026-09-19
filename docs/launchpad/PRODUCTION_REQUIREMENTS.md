---
id: LP-PRODUCTION
type: normative
product: launchpad
version: v2
status: active
---

# Production Requirements

A production-shaped release has:
- reproducible source/build/deployment;
- versioned environment/address manifest;
- bounded admin/key model;
- qualified quote/Kuru configuration;
- contract test/security evidence;
- indexer rebuild/reorg/freshness behavior;
- typed API/domain/SDK boundaries;
- browser E2E against real environment;
- secret/dependency scanning;
- metrics/logs/alerts;
- incident and redeploy/rollback procedures.

Web/API/indexer rollback is distinct from immutable contract incident response.

Do not call HACKATHON_READY equivalent to MAINNET_AUTHORIZED.

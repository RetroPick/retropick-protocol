# Launchpad Agent Control Plane Validation

**Status:** PASS for control-plane structure; product DEVELOPMENT_READY remains open  
**Date:** 2026-09-20  
**Validated commit:** `7c24e20e88cfaa1c6e71d953a949670f64392d31`

## Structural result

- canonical Launchpad product/protocol Markdown: 23 files;
- current-code contract reference: 7 files;
- Launchpad development/control documents: 102 Markdown/YAML files;
- Kiro steering: 6 files;
- Kiro custom agents: 9 files;
- old numbered Launchpad documentation directories: absent;
- old duplicate contract-doc filenames targeted by consolidation: absent.

## Agent-control result

Current official Kiro IDE 1.0 / CLI 3.0 documentation supports:
- workspace steering under `.kiro/steering/`;
- Markdown custom agents under `.kiro/agents/`;
- `resources`, `tools`, and capability-based `permissions.rules`;
- nested `AGENTS.md`.

Repository custom agents use those current schema concepts. A local Kiro parser/runtime was not available through the GitHub connector, so local CLI loading remains an implementation-environment smoke test.

## Current-source findings encoded

- V2 Factory is directly coupled to Uniswap V4 PoolManager/PositionManager/Permit2/hook/locker/graduation executor.
- Kuru is TARGET, not current committed graduation runtime.
- committed Launchpad test directories currently contain Doorway-focused tests, not Factory/Token/Curve/Graduation qualification.

## Representative routing simulation

### Implement Launchpad buy UI
Read:
`docs/launchpad/{PRODUCT,USER_FLOWS,PROTOCOL}.md`,
`development/launchpad/frontend/*`,
`development/launchpad/shared/*`,
future `apps/web/AGENTS.md`.
Owner: frontend.
Forbidden: Solidity/backend/indexer mutation.
Blocker: runtime workspace not implemented yet.

### Implement launch metadata API
Read:
backend architecture/API/DB/auth/metadata specs plus shared domain.
Owner: backend.
Hard boundary: no reserve authority or user-trade signing.
Blocker: backend runtime ADR/workspace not yet accepted/implemented.

### Implement indexer Trade entity
Read:
indexing event/entity/reorg/query/sync specs plus generated contract event catalog.
Owner: indexer.
Hard boundary: derived read model only.
Blocker: provider ADR and generated Launchpad event artifact.

### Implement V2 Kuru graduation
Read:
canonical Graduation/Kuru/Invariant specs, contract target architecture, Kuru parameter policy and source pins.
Owner: Solidity + integrations.
Hard boundary: do not change bonding math; destination failure must preserve secured assets.
Blocker: target Kuru deployment/API and parameter ADR acceptance.

### Implement staging deployment
Read:
DevOps environment/deployment/CI/observability/runbook specs and machine gate definitions.
Owner: DevOps.
Blocker: preceding implementation/integration/security artifacts.

## Verdict

The repository now provides bounded context, ownership, constraints, handoffs and machine-readable gates for agent development. The control-plane construction goal is structurally complete.

The product is intentionally NOT marked DEVELOPMENT_READY because material implementation/decision blockers remain. This is a correctness property, not a documentation failure.

---
id: LP-CURRENT-STATE
type: generated_current_state
status: ready
owner: launchpad-planner
product: launchpad
version: v2
---

# Current Repository State

Validated against `main` before creation of this control plane.

## Runtime

- `apps/`: placeholder README only.
- `packages/`: placeholder README only.
- root `tests/`: placeholder README only.
- root `scripts/`: placeholder README only.
- no committed TypeScript workspace/runtime foundation.
- no committed web/API/indexer implementation.

## Contracts

Substantive implementation exists in `contracts/src/v1/` and `contracts/src/v2/`.

Current V2 factory directly imports Uniswap V4 core/periphery, Permit2, the V4-oriented graduation executor, launch locker and hook. The active Solidity therefore represents a V4-oriented graduation implementation, not a completed Kuru graduation implementation.

## Tests

Current committed Foundry tests are Doorway-focused:
- unit: Doorway base/lifecycle/request;
- fuzz: Doorway fuzz;
- invariant: Doorway invariant;
- integration: Doorway E2E.

No committed Factory/Token/BondingCurve/fee/graduation core V2 test suite currently qualifies the Launchpad P0 path.

## Agent infrastructure

- `.agent/` is now the universal cross-harness control plane for Launchpad and PRISM;
- tool-specific `.kiro/` repository configuration has been removed;
- root `AGENT_GUIDE.md` and `AGENTS.md` route all agent harnesses into the same workflow.

## Consequence

The next implementation phase must not begin from an assumption that the full-stack or Kuru integration already exists. First establish contract behavioral coverage and stable interfaces.

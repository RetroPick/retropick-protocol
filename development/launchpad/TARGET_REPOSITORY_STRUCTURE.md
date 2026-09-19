---
id: LP-STRUCTURE
type: normative_implementation
status: ready
owner: launchpad-planner
product: launchpad
version: v2
---

# Target Repository Structure

```text
apps/
  web/
  api/
  indexer/

packages/
  contracts/
  domain/
  sdk/
  config/
  ui/
  test-utils/

contracts/
  src/
  test/
  script/
  docs/

docs/
  launchpad/
  prism/

development/
  launchpad/

evidence/
  launchpad/
```

## Workspace decision state

A TypeScript monorepo is a CANDIDATE until accepted by ADR. The implementation plan assumes a pnpm workspace with strict TypeScript and a task orchestrator such as Turborepo only after that decision is accepted.

## Ownership

- `apps/web/**`: frontend.
- `apps/api/**`: backend.
- `apps/indexer/**`: indexer.
- `packages/domain/**`: shared canonical TS domain types/schemas.
- `packages/contracts/**`: generated ABI/types/deployments.
- `packages/sdk/**`: transaction/read helpers.
- `packages/config/**`: machine-readable environment/config.
- `packages/ui/**`: reusable UI.
- `contracts/**`: Solidity.

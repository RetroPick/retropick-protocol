---
inclusion: always
---

# Repository Structure Steering

Canonical responsibility:
- `docs/launchpad/`: Launchpad product/protocol truth.
- `docs/prism/`: Prediction/PRISM truth.
- `development/launchpad/`: Launchpad implementation architecture/control.
- `contracts/docs/`: current Solidity reference.
- `evidence/`: proof.
- `decisions/`: ADRs.
- `goals/`: scoped execution goals.

Future runtime ownership:
- `apps/web`: frontend
- `apps/api`: backend
- `apps/indexer`: indexer
- `packages/domain`: canonical TS types/schemas
- `packages/contracts`: generated contract artifacts
- `packages/sdk`: typed reads/writes
- `packages/config`: environment/deployment configuration

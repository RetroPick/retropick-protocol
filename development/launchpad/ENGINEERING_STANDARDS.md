---
id: LP-ENG-STANDARDS
type: normative_implementation
status: ready
owner: launchpad-planner
product: launchpad
version: v2
---

# Engineering Standards

## Global

- Do not duplicate canonical domain types across runtimes.
- Do not silently change protocol semantics in implementation.
- Do not make backend/indexer state authoritative for contract economics.
- Normal economic writes are user-wallet -> chain transactions.
- Onchain integer quantities use `bigint` in TypeScript; format at UI boundaries.
- External mutable integrations require a version/source pin.
- New architectural decisions require ADRs.
- Every feature maps requirement -> owner -> implementation -> test -> evidence -> gate.

## Change discipline

Each implementation spec distinguishes CURRENT, TARGET, DELTA and MIGRATION ORDER.

## Completion

A task is incomplete until exact verification commands pass or the failure is explicitly recorded as a blocker.

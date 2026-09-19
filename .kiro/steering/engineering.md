---
inclusion: always
---

# Engineering Steering

- Read the nearest local `AGENTS.md`.
- Do not duplicate canonical domain models.
- Use bigint for onchain integer quantities in TypeScript.
- Do not treat indexer/backend data as authoritative economic state.
- Preserve CURRENT/TARGET/DELTA/MIGRATION_ORDER distinction.
- Do not make architecture changes inside ordinary feature tasks.
- Do not change V1 while implementing V2 unless explicitly authorized.
- Do not add a generic multi-venue abstraction for P0 without a second real requirement.
- Every implementation output must satisfy an explicit requirement and produce downstream handoff artifacts.

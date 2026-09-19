# Engineering Steering

- Read the nearest local `AGENTS.md`.
- Resolve requirement/owner/dependency before coding.
- Do not duplicate canonical domain models.
- Use exact integer arithmetic for onchain values; TypeScript uses `bigint`.
- Do not treat indexer/backend state as canonical economics.
- Architecture-changing work must state CURRENT / TARGET / DELTA / MIGRATION ORDER.
- Do not make hidden architecture decisions inside feature implementation.
- Do not modify V1 while implementing V2 unless explicitly authorized.
- Do not introduce generic abstractions before a real second use case justifies them.
- Every output must have a downstream interface/handoff when another component consumes it.

# ADR-007 — Math-First Phase Gates

**Status:** ACCEPTED  
**Date:** 2026-09-17

## Context

The historical implementation report scheduled contract work immediately after architecture discussion and described W0-W12 as a sequential twelve-week plan.

The protocol contains financial invariants whose implementation should be derived from a validated reference model rather than discovered during Solidity development.

## Decision

Use hard dependency gates:

```text
SPEC-1
-> MATH-1
-> CONTRACT-ARCH-1
-> CONTRACT-1
-> INTEGRATION-1 / PRODUCT-1
-> E2E-1
-> SUBMISSION-1
```

Parallel sponsor/UI prototypes may use mocks once boundaries are stable, but they may not define protocol economics.

Production Solidity does not begin before MATH-1 verdict.

## Consequences

- some sponsor work may be prototyped in parallel;
- financial semantics stay centralized;
- contract storage/interfaces are derived after precision/invariant decisions;
- schedule cuts remove breadth before solvency work.

The detailed gate definitions live in `docs/prism/05-hackathon/PHASE_GATES.md`.

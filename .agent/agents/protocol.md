# Protocol Agent

## Mission

Own financial semantics, lifecycle, state machines and invariants for the routed module.

## Routing

- Launchpad-Core protocol: docs/launchpad/
- Prediction/PRISM protocol: docs/prism/protocol/ + docs/prism/math/

## Rules

- one RetroPick product platform does not imply one accounting model;
- never transfer semantics between modules without explicit scope and normally an ADR;
- code may not redefine protocol truth;
- shared infrastructure remains non-authoritative for module accounting.

## Output contract

Every protocol change states CURRENT, TARGET, DELTA, assumptions, invariants, tests/proofs required and ADR impact.

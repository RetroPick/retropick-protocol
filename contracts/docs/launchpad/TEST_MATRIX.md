# Contract Test Matrix

**Status:** DRAFT  
**Owner:** Smart Contracts + Security  
**Authority:** Solidity implementation specification

## Purpose

Define V1/V2 unit/fuzz/invariant/integration ownership.

## Requirements

- V2 divergence requires V2 tests.
- Include malicious token, threshold crossing, failure/retry and access-control cases.
- Track current pass evidence separately from intended tests.

## Non-goals

- Does not override docs/launchpad/03-protocol.

## Acceptance criteria

- Implementation mapping is concrete enough to review against code.

## Evidence required

- Foundry/static/deployment evidence as applicable.

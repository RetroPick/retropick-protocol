# Invariant Map

**Status:** DRAFT  
**Owner:** Smart Contracts + Security  
**Authority:** Solidity implementation specification

## Purpose

Map protocol invariants to contracts/tests.

## Requirements

- Each invariant names state variables, functions that can affect it and a Foundry invariant/fuzz owner.
- No safety claim without executable coverage.

## Non-goals

- Does not override docs/launchpad/03-protocol.

## Acceptance criteria

- Implementation mapping is concrete enough to review against code.

## Evidence required

- Foundry/static/deployment evidence as applicable.

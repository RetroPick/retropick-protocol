# Contract Responsibility Map

**Status:** DRAFT  
**Owner:** Smart Contracts + Security  
**Authority:** Solidity implementation specification

## Purpose

Prevent god-contract responsibility drift.

## Requirements

- For every contract list custody, state ownership, trusted callers, external calls and invariants.
- A responsibility has one canonical owner.

## Non-goals

- Does not override docs/launchpad/03-protocol.

## Acceptance criteria

- Implementation mapping is concrete enough to review against code.

## Evidence required

- Foundry/static/deployment evidence as applicable.

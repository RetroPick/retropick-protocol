# Contract Change Control

**Status:** DRAFT  
**Owner:** Smart Contracts + Security  
**Authority:** Solidity implementation specification

## Purpose

Define how V2 semantic changes are approved.

## Requirements

- Protocol change -> spec update; architecture change -> ADR; ABI/storage/economic change -> explicit impact review; all -> tests/security.
- Emergency fixes require follow-up documentation.

## Non-goals

- Does not override docs/launchpad/03-protocol.

## Acceptance criteria

- Implementation mapping is concrete enough to review against code.

## Evidence required

- Foundry/static/deployment evidence as applicable.

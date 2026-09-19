# Contract Access Control

**Status:** DRAFT  
**Owner:** Smart Contracts + Security  
**Authority:** Solidity implementation specification

## Purpose

Map functions to authorized callers and risk.

## Requirements

- Create a function/role matrix.
- Document owner transfer/renounce/pause/recovery behavior.
- Tie each privilege to tests.

## Non-goals

- Does not override docs/launchpad/03-protocol.

## Acceptance criteria

- Implementation mapping is concrete enough to review against code.

## Evidence required

- Foundry/static/deployment evidence as applicable.

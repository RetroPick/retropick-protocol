# CREATE2 and Deployment

**Status:** DRAFT  
**Owner:** Smart Contracts + Security  
**Authority:** Solidity implementation specification

## Purpose

Document deterministic deployment semantics.

## Requirements

- Record salt namespaces, predict/deploy relation and collision behavior.
- Bytecode changes imply address changes; scripts must verify expected addresses.

## Non-goals

- Does not override docs/launchpad/03-protocol.

## Acceptance criteria

- Implementation mapping is concrete enough to review against code.

## Evidence required

- Foundry/static/deployment evidence as applicable.

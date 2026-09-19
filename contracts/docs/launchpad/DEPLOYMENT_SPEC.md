# Contract Deployment Specification

**Status:** DRAFT  
**Owner:** Smart Contracts + Security  
**Authority:** Solidity implementation specification

## Purpose

Define production-like deployment/configuration order.

## Requirements

- Derive order from constructor/runtime dependencies.
- Record args, role addresses, expected code hashes, post-deploy config and smoke tests.
- No secrets in repo.

## Non-goals

- Does not override docs/launchpad/03-protocol.

## Acceptance criteria

- Implementation mapping is concrete enough to review against code.

## Evidence required

- Foundry/static/deployment evidence as applicable.

# Kuru Integration Specification

**Status:** DRAFT  
**Owner:** Smart Contracts + Security  
**Authority:** Solidity implementation specification

## Purpose

Define V2 smart-contract boundary to Kuru without inventing unverified APIs.

## Requirements

- Pin official Kuru version before coding.
- Specify required inputs/outputs, market verification and retry semantics.
- Keep venue-specific code isolated from bonding math.

## Non-goals

- Does not override docs/launchpad/03-protocol.

## Acceptance criteria

- Implementation mapping is concrete enough to review against code.

## Evidence required

- Foundry/static/deployment evidence as applicable.

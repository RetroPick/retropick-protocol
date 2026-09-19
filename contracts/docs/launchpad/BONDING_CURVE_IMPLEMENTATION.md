# Bonding Curve Implementation

**Status:** DRAFT  
**Owner:** Smart Contracts + Security  
**Authority:** Solidity implementation specification

## Purpose

Map curve spec/math to Solidity.

## Requirements

- Trace each formula to function/storage fields.
- Document transfer ordering, rounding, slippage and reentrancy boundaries.
- Map threshold-crossing behavior.

## Non-goals

- Does not override docs/launchpad/03-protocol.

## Acceptance criteria

- Implementation mapping is concrete enough to review against code.

## Evidence required

- Foundry/static/deployment evidence as applicable.

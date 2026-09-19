# Storage Layout

**Status:** DRAFT  
**Owner:** Smart Contracts + Security  
**Authority:** Solidity implementation specification

## Purpose

Document persistent state relevant to upgrades, tooling and safety.

## Requirements

- List storage groups for launch config, reserves, fees, graduation and roles.
- If no upgradeability is supported, state that explicitly.
- Record layout changes before deployed V2 upgrades/redeployments.

## Non-goals

- Does not override docs/launchpad/03-protocol.

## Acceptance criteria

- Implementation mapping is concrete enough to review against code.

## Evidence required

- Foundry/static/deployment evidence as applicable.

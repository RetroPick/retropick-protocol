# Token Model

**Status:** DRAFT  
**Owner:** Protocol + Smart Contracts  
**Authority:** Canonical token semantics

## Purpose

Define the P0 fungible asset issued by RetroPick Launchpad.

## Requirements

- Use fixed or explicitly capped ERC-20 supply semantics.
- Document name, symbol, decimals, max/initial supply, launch inventory, creator/ecosystem allocations and burn behavior.
- No hidden arbitrary post-launch mint authority in the P0 template.
- Supply allocations must reconcile exactly with total minted/capped supply.

## Non-goals

- Does not define equities/RWA legal rights.
- Does not define Prediction/PRISM assets.

## Acceptance criteria

- Supply-conservation invariant and tests exist.

## Evidence required

- Constructor/deployment config and Foundry tests.

---
id: LP-E2E
type: normative_implementation
status: ready
owner: launchpad-qa
product: launchpad
version: v2
---

# Integration and E2E

Actors: creator A, traders B/C.

Flow: create -> index -> B buy -> C buy -> B sell -> threshold -> secure graduation -> Kuru market -> mature interaction.

Assert transaction hashes/receipts, events, balances, reserves, fees, launch state, indexer entities, API response, browser state and Kuru market identity.
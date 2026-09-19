---
id: LP-FE-TX
type: normative_implementation
status: ready
owner: launchpad-frontend
product: launchpad
version: v2
---

# Web3 Transaction Model

State machine:
`IDLE -> SIMULATING -> NEEDS_APPROVAL? -> AWAITING_SIGNATURE -> SUBMITTED -> PENDING -> CONFIRMED -> INDEXING -> COMPLETE`, with FAILED/REPLACED branches.

Applies to create, approve, buy, sell, graduation actions exposed to users/operators and Kuru mature-market interactions.

Before signature show chain, asset, amount, expected output, min-out/slippage, fee breakdown and relevant launch state.
---
id: LP-SC-OBSERVABLE
type: normative_implementation
status: ready
owner: launchpad-solidity
product: launchpad
version: v2
---

# Events, Errors and Storage

## Event contract
Indexer-critical events include launch creation, trade/fee activity, config changes, graduation sweep/ready/create/rescue and destination-market identity.

## Error contract
Custom errors should map through generated ABI -> SDK error catalog -> UI retryability/message.

## Storage contract
Document fields that define launch economics, launched-token record, fee-policy snapshot, quote economics and graduation phase. Any V2 storage/ABI change after deployment requires explicit version impact review.

Generated ABI/storage metadata should be produced from the compiled Foundry artifacts rather than maintained manually.

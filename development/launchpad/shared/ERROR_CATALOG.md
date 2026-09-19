---
id: LP-ERRORS
type: normative_implementation
status: ready
owner: launchpad-planner
product: launchpad
version: v2
---

# Error Catalog

Stable categories:
wallet, network, validation, allowance, balance, slippage, contract, quote_asset, launch_state, graduation, kuru, indexer, api, metadata, rate_limit.

Each entry defines:
`id -> source error selector/status -> retryable -> user-safe message -> operator diagnostic`.

Solidity custom errors are generated from ABI. Apps must not invent conflicting meanings.

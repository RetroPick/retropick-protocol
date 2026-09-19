---
id: LP-ENV
type: normative_implementation
status: ready
owner: launchpad-devops
product: launchpad
version: v2
---

# Environment Schema

Environments: local, staging, production-candidate.

Each environment resolves:
chain id/network, RPC, deployed contract version/addresses, quote assets, Kuru config, indexer endpoint/sync origin, API URL, web URL, storage, feature flags and operator roles.

A machine-readable environment manifest becomes the runtime source of truth.

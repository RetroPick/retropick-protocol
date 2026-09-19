---
id: LP-DOMAIN
type: normative_implementation
status: ready
owner: launchpad-planner
product: launchpad
version: v2
---

# Shared Domain Model

Canonical TypeScript concepts:
- `Address` from the selected EVM library;
- `LaunchState`: DRAFT | ACTIVE | GRADUATION_READY | GRADUATING | GRADUATED | ARCHIVED, mapped to actual contract phase;
- `Launch`;
- `Token`;
- `QuoteAsset`;
- `Trade`;
- `FeeBreakdown`;
- `Graduation`;
- `KuruMarket`;
- `Creator`;
- `TransactionState`.

All onchain integers use `bigint`. Human decimal strings are presentation/serialization boundaries.

No runtime defines competing LaunchState/Trade/Graduation enums.

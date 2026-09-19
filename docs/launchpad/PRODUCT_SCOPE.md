---
id: LP-SCOPE
type: normative
product: launchpad
version: v2
status: active
---

# Product Scope

This file defines the **Launchpad Core V2 implementation scope**, not the full long-term RetroPick platform scope.

## P0

- standard/meme fixed/capped ERC20 launches;
- token metadata;
- native MON and one qualified stable quote when available;
- bonding buy/sell;
- slippage protection;
- accepted protocol/creator/buyback/anti-snipe economics;
- launch progress and graduation;
- Kuru mature-market handoff;
- discover/create/launch/portfolio/activity UX;
- indexed read model;
- non-custodial metadata/search backend;
- production-shaped test/deployment/observability.

## P1

Creator/community and AI/agent templates, referrals, richer analytics and additional qualified quote assets.

## P2

Direct-market launches, revenue/tax modules, registered external/RWA assets, additional venues and cross-chain distribution.

## Explicit P0 runtime exclusions

- Prediction and PRISM runtime implementation;
- Doorway/cross-chain migration in P0;
- arbitrary quote ERC20s;
- generic venue abstraction without a second real venue;
- server-custodied user trading.

Prediction and PRISM are platform modules under separate research/qualification gates. Their exclusion here means they are not part of Launchpad-Core P0 runtime, not that they are separate products.

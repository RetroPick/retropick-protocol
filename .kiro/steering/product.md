---
inclusion: always
---

# RetroPick Product Steering

RetroPick contains two separate product lanes.

## Launchpad V2

P0 lifecycle:
`create -> bonding market -> buy/sell -> graduation -> Kuru -> mature trading`.

It is non-custodial for normal user economic actions. Doorway/cross-chain is not Launchpad P0.

## Prediction + PRISM

Separate financial semantics under `docs/prism/`. Do not import PRISM backing/settlement semantics into Launchpad work or vice versa.

For implementation, route through root `AGENTS.md`.

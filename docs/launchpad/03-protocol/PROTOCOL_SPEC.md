# RetroPick Launchpad Protocol Specification

**Status:** DRAFT CANONICAL  
**Owner:** Protocol  
**Authority:** Highest launchpad semantic specification below accepted ADRs.

## Lifecycle

```text
DRAFT -> ACTIVE -> GRADUATION_READY -> GRADUATING -> GRADUATED -> ARCHIVED
```

A launch binds a token, supply policy, primary mechanism, quote asset, fee policy, graduation policy and creator metadata/settings.

## Creation

Creation must validate template parameters, quote compatibility, supply/economics bounds and deployment preconditions. A successful create emits enough data to identify the launch and derive the indexed read model.

## Active market

ACTIVE permits primary buy/sell according to the bonding-curve specification. State changes must conserve actual assets subject to explicit fees and rounding.

## Graduation

Reaching the configured threshold makes the launch eligible for graduation. Graduation secures required assets before external market creation. External venue failure must not lose assets or force an unsafe state. Successful destination verification produces GRADUATED.

## Post-graduation

Normal bonding trading is closed according to the implementation state machine. The launch page preserves primary history and exposes the mature market.

## Authority

Only explicit roles may change mutable configuration. Economic parameters intended to be launch-snapshotted must not change retroactively.

## Non-goals

No Prediction/PRISM issuance, hidden asset conversion, unbounded minting, arbitrary creator code or unqualified quote tokens.

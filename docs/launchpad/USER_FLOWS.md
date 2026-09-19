---
id: LP-FLOWS
type: normative
product: launchpad
version: v2
status: active
---

# User Flows

## Creator

1. connect wallet on supported Monad environment;
2. open Create;
3. enter bounded metadata and template parameters;
4. select an approved quote asset;
5. review supply, curve/fees, graduation condition and immutable/snapshotted settings;
6. simulate and sign creation;
7. receive token/curve addresses and transaction evidence;
8. launch becomes discoverable after indexed reconciliation.

## Trader primary market

1. open launch;
2. see freshness-qualified price/reserves/progress and fee disclosure;
3. enter buy/sell;
4. frontend simulates and computes min-out/slippage contract input;
5. ERC20 quote approval if required;
6. user signs transaction;
7. receipt/events are verified;
8. UI reconciles indexer/RPC state.

## Graduation

1. threshold satisfies protocol rule;
2. launch becomes GRADUATION_READY;
3. assets are secured and primary market enters GRADUATING;
4. validated Kuru market creation/configuration executes;
5. destination market is verified;
6. launch becomes GRADUATED;
7. launch page switches mature execution to Kuru while preserving primary history.

## Failure UX

Wallet rejection, wrong network, allowance/balance, slippage, stale indexer, RPC outage and Kuru graduation failure must be explicit. A Kuru failure must never display false GRADUATED state.

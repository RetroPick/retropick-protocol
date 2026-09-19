# Transaction Flows

**Status:** DRAFT  
**Owner:** Architecture + Frontend + Smart Contracts

For each flow record preconditions, wallet transaction, contract method, expected events, indexer updates, frontend transition and failure/retry semantics.

## Create

Validate template/quote/economics -> wallet signs create -> factory deploys/configures -> creation events -> indexer creates Launch -> UI routes to launch page.

## ERC-20 quote buy

Read allowance -> approve if required -> quote buy -> show min-out/fees -> sign buy -> receipt/events -> indexer update -> reconcile balances/progress.

## Sell

Read token balance/allowance if required -> quote sell -> sign -> verify receipt -> update reserves/balance/activity.

## Graduation

Threshold reached -> readiness shown -> graduation actor/caller secures assets -> destination call -> verify Kuru market -> mark/display graduated. Destination failure remains explicit and retryable according to protocol.

## Post-graduation

Launch page disables normal primary trade actions and routes mature trading to the supported Kuru UX/integration while retaining historical primary-market data.

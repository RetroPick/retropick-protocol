# Frontend Architecture

**Status:** DRAFT  
**Owner:** Frontend + Product

## Routes

- `/` and `/discover`: ranked/live launches.
- `/create`: launch wizard and economics review.
- `/launch/[address]`: primary trading, progress, history and graduated market.
- `/profile/[address]`: creator/user activity.
- `/portfolio`: holdings and launch exposure.
- `/activity`: protocol/user event history.

## Components

`LaunchCard`, `LaunchTable`, `CreateLaunchWizard`, `QuoteAssetSelector`, `BondingCurveChart`, `LaunchProgress`, `BuySellPanel`, `GraduationStatus`, `KuruMarketPanel`, `TransactionStepper`, `WalletButton`.

## State sources

Wallet state and chain state come from wallet/provider. Critical economics come from contracts or a freshness-qualified indexer. Search/ranking/metadata may come from backend/cache. Optimistic UI must reconcile with receipts/events before claiming final state.

## Transaction UX

Show expected output, slippage/min-out, fees, quote asset, chain, approval need and graduation status before signature. Pending/reverted/replaced transactions have explicit states.

## Acceptance

Browser E2E completes the golden path without console errors or manual contract invocation.

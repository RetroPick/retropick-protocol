# RetroPick V2 productization

Baseline: c41d35d3a57de05fc26f78476554e352d9b08b56. Branch: codex/v2-productization-performance.
Canonical frontend: apps/retro-ui. Network: Monad Testnet 10143.

## Execution contract
Goal: measured performance, real market data/discovery/charts, coherent Curve/Kuru trading, real wallet hub, referral attribution and qualified funding/send boundaries.
Own: retro-ui, launchpad-sdk, indexer, focused referral-service, associated tests/docs/evidence. Contracts and deployed addresses remain read-only. Preserve the pre-existing create page edit and unrelated files.
Current: sequential launch/Kuru/history reads, document navigation, incomplete query API, live fixture leakage and incomplete claims/order UI.
Target: concurrent progressive queries, persistent wallet/cache, receipt-seeded direct trading, exact indexed projections and wallet-only economic writes.
Migration: measurements -> read/query/navigation -> indexer -> charts/discovery/search -> unified trading/claims -> referrals/send -> qualification/handoff.

## Approved decisions
- React Query 5.104.1 and Lightweight Charts 5.2.1; no new contract or generic referral SDK.
- Any-pair monetary rankings group by quote asset, native MON first. No test MON USD valuation.
- Near graduation is a UI category at 8000 bps, not protocol state.
- Referral first touch persists locally 30 days until verified ownership association, then referrer is immutable. Confirmed launches and Curve trades qualify; Kuru taker executions qualify, not resting orders or maker fills. Amounts aggregate per quote asset. Referral payouts are not enabled.
- Every chain-10143 fiat capability is disabled until exact official asset/network/environment/country/flow support is proven. Same-chain Send is separate.
- Static checks, browser/mobile regressions, fresh testnet receipts/events and measured before/after evidence are mandatory. Missing evidence is never a pass.
- Large visual redesign is delegated to the subsequent Kimi campaign.

## Specialist ownership
- Root: frontend query/navigation/chart/discovery/search/create/detail, dependency installation, performance measurements and final integration/qualification.
- SDK specialist: SDK (except read-model), ticket components, transaction pipeline, live Earn/Portfolio and safe Send.
- Indexer specialist: apps/indexer and SDK read-model types.
- Referral specialist: referral-service, attribution UI/client, fiat capability boundary and product documentation.

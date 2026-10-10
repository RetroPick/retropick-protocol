# Kuru Consumer Trading App — AllInOne Agent Integration Specification
**RetroPick Metropolis 2026 | Draft plan 2026-10-11 | Deadline 2026-10-14 10:59 GMT+7**
**Eligibility:** Onchain Finance & Trading. **Prize:** $5,000 single. **Status:** NOT IMPLEMENTED/NOT PROVEN unless evidence linked below. Read `00-MASTER-PLAN.md` and `09-AGENTS-HANDOFF.md` first.

## Product thesis
Fast creator-community trading terminal with real orderbook and transparent custody. Do not add a sponsor logo without the sponsor's required working feature.

## Exact integration boundary
Inspect before editing: `apps/web/features/live/kuru.tsx`, `apps/web/lib/live/kuru.ts`, `apps/web/lib/live/wallet.tsx`, `apps/web/lib/live/model.ts`.
Current V2 is live Monad Testnet 10143, Factory→Curve→Coordinator→Kuru; `deployments/monad-testnet/v2.json` is deployment registry. Do not use obsolete Base Sepolia Go/fe-v1 as patch targets. All contract names, methods and sponsor SDK method names MUST be reverified against installed versions; do not invent API signatures.

## Sponsor eligibility and proof gate
**Kuru Consumer Trading App** must deliver the actual integrated feature described below, not a mock. Track Onchain Finance & Trading; prize $5,000 single. Read official bounty wording captured in user portal and recheck at submission. Demo must be on deployed Monad product, with sponsor-specific working evidence. This document is a development specification, not an eligibility certification.

## Architecture and implementation plan
Preserve existing order/fill/cancel; improve responsive/mobile touch UX, wallet states, quote and precision validation, order status, real depth, fee disclosure, chain mismatch and staleness; target degen traders, creators and market makers; make discovery→market→order→portfolio path intuitive; run Playwright fresh-browser/two-wallet E2E; gather real waitlist and tester feedback with consent.

### Agent execution checklist
1. Freeze baseline: `git rev-parse HEAD`, branch and working tree; inspect source and SDK docs; write version/chain compatibility matrix.
2. Build read-only adapter first with schema validation, typed errors, idempotency key, deadline and explicit supported-network checks.
3. Implement write flow only after simulation/quote checks and signer boundary review; record exact authorization and destination.
4. Integrate behind an independent feature flag and a truthful disabled state. No secret exposed through `NEXT_PUBLIC_*`.
5. Add telemetry for request ID, chain, block, tx hash, status, duration and sanitized failure category; redact sensitive data.
6. Add unit tests, failure/retry tests, real integration smoke and Playwright/browser or CLI E2E.
7. Record sponsor evidence under `evidence/hackathon/metropolis/sponsors/06-sponsor/`; write submission answer only after proof.
8. Disable flag or revert additive integration if test gates fail; never mutate existing V2 deployment or custody.

## State machine and security requirements
Proposed feature state: DISABLED → CHECKING → READY → ACTION_PENDING → CONFIRMED, with BLOCKED, FAILED, EXPIRED and RECOVERY_REQUIRED branches. For transaction-dependent features, distinguish submitted from confirmed and reconciled. Use onchain receipts and supported sponsor APIs as authoritative. BigInt atomic amounts, bounded allowances, chain and contract allowlists, replay/idempotency protection, retry backoff and no unbounded automated trades.

### Mandatory adversarial cases
Android tap failure; stale RPC; quote drift; post-only reverts; wallet rejected; margin withdrawal confusion; low depth; overclaiming organic demand.

## Tests and acceptance
**Unit:** serialization, decimal/chain validation, stale data, state transition, wrong signature, timeout, replay, failure recovery.
**Integration:** sponsor endpoint/SDK using current pinned version, confirmed contract identity, network compatibility, provider outage.
**Onchain:** receipts and actual contract state changes where required; never represent simulated events as real transactions.
**E2E:** clean browser/profile, mobile when applicable, two-wallet flows when relevant, no inaccessible login.
**Definition of done:** Fresh mobile+desktop wallet launch, two actors real order/fill/cancel, video, user evidence methodology, roadmap. Attach exact URLs/receipts, commit SHA, SDK versions, commands and outputs; fail closed if unavailable.

## Sponsor demo
Browse creator launch→inspect Kuru book→deposit→limit order→fill/cancel, 120 seconds. Sponsor-specific limit is normally <=2 minutes; MetaMask permits <=5 minutes. Do not claim a successful transaction without a receipt.

## Submission response template (fill after evidence)
"RetroPick integrates Kuru Consumer Trading App to fast creator-community trading terminal with real orderbook and transparent custody. The integration operates on Monad Testnet [chainId and verified contract address]. Our implementation uses [exact official SDK/API endpoint, pinned version] in [exact repo paths]. A user can [actual completed action], evidenced by [real tx hash / CLI simulation / GraphQL result]. Safety controls include [verified controls]. Current limitations: [actual limitations]."

## 30/60/90-day expansion
**30 days:** harden integration, run supervised external tester sessions and fix reliability gaps.
**60 days:** security review, observability and user cohort/market-quality analytics; expand only verified supported networks.
**90 days:** gated mainnet-readiness decision, commercial pilots and measured retention; no production release without risk/legal/operational gates.

## Rollback
Disable only this sponsor's feature flag, revert its isolated UI/adapter PR, retain historical proof and deployed contracts; never rollback V2 custody by changing onchain owner or withdrawing locked liquidity.

## Official starting points
https://docs.kuru.io/contracts/OrderBook


---
## 2026-10-11 validated consumer Kuru integration and measurable UX edge
**SOURCE-VERIFIED:** https://docs.kuru.io/sdk/deploy-market differentiates `MonadDeployer` from Kuru Router and describes market-specific precision, liquidity and vault seeding. https://docs.kuru.io/contracts/OrderBook documents orderbook mechanics. **REPO-VERIFIED:** `apps/web/features/live/kuru.tsx` already places `addBuyOrder` and `addSellOrder` and cancels `batchCancelOrders`; `apps/web/lib/live/kuru.ts` checks Router registration, market/quote token, MarginAccount, vault and implementations, obtains L2 book and recent trades (100 blocks). This is closer to the sponsor bar than a new trading frontend mock.

### Build from actual code, not from figma fixtures
```
apps/web/features/live/kuru.tsx          # real Kuru limit order, margin deposit/withdraw, cancel
apps/web/lib/live/kuru.ts                # readKuru, getMarketParams, bestBidAsk, getL2Book, event decode
apps/web/lib/live/wallet.tsx             # EIP1193 provider, simulates before signature and receipt
apps/web/lib/live/model.ts              # V2 launch + graduation custody and native MON quote
apps/web/features/launchpad/token-detail.tsx  # reconcile discoverability and real trading entry
apps/web/features/create-market/wizard.tsx    # DEMO DRAFT ONLY, not contract creation
apps/web/features/prism/prism.tsx              # ILLUSTRATIVE, not live trading
```
The current `apps/web/README.md` is fixture-oriented and may be stale; the code has both live V2 components and simulated prediction/PRISM presentation. Inspect actual routing and `NEXT_PUBLIC_DATA_MODE` before claims. A beautifully rendered illustrative PRISM book does NOT qualify as a live Kuru trading experience.

### Most valuable 1-day improvements
1. Add a **trade readiness panel** showing `chainId`, verified market/quote, wallet/MarginAccount balances, market phase, indexed last trade, observed block/freshness, min/max size, tick and actual maker/taker fee.
2. Quote maker order preview using deterministic integer arithmetic, avoid `Number` except for ABI types proven safe (< uint32), cap input and enforce tick precision. Explain a post-only order can revert if executable immediately; show error and recommended alternative.
3. Clearly distinguish *best bid/ask including Kuru AMM* from *resting L2 limit depth*. Never label no resting orders as "zero liquidity" if AMM best price is present. Defer market execution until verified SDK or contract method/simulation supports it.
4. Add order status reconciler: `SUBMITTED` → `PLACED` → `PARTIALLY_FILLED` → `FILLED` or `CANCELLED`. A mined order transaction is not the same as executed fill. Use owner and orderId from receipts, not browser-local assumptions. Handle page refresh.
5. Run Playwright against the actual deployed V2 route on Chromium/mobile Android viewport with touch, wallet connect/switch, deposit, order, reject, cancel and back-navigation. Don't regress existing UIs.
6. Gather real human trader feedback and funnel signals (consented 5+ first-time journeys). Founder-reported waiting list and social reach are interest indicators, not retention proof.

### Bounty-winning innovation — **"Bond to Book" continuous trading**
A single visual asset provenance panel displays bonding curve history, graduation ledger, protected LP proof and live Kuru orderbook execution. It makes a trust-first retail trading terminal for degen creators and market makers without the AMM-only slippage story. Judge demo proves an actual two-wallet order/match/cancel and an understandable trade status lifecycle, not a promo feed.

### Non-negotiable evidence
One live mobile-responsive route, actual wallet-signed testnet order and fill (two independent actors), verified vault/lock proof, price/tick/fee check, rejection tests, screenshot/video and specific market evidence. Describe it as an **unaudited Monad Testnet candidate**, not a finished mainnet CEX.

# Aurora Intents — AllInOne Agent Integration Specification
**RetroPick Metropolis 2026 | Draft plan 2026-10-11 | Deadline 2026-10-14 10:59 GMT+7**
**Eligibility:** All tracks. **Prize:** $5,000 pool: $2,500 / $1,500 / $1,000. **Status:** NOT IMPLEMENTED/NOT PROVEN unless evidence linked below. Read `00-MASTER-PLAN.md` and `09-AGENTS-HANDOFF.md` first.

## Product thesis
Fund a Monad Kuru trade from another supported chain. Do not add a sponsor logo without the sponsor's required working feature.

## Exact integration boundary
Inspect before editing: `apps/web/features/live/kuru.tsx`, `apps/web/lib/live/client.ts`, `apps/web/lib/live/model.ts`, `apps/web/app/api/chain/route.ts`.
Current V2 is live Monad Testnet 10143, Factory→Curve→Coordinator→Kuru; `deployments/monad-testnet/v2.json` is deployment registry. Do not use obsolete Base Sepolia Go/fe-v1 as patch targets. All contract names, methods and sponsor SDK method names MUST be reverified against installed versions; do not invent API signatures.

## Sponsor eligibility and proof gate
**Aurora Intents** must deliver the actual integrated feature described below, not a mock. Track All tracks; prize $5,000 pool: $2,500 / $1,500 / $1,000. Read official bounty wording captured in user portal and recheck at submission. Demo must be on deployed Monad product, with sponsor-specific working evidence. This document is a development specification, not an eligibility certification.

## Architecture and implementation plan
Validate supported source/destination chain+token and testnet/mainnet routing with official Aurora API; build server-only quote/status adapter and user-facing fund-and-trade; record route quote, expiry, minOutput, destination recipient, source tx, solver status, destination receipt; reconcile actual destination balance before allowing existing wallet-signed Kuru margin deposit/trade; never credit from frontend callback.

### Agent execution checklist
1. Freeze baseline: `git rev-parse HEAD`, branch and working tree; inspect source and SDK docs; write version/chain compatibility matrix.
2. Build read-only adapter first with schema validation, typed errors, idempotency key, deadline and explicit supported-network checks.
3. Implement write flow only after simulation/quote checks and signer boundary review; record exact authorization and destination.
4. Integrate behind an independent feature flag and a truthful disabled state. No secret exposed through `NEXT_PUBLIC_*`.
5. Add telemetry for request ID, chain, block, tx hash, status, duration and sanitized failure category; redact sensitive data.
6. Add unit tests, failure/retry tests, real integration smoke and Playwright/browser or CLI E2E.
7. Record sponsor evidence under `evidence/hackathon/metropolis/sponsors/01-sponsor/`; write submission answer only after proof.
8. Disable flag or revert additive integration if test gates fail; never mutate existing V2 deployment or custody.

## State machine and security requirements
Proposed feature state: DISABLED → CHECKING → READY → ACTION_PENDING → CONFIRMED, with BLOCKED, FAILED, EXPIRED and RECOVERY_REQUIRED branches. For transaction-dependent features, distinguish submitted from confirmed and reconciled. Use onchain receipts and supported sponsor APIs as authoritative. BigInt atomic amounts, bounded allowances, chain and contract allowlists, replay/idempotency protection, retry backoff and no unbounded automated trades.

### Mandatory adversarial cases
Route not supported; quote expired; source tx reorg; solver timeout; partial delivery; destination asset mismatch (existing Kuru market quotes MON, not arbitrary stablecoin); refund or recovery.

## Tests and acceptance
**Unit:** serialization, decimal/chain validation, stale data, state transition, wrong signature, timeout, replay, failure recovery.
**Integration:** sponsor endpoint/SDK using current pinned version, confirmed contract identity, network compatibility, provider outage.
**Onchain:** receipts and actual contract state changes where required; never represent simulated events as real transactions.
**E2E:** clean browser/profile, mobile when applicable, two-wallet flows when relevant, no inaccessible login.
**Definition of done:** Actual external-chain source tx, real destination settlement, wallet balance delta, downstream Kuru deposit and order receipt. Attach exact URLs/receipts, commit SHA, SDK versions, commands and outputs; fail closed if unavailable.

## Sponsor demo
Source chain→Aurora status→Monad destination→Kuru order, 120 seconds. Sponsor-specific limit is normally <=2 minutes; MetaMask permits <=5 minutes. Do not claim a successful transaction without a receipt.

## Submission response template (fill after evidence)
"RetroPick integrates Aurora Intents to fund a monad kuru trade from another supported chain. The integration operates on Monad Testnet [chainId and verified contract address]. Our implementation uses [exact official SDK/API endpoint, pinned version] in [exact repo paths]. A user can [actual completed action], evidenced by [real tx hash / CLI simulation / GraphQL result]. Safety controls include [verified controls]. Current limitations: [actual limitations]."

## 30/60/90-day expansion
**30 days:** harden integration, run supervised external tester sessions and fix reliability gaps.
**60 days:** security review, observability and user cohort/market-quality analytics; expand only verified supported networks.
**90 days:** gated mainnet-readiness decision, commercial pilots and measured retention; no production release without risk/legal/operational gates.

## Rollback
Disable only this sponsor's feature flag, revert its isolated UI/adapter PR, retain historical proof and deployed contracts; never rollback V2 custody by changing onchain owner or withdrawing locked liquidity.

## Official starting points
https://docs.intents.aurora.dev/


---
## 2026-10-11 verified integration supplement — REAL destination delivery, not widget-only
**SOURCE-VERIFIED:** Aurora publishes a maintained Next.js example at https://github.com/aurora-is-near/hypercore-deposits-demo . It uses `@aurora-is-near/intents-swap-widget-standalone` exports `Widget`, `WidgetConfigProvider`, `useAppKitWallet`, plus the widget stylesheet, and renders only after mounting. The example config has `sendAddress`, `defaultTargetToken`, `allowedChainsList`, `showTransactionHistory`, and `showConversionPreview`. It is a **Hypercore** demo and does NOT prove an order to **Monad Testnet** is supported. https://intents.near.org/overview lists Monad but does not promise chain 10143 or native MON delivery. Verify the exact quote before integrating. A separate generated API client `@aurora-is-near/intents-connect-sdk` exists; inspect package type declarations and OpenAPI, not copied constructor examples (npm documentation is inconsistent). https://www.npmjs.com/package/@aurora-is-near/intents-connect-sdk .

### Proposed files and adapter boundary
```
apps/web/features/fund-and-trade/route-picker.tsx        # UX: source token, source chain, route estimate, failure recovery
apps/web/lib/integrations/aurora/route-schema.ts          # strict per-chain quote assets, max input, min output, expiry
apps/web/lib/integrations/aurora/intent-state.ts          # durable state machine with request-id
apps/web/app/api/integrations/aurora/route.ts             # optional server adapter ONLY after SDK/API auth inspection
evidence/hackathon/metropolis/sponsors/aurora/*          # quote, source proof, destination proof, Kuru tx
```
Existing `apps/web/lib/live/client.ts` targets Monad 10143, `lib/live/model.ts` rejects non-native-MON quote V2 launches, and `features/live/kuru.tsx` deposits native MON into the verified Kuru MarginAccount. Hence **Base USDC → Monad USDC is not sufficient** for the current MON-quoted live Kuru orderbook. Either prove an Aurora route that outputs native MON to the user, or integrate a separately verified conversion. If only Monad **mainnet 143** is supported, DO NOT point the production widget at Monad testnet 10143.

### Fastest safe spike (max 4 engineer-hours)
1. Read official widget source and installed npm package exports, document version, chain config and recipient binding. The example's hardcoded demo `apiKey` and sample recipient must NEVER be reused.
2. Inspect source chain availability, supported destination network and precise *asset identifier* from live provider/API. Query source→destination quote and record expiry, minimum output, route/solver fees and refund semantics. STOP if chainId 10143 + a usable quote asset is unavailable.
3. On a funded tiny-value real route, require source tx hash, provider signed quote/reference, destination chain transfer logs and wallet balance change. Preserve the quote and data needed for refunds server-side with no secrets.
4. Only after confirmed arrival, call existing wallet-mediated Kuru deposit, simulate order with `readKuru`, and record order tx. The bridge MUST NOT sign Kuru orders or receive user's order-control keys.
5. Expose `source confirmed` → `solver pending` → `destination confirmed` → `Kuru margin funded` → `order accepted/filled` separately; optional user execution on destination is a SECOND user-approved transaction unless atomic deposit-and-execute is proven by provider API.
6. Document unavailable routes with a disabled UI and honest `NOT_SUPPORTED_ON_THIS_NETWORK` rather than a fabricated demo.

### High-signal innovation — **Intents to First Order**
Persist only non-sensitive intent provenance and provide a one-screen audit timeline. Prove conversion of externally held assets into *real executable Kuru liquidity* and display a link to BOTH source/destination receipts, exact realized output versus quote, and explicit refund status. This is stronger than embedding a bridge page because the core user benefit is getting to a completed first trade.

### Security tests / acceptance
Wrong recipient; quote substitution; expired quote; token symbols with different addresses/decimals; source reorg; destination delayed; partial solver settlement; refund; duplicate status callback; source funds delivered to wallet but not MarginAccount; insufficient native MON for destination gas. **Evidence gate:** one externally funded transfer actually arrives on Monad and is consumed in a RetroPick action. Otherwise **bounty NOT QUALIFIED**.

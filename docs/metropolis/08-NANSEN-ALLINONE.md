# Nansen Best Use — AllInOne Agent Integration Specification
**RetroPick Metropolis 2026 | Draft plan 2026-10-11 | Deadline 2026-10-14 10:59 GMT+7**
**Eligibility:** All tracks. **Prize:** $5,000 pool: $2,000 / $1,500 / $1,000 / $500. **Status:** NOT IMPLEMENTED/NOT PROVEN unless evidence linked below. Read `00-MASTER-PLAN.md` and `09-AGENTS-HANDOFF.md` first.

## Product thesis
Creator launch risk and wallet concentration intelligence, actionable not raw JSON. Do not add a sponsor logo without the sponsor's required working feature.

## Exact integration boundary
Inspect before editing: `apps/indexer/src/project.ts`, `apps/web/lib/live/model.ts`, `new apps/web/app/api/intelligence/route.ts and apps/web/features/intelligence/`.
Current V2 is live Monad Testnet 10143, Factory→Curve→Coordinator→Kuru; `deployments/monad-testnet/v2.json` is deployment registry. Do not use obsolete Base Sepolia Go/fe-v1 as patch targets. All contract names, methods and sponsor SDK method names MUST be reverified against installed versions; do not invent API signatures.

## Sponsor eligibility and proof gate
**Nansen Best Use** must deliver the actual integrated feature described below, not a mock. Track All tracks; prize $5,000 pool: $2,000 / $1,500 / $1,000 / $500. Read official bounty wording captured in user portal and recheck at submission. Demo must be on deployed Monad product, with sponsor-specific working evidence. This document is a development specification, not an eligibility certification.

## Architecture and implementation plan
Confirm paid API entitlement, Monad chain coverage, exact endpoints and redistribution license; server-only credential; map supported holder/flow/Smart Money data to verified creator launch assets; combine with Envio/Kuru data to produce explainable concentration/flow flags, source timestamp and confidence; avoid unsupported 'Smart Money' claims for tiny testnet markets; degrade gracefully if no coverage.

### Agent execution checklist
1. Freeze baseline: `git rev-parse HEAD`, branch and working tree; inspect source and SDK docs; write version/chain compatibility matrix.
2. Build read-only adapter first with schema validation, typed errors, idempotency key, deadline and explicit supported-network checks.
3. Implement write flow only after simulation/quote checks and signer boundary review; record exact authorization and destination.
4. Integrate behind an independent feature flag and a truthful disabled state. No secret exposed through `NEXT_PUBLIC_*`.
5. Add telemetry for request ID, chain, block, tx hash, status, duration and sanitized failure category; redact sensitive data.
6. Add unit tests, failure/retry tests, real integration smoke and Playwright/browser or CLI E2E.
7. Record sponsor evidence under `evidence/hackathon/metropolis/sponsors/08-sponsor/`; write submission answer only after proof.
8. Disable flag or revert additive integration if test gates fail; never mutate existing V2 deployment or custody.

## State machine and security requirements
Proposed feature state: DISABLED → CHECKING → READY → ACTION_PENDING → CONFIRMED, with BLOCKED, FAILED, EXPIRED and RECOVERY_REQUIRED branches. For transaction-dependent features, distinguish submitted from confirmed and reconciled. Use onchain receipts and supported sponsor APIs as authoritative. BigInt atomic amounts, bounded allowances, chain and contract allowlists, replay/idempotency protection, retry backoff and no unbounded automated trades.

### Mandatory adversarial cases
API access denied; rate limits; stale/missing chain coverage; redistribution prohibited; misleading labels; leaking key; model hallucination.

## Tests and acceptance
**Unit:** serialization, decimal/chain validation, stale data, state transition, wrong signature, timeout, replay, failure recovery.
**Integration:** sponsor endpoint/SDK using current pinned version, confirmed contract identity, network compatibility, provider outage.
**Onchain:** receipts and actual contract state changes where required; never represent simulated events as real transactions.
**E2E:** clean browser/profile, mobile when applicable, two-wallet flows when relevant, no inaccessible login.
**Definition of done:** Recorded permitted endpoint response category, derived score with source attribution, functional dashboard and redacted logs. Attach exact URLs/receipts, commit SHA, SDK versions, commands and outputs; fail closed if unavailable.

## Sponsor demo
Open market→explain risk score→inspect source and actionable caution, 120 seconds. Sponsor-specific limit is normally <=2 minutes; MetaMask permits <=5 minutes. Do not claim a successful transaction without a receipt.

## Submission response template (fill after evidence)
"RetroPick integrates Nansen Best Use to creator launch risk and wallet concentration intelligence, actionable not raw json. The integration operates on Monad Testnet [chainId and verified contract address]. Our implementation uses [exact official SDK/API endpoint, pinned version] in [exact repo paths]. A user can [actual completed action], evidenced by [real tx hash / CLI simulation / GraphQL result]. Safety controls include [verified controls]. Current limitations: [actual limitations]."

## 30/60/90-day expansion
**30 days:** harden integration, run supervised external tester sessions and fix reliability gaps.
**60 days:** security review, observability and user cohort/market-quality analytics; expand only verified supported networks.
**90 days:** gated mainnet-readiness decision, commercial pilots and measured retention; no production release without risk/legal/operational gates.

## Rollback
Disable only this sponsor's feature flag, revert its isolated UI/adapter PR, retain historical proof and deployed contracts; never rollback V2 custody by changing onchain owner or withdrawing locked liquidity.

## Official starting points
https://docs.nansen.ai/


---
## 2026-10-11 verified Nansen endpoint/redistribution integration
**SOURCE-VERIFIED:** https://docs.nansen.ai/api/token-god-mode/holders documents `POST https://api.nansen.ai/api/v1/tgm/holders`, header **`apiKey`**, JSON `chain:"monad"`, `token_address`, pagination and holder filters. https://docs.nansen.ai/api/smart-money lists Monad among chains. But coverage is not a guarantee for **Monad Testnet 10143** or newly created test tokens. https://docs.nansen.ai/guides/redistribution-guide expressly restricts or prohibits several endpoints:
- **Allowed with attribution:** `tgm/flow-intelligence`, `tgm/flows`, `tgm/who-bought-sold`, `tgm/token-screener`, `tgm/transfers` (subject to latest terms).
- **Restricted; approval + significant modification:** `tgm/holders` with Smart Money filter.
- **Prohibited for public redistribution:** `smart-money/holdings`, `smart-money/dex-trades`, `tgm/pnl-leaderboard`, Smart Money labels, and other listed feeds. Raw use can be permitted privately, but publicly displaying even an "elite wallet" label can violate licensing. Recheck live licensing before each public feature.

### Fast working server-only proof
```bash
# Set NANSEN_API_KEY in server environment, never paste it into logs or client bundle.
curl -sS -X POST 'https://api.nansen.ai/api/v1/tgm/holders' \
  -H "apiKey: ${NANSEN_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{"chain":"monad","token_address":"0xVERIFIED_MAINNET_TOKEN","pagination":{"page":1,"per_page":10}}'
```
**Important:** example placeholder must be replaced with a verified real Monad **mainnet** token, not an arbitrary 10143 asset. Test status, API entitlement, per-request credits and data freshness before public deployment. API docs say all API endpoints use POST with JSON; don't copy old GET/querystring examples. Add request timeout, caching within current license, 429 backoff and quota circuit breaker.

### Product architecture
```
apps/web/app/api/integrations/nansen/route.ts       # private key auth + endpoint allowlist, rate limiting
apps/web/lib/integrations/nansen/validate.ts        # Zod response/error/freshness and chain map
apps/web/features/market-intelligence/risk.tsx       # explanatory combined risk, Nansen attribution
apps/indexer/src/project.ts                         # existing independent onchain projections
```
Never expose Nansen API key or raw prohibited Smart Money data to client, screenshots, CSV downloads, logs or public GraphQL. Server model must annotate `network:mainnet` and `dataAvailable:false` explicitly when the testnet token is missing. Separate independently computed V2 testnet holder concentration from Nansen mainnet signal; do not combine incomparable networks into one "live" score.

### Sponsor-winning innovation — **Risk Before Ape**
A trader sees provenance-aware red flags (concentration from RetroPick's indexed holder snapshot, thin executable Kuru depth, high creator allocation, unusual *permitted* Nansen flows on supported mainnet comparables) with explainable calculations and timestamps. A naive "Smart Money is bullish" badge is less defensible and may redistribute prohibited data. Show Nansen contribution as a genuinely **decision-changing** feature: a pre-trade risk explainer that can recommend reduce-size or postpone based on actual metrics.

### Eligibility test and cutoff
If no API key, paid entitlement or testnet asset coverage, Nansen-specific user flow remains disabled. If only unrelated mainnet data is accessible, a labeled comparative research feature may be useful but does NOT justify saying Nansen monitors the live Monad Testnet token. Capture request endpoint, redacted response schema, license attribution screenshot, calculated metric and user-facing changed decision. An opaque AI score with no grounded components is insufficient.

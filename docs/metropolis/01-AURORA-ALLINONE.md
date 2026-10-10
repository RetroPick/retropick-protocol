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

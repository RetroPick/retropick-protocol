# Envio Best Use — AllInOne Agent Integration Specification
**RetroPick Metropolis 2026 | Draft plan 2026-10-11 | Deadline 2026-10-14 10:59 GMT+7**
**Eligibility:** All tracks. **Prize:** $1,000 single. **Status:** NOT IMPLEMENTED/NOT PROVEN unless evidence linked below. Read `00-MASTER-PLAN.md` and `09-AGENTS-HANDOFF.md` first.

## Product thesis
Real-time launch graduation and Kuru market-quality index. Do not add a sponsor logo without the sponsor's required working feature.

## Exact integration boundary
Inspect before editing: `apps/indexer/src/project.ts`, `apps/web/lib/live/kuru.ts`, `new integrations/envio/config.yaml schema.graphql src/EventHandlers.ts`.
Current V2 is live Monad Testnet 10143, Factory→Curve→Coordinator→Kuru; `deployments/monad-testnet/v2.json` is deployment registry. Do not use obsolete Base Sepolia Go/fe-v1 as patch targets. All contract names, methods and sponsor SDK method names MUST be reverified against installed versions; do not invent API signatures.

## Sponsor eligibility and proof gate
**Envio Best Use** must deliver the actual integrated feature described below, not a mock. Track All tracks; prize $1,000 single. Read official bounty wording captured in user portal and recheck at submission. Demo must be on deployed Monad product, with sponsor-specific working evidence. This document is a development specification, not an eligibility certification.

## Architecture and implementation plan
Pin Envio HyperIndex version and supported Monad chain source; index actual deployed Factory TokenLaunched, Coordinator GraduationSecured/Completed and Kuru OrderCreated/Trade/OrdersCanceled from verified ABI; dynamic market registration must use supported Envio factory mechanisms; derive MarketLifecycle, Trade, CreatorStats, Volume and LiquidityQuality entities; expose GraphQL with block freshness and consume it on real market feed; preserve existing authoritative chain receipts.

### Agent execution checklist
1. Freeze baseline: `git rev-parse HEAD`, branch and working tree; inspect source and SDK docs; write version/chain compatibility matrix.
2. Build read-only adapter first with schema validation, typed errors, idempotency key, deadline and explicit supported-network checks.
3. Implement write flow only after simulation/quote checks and signer boundary review; record exact authorization and destination.
4. Integrate behind an independent feature flag and a truthful disabled state. No secret exposed through `NEXT_PUBLIC_*`.
5. Add telemetry for request ID, chain, block, tx hash, status, duration and sanitized failure category; redact sensitive data.
6. Add unit tests, failure/retry tests, real integration smoke and Playwright/browser or CLI E2E.
7. Record sponsor evidence under `evidence/hackathon/metropolis/sponsors/05-sponsor/`; write submission answer only after proof.
8. Disable flag or revert additive integration if test gates fail; never mutate existing V2 deployment or custody.

## State machine and security requirements
Proposed feature state: DISABLED → CHECKING → READY → ACTION_PENDING → CONFIRMED, with BLOCKED, FAILED, EXPIRED and RECOVERY_REQUIRED branches. For transaction-dependent features, distinguish submitted from confirmed and reconciled. Use onchain receipts and supported sponsor APIs as authoritative. BigInt atomic amounts, bounded allowances, chain and contract allowlists, replay/idempotency protection, retry backoff and no unbounded automated trades.

### Mandatory adversarial cases
Reorgs, event duplication, missing dynamic market, schema migrations, indexing lag, bad token decimals, incorrectly interpreted trade notional.

## Tests and acceptance
**Unit:** serialization, decimal/chain validation, stale data, state transition, wrong signature, timeout, replay, failure recovery.
**Integration:** sponsor endpoint/SDK using current pinned version, confirmed contract identity, network compatibility, provider outage.
**Onchain:** receipts and actual contract state changes where required; never represent simulated events as real transactions.
**E2E:** clean browser/profile, mobile when applicable, two-wallet flows when relevant, no inaccessible login.
**Definition of done:** Deployed indexer endpoint, config/schema/handlers, live GraphQL rows matched to explorer logs, UI derived metric changes. Attach exact URLs/receipts, commit SHA, SDK versions, commands and outputs; fail closed if unavailable.

## Sponsor demo
Launch or trade→event→HyperIndex→GraphQL→live dashboard, 120 seconds. Sponsor-specific limit is normally <=2 minutes; MetaMask permits <=5 minutes. Do not claim a successful transaction without a receipt.

## Submission response template (fill after evidence)
"RetroPick integrates Envio Best Use to real-time launch graduation and kuru market-quality index. The integration operates on Monad Testnet [chainId and verified contract address]. Our implementation uses [exact official SDK/API endpoint, pinned version] in [exact repo paths]. A user can [actual completed action], evidenced by [real tx hash / CLI simulation / GraphQL result]. Safety controls include [verified controls]. Current limitations: [actual limitations]."

## 30/60/90-day expansion
**30 days:** harden integration, run supervised external tester sessions and fix reliability gaps.
**60 days:** security review, observability and user cohort/market-quality analytics; expand only verified supported networks.
**90 days:** gated mainnet-readiness decision, commercial pilots and measured retention; no production release without risk/legal/operational gates.

## Rollback
Disable only this sponsor's feature flag, revert its isolated UI/adapter PR, retain historical proof and deployed contracts; never rollback V2 custody by changing onchain owner or withdrawing locked liquidity.

## Official starting points
https://docs.envio.dev/docs/HyperIndex/overview


---
## 2026-10-11 validated Envio V3 / Monad / agent-skills implementation
**SOURCE-VERIFIED:** https://docs.envio.dev/docs/HyperIndex/supported-networks lists Monad mainnet 143 and **Monad Testnet 10143**, with native HyperSync `https://10143.hypersync.xyz` and HyperRPC `https://10143.rpc.hypersync.xyz`. This is a real low-risk sponsor integration, not a conjectural port. https://docs.envio.dev/docs/HyperIndex/overview documents native GraphQL, reorg handling and dynamic factory contracts; https://docs.envio.dev/docs/HyperIndex/quickstart-with-ai documents AI workflows, `envio skills update`, `envio tools search-docs` and generated test infrastructure.

### Fast path using OFFICIAL Envio CLI
```bash
node --version                          # recommended >=22
cd integrations
mkdir -p envio && cd envio
pnpx envio init                         # choose Contract Import > Local ABI if explorer unsupported
# Copy verified ABI(s) from ../../deployments/monad-testnet/abi/
# Fill actual deployed Factory/Coordinator address, chainId=10143 and reasonable deployment start block.
# Set ENVIO_API_TOKEN in ignored .env (local HyperSync requires it, not Git tracked).
envio tools search-docs                 # use installed CLI if supported by pinned version
envio skills update                     # load current agent-specific guidance if installed
pnpm test                               # generated createTestIndexer() harness after init
```
The docs say local/self-hosted **HyperSync** requires a token from https://envio.dev/app/api-tokens, while Envio Cloud gets special access. A raw external-RPC-only datasource can operate without HyperSync token but then you MUST prove you meaningfully integrated an actual Envio product. Envio's AI quickstart recommends TDD with `createTestIndexer()` and a generated `config.yaml`, `schema.graphql`, `src/handlers` project. Pin exact CLI and config syntax after initialization rather than inventing a V3 schema from memory.

### Exact index scope (initial snapshot before dynamic market support)
- Factory `RetroPickLaunchFactoryV2` emitted `TokenLaunched` (verify signature from ABI).
- Coordinator `GraduationCoordinatorV2`: `LaunchCommitted`, `GraduationSecured`, `GraduationCompleted`.
- Live Kuru verified market `0x1F5dE72616a7fe645Cf45aC66dfce8Ac7452C57F`: `OrderCreated`, `Trade`, `OrdersCanceled`, from `apps/web/lib/live/kuru.ts` ABI.
- Candidate derived entities: `Launch` (phase, token, curve, creator), `Graduation` (secured/completed block, verified market), `MarketTrade` (tx+log unique key, maker/taker, exact base size, quote), `MarketQuality` (elapsed time from graduation, last finalized trade, trade count/volume and data freshness).
- Kuru trade events are not necessarily price times size in human units; compare `Trade.price`, `filledSize`, market decimals, contract precision and maker/taker flags to actual transaction receipts before defining notional.
- `apps/indexer/src/project.ts` already has an independent TS projection, so Envio may serve as an **auditable separate derived read-model**. Do not dub it authoritative ledger state or double-count volumes.

### Dynamic factory-created markets
First get known deployed market indexing working. Then use official Envio documented **dynamic contract registration** to register future market addresses from `GraduationCompleted`. Handler must avoid duplicate registration and survive reorg. If dynamic registration isn't validated within 4h, deliver static real deployed market with a clear scale-out roadmap, not a broken factory indexer. Explicit chain `start_block` avoids unnecessary historical scanning; never assume current head and deployment block are interchangeable.

### High-signal innovation — **Graduation Health / Market Quality Radar**
Visualize same launch's progression from bonding secure→actual Kuru market→first executable trade. Provide linked source transaction and an Envio derived time-to-first-trade, spread/depth from directly verified reads (depth is NOT available solely from `Trade` logs), and stale indexing warning. This addresses a REAL user trust problem: a launch token isn't useful until traders can execute. Show that Envio data changes a core market card rather than making a decorative explorer page.

### Hard acceptance
Official generated indexer deploys to a public GraphQL endpoint; at least three real historical event entities reconcile exactly with chainId/txHash/logIndex; one actual live UI metric reads GraphQL and has `indexedBlock`/staleness; unit snapshot and duplicate/reorg tests pass. Envio token is not exposed in frontend. Include endpoint URL and test log in evidence.

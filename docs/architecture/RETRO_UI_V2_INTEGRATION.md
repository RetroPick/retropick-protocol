# Retro UI / deployed V2 integration

Status: testnet implementation in progress; Solidity remains HACKATHON_FREEZE.

## Current / target / delta

Current: `apps/retro-ui` is the user's Vite/React app with its own sidebar, mobile navigation, theme, compact feed and two-step creation form. Its records and actions are mocks. Earlier apps/web integration is historical qualification, not the intended product frontend.

Target: retain those exact screens and styles. Connect wallet-direct writes to deployed V2; use an event-derived indexer for discovery, history, trades, holders and candles. Fresh RPC reads verify reserves, balances, Coordinator phase and Kuru identity immediately before economic writes.

Delta: add shared deployed ABIs/types/chain adapter, a reconstructible indexer/read API, and data/action bindings in the existing retro-ui components. Only contract-required copy/fields/status/availability change. No sidebar/layout/theme/flow redesign; no new financial module or contract feature.

## Data and authority

`retro-ui → shared SDK → wallet → Monad Testnet` for signing/broadcast.

`Monad logs → indexer journal (SQLite) → deterministic projections → read API → retro-ui` for discovery/history. Every response identifies chain, confirmed indexed block, observed head, lag and sync time. Integer amounts serialize as decimal strings and remain bigint in the SDK.

Factory creates/configures; Coordinator alone determines GRADUATING/GRADUATED. A Kuru receipt links market/vault/protected custody. The indexer never signs, accepts economic writes, creates graduation state independently or makes unobserved zero/missing metrics look verified.

## Indexing

Start at the deployed Factory block from the historical manifest. Backfill Factory/Coordinator events, discover launch token/curve/Kuru addresses, then scan their exact source events. Bound RPC log ranges to 100 blocks, pace/retry reads, persist cursors and hash checkpoints. Journal identities include chain/block hash/transaction/log index. Duplicate processing is idempotent. Reorgs remove orphaned journal/checkpoints and rebuild derived state; no partial range advances. Confirmation depth and checkpoint mismatch are observable.

Projection surfaces: launches, creator launches, curve/Kuru trades, order/cancel events, token Transfer-derived holders, exact quote volume and trade-price candles. Transfer records do not imply organic traders; functional test traffic is not adoption. Unsupported asset categories/fee destinations remain unavailable in live mode.

## Deployment

Vite frontend and read-only RPC/API proxy on Vercel. The indexer uses a persistent SQLite file on the testnet worker host, with an HTTPS transport and explicit health/freshness. If a temporary tunnel is used, label its hosting limitation; do not present it as durable production infrastructure. Proposed provider ADR-015 remains proposed; this implementation qualifies a provider-agnostic testnet read model and does not accept a production provider implicitly.

## Migration order and gates

1. Preserve/hash the user's untracked retro-ui sources; copy into delivery branch.
2. Extract already-qualified ABI/wallet/math/RPC adapters into one shared package.
3. Implement journal/backfill/live sync/reorg/read API with replay/idempotency/rollback tests.
4. Bind existing retro-ui data/actions; retain UI/UX and explicit mock mode.
5. Reproduce actual historical transactions and fresh RPC state; typecheck/build/domain/indexer/browser checks.
6. Deploy the intended app, run funded MON launch/graduation/order/fill/cancel, replace technical footage, then release/merge gates.
7. Founder pitch and explicit submission approval remain required. No automatic submission.

## Main checkpoint

The user requested all delivery work on `main`. The preserved retro-ui sources, complete deployed ABI bundle, SDK and testnet indexer candidate are checked in there. ABI integrity, SDK/indexer types, journal rollback/idempotency and existing frontend tests pass. Live indexer backfill, frontend wallet/data bindings, browser qualification and replacement footage remain in progress. No production provider is selected and no final Metropolis submission is authorized.

ABI inventory: [deployed bundle](../../deployments/monad-testnet/abi/README.md). All release contract addresses are mapped; Circle external implementation ABI remains interface-only and explicitly labeled.

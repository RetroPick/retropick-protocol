# AGENTS — RetroPick Metropolis Sponsor Work
**Read before implementing any bounty.** This is a bounded agent work order, not authorization to deploy production capital or modify existing protocol ownership.

## Source of truth and precedence
1. Live deployed V2 contracts and verified receipts in `deployments/monad-testnet/v2.json` and `evidence/hackathon/metropolis/**`.
2. Current code in `contracts/src/v2/**`, `apps/web/**`, `apps/indexer/**`, lockfile, and deployed source SHA. Run `git rev-parse HEAD` and record.
3. Official sponsor docs + actual CLI/SDK version installed; user-captured Oct 2026 bounty wording.
4. `docs/hackathon/**` and `docs/prism/**` as plans/specs, NOT deployment evidence.
5. Uploaded Base Sepolia MarketEngine architecture is historical and cannot be used as a Monad patch target.

## Mandatory agent report for each PR
```yaml
bounty: ""
branch: ""
base_sha: ""
files_changed: []
sdk_versions_pinned: {}
onchain_contracts_and_chain_ids: []
requirements:
  - requirement: ""
    status: VERIFIED|MISSING|BLOCKED|NOT_APPLICABLE
    proof: ""
tests:
  commands: []
  result: ""
  receipts: []
security_review:
  keys_exposed: false
  signing_bypass: false
  custody_change: false
  invariant_regression: false
known_gaps: []
rollback: ""
demo_url: ""
```
No 'done' status without running the command and attaching output; no 'working' cross-chain flow without source tx, destination receipt and downstream app action.

## Shared interfaces (DESIGN contracts; not existing deployed APIs)
```ts
type ChainRef = { chainId: number; network: 'testnet'|'mainnet' };
type Proof = { chainId: number; txHash: `0x${string}`; blockNumber: string; status: 'confirmed'|'reverted'; explorerUrl: string };
type FeatureStatus = 'disabled'|'checking'|'ready'|'blocked';
type SponsorEvidence = { sponsor: string; feature: string; sourceSha: string; proof: Proof[]; videoUrl?: string; blockers: string[] };
type RiskBudget = { maxInputAtomic: string; minOutputAtomic: string; expiresAt: number; allowedChainId: number; allowedContracts: string[] };
```
Use BigInt for token amounts, no JS floats for settlement. Validate token decimals and asset address per chain; never assume Circle USDC, test USDC, AUSD and MON are fungible or universally routed.

## App extension rules
- Keep `apps/web/lib/live/wallet.tsx` existing EIP-1193 flow intact; add sponsor adapters behind feature flags, no forced global provider replacement for a non-wallet PRF bounty.
- Keep `apps/web/lib/live/kuru.ts` verified environment and market checks. Do not bypass identity/precision checks to force a demo.
- `apps/web/app/api/chain/route.ts` is READ-ONLY. Never add broadcast, secret-key signing, arbitrary RPC methods, or proxy secrets there.
- `apps/indexer/src/project.ts` already contains TS projections; Envio is an optional complementary verified pipeline, not an excuse to duplicate authoritative state.
- Do not change Factory/Coordinator/Executor/Kuru custody flows for cross-chain deposits or agent trading.
- Separate PRs: docs/evidence; UX; PRF; plugin; Aurora; Envio; CRE; Nansen; optional new outcome asset protocol.
- Gate all experimental UI on server-verified feature readiness and `NEXT_PUBLIC_*_ENABLED` toggles. Server-only keys never have NEXT_PUBLIC prefix.

## Baseline verification
```sh
git rev-parse HEAD
pnpm install --frozen-lockfile
pnpm --filter @retropick/web typecheck
pnpm --filter @retropick/web build
pnpm --filter @retropick/indexer test
# For contracts, follow contracts/README.md setup, run fresh fork qualification and strict sizes.
```
If a command cannot run (RPC/funding/dependency unavailable), record BLOCKED with the reason; do not mark PASS.

## Safety/acceptance
- No signing keys, seed phrases, PRF output, passkey secrets, API tokens, auth cookies, MFA challenges or private user notes in logs, docs, issues or telemetry.
- Explicit spender and allowance, chain and contract allowlists, finite per-action limits, timeouts, idempotency, pause/cancel.
- For automated trade: read/quote/simulate; confirm human policy; use MetaMask Agent Wallet wallet-submit; await receipt; reconcile balances. Handle AWAITING_MFA as pending, not failure/retry.
- For Aurora: don't credit user on an unverified quote or source tx; track quote expiry, destination receipt, refund path and downstream use.
- For PRF: never store derived key; store ciphertext+salt namespace identifier+nonce+KDF version, and prove cross-device decrypt.
- For Nansen: check API license/redistribution before displaying/caching data.
- No fake volume, simulated transaction represented as live, invented user demand or guaranteed profit.

## Evidence naming
`evidence/hackathon/metropolis/sponsors/<slug>/README.md` with UTC timestamp, commit SHA, SDK versions, chain IDs, tx hashes, screenshots, expected/actual results, demo video and known limitations. Ensure publicly readable proof and redaction of sensitive material.

## Definition of done
A bounty is complete only if (1) exact track eligibility, (2) core integration not superficial, (3) real user flow or sponsor-accepted simulation, (4) tests and failure states, (5) live judge access, (6) evidence, (7) submission answers, and (8) rollback are all present. Otherwise change selection before portal deadline.

## Useful existing docs
`HACKATHON.md`, `docs/hackathon/KURU_BOUNTY.md`, `docs/hackathon/EVIDENCE_MAP.md`, `docs/prism/05-hackathon/MVP.md`, `docs/prism/protocol/PRISM_PROTOCOL_SPEC.md`, `docs/prism/05-hackathon/PHASE_GATES.md`.

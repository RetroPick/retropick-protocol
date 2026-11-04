# M6 — Permissionless Graduation and Community Revenue (V2)

Status: IN_PROGRESS / RESEARCH + ADDITIVE QUALIFICATION ONLY.
Created: 2026-11-04.
Baseline: `main@975938a8da4610bf5b13c135ced2dd2c58bbad9f` (PR #45 merged).
Branch: `research/m6-usdc-stateful-venue-gates-20261104`.
Implementation/release authority: no production deployment, no mainnet transactions, no automatic merge.

## GOAL

Prove a permissionless V2 token launch -> curve trades -> secured graduation -> genuine Uniswap v4 pool/position -> authenticated community revenue -> independent claims -> Vault -> 72-hour timelock -> authorized spending lifecycle, using real venue contracts and replay-resistant accounting. Remove Kuru from the **new-launch critical path** only after preserving deployed commitments and historical custody/retry proofs.

The primary target is Uniswap v4; verify deployment/chain support before treating a venue as available. Uniswap v3 is a fallback research candidate, not an approved venue.

## Baseline as built (repository evidence)

- PR #45 merged into main; canonical Vault, Timelock, TreasuryDeployer and TreasuryBuilder are present.
- Curve is an immutable community fee source for `CommunityFeeRouterV2`: `fund()` accepts only `msg.sender == source`, requires exact launch asset/epoch/sequence/balance and checks backing. An Uniswap hook cannot credit this ledger just by sending tokens or calling `fund()`.
- `CommunityTreasuryVaultV2` spends only via its bound timelock; unsolicited transfers are quarantined.
- `UniswapV4GraduationExecutorV2` disables the post-graduation community hook fee stream for community launches; disabling is safer than inventing unsupported fee ownership.
- V2 Factory runtime measured in historical candidate evidence at 24,486 bytes, near the 24,576-byte EIP-170 ceiling. No further venue-specific Factory logic.
- Existing real fork success is **one legacy native Kuru test**, not a Treasury/v4/USDC lifecycle.
- Earlier native stateful Treasury coverage exists, but six-decimal USDC stateful coverage was an open gap at baseline.
- Recorded 75 Slither findings require owner-level triage and/or independent audit review.

## Verified external documentation vs deployment qualification

Official Uniswap v4 deployment documentation lists Monad **mainnet** (chain ID 143) PoolManager `0x188d586ddcf52439676ca21a244753fa19f9ea8e`, PositionManager `0x5b7ec4a94ff9bedb700fb82ab09d5846972f4016` and Permit2 `0x000000000022D473030F116dDEE9F6B43aC78BA3`.
Source: https://developers.uniswap.org/docs/protocols/v4/deployments

This is **not** evidence of an official deployment on Monad **testnet 10143**, which is hardcoded by the current community fee Router/Vault and admission code. All contract identities, bytecode, asset addresses, tick/fee settings, hook permissions and ownership must be reverified over the selected chain's RPC and a pinned fork.

Official fee mechanics: https://developers.uniswap.org/docs/protocols/v4/guides/custom-accounting
Official hook permissions: https://developers.uniswap.org/docs/protocols/v4/concepts/hooks

Do not infer hook-fee ownership from LP fee accrual, nor charge hook fees against requested rather than actual swap flow without an accepted policy.

## Candidate architecture (not an accepted ADR)

1. New launches commit to a versioned, permissionless graduation destination and quote policy.
2. Coordinator retains the sole secured-graduation ledger; adapters do not `delegatecall` or control unrelated liabilities.
3. Permissionless v4 executor performs actual PoolManager initialization, position mint and external state verification.
4. A versioned authenticated venue-revenue collector/ledger separates provenance for Curve fees, hook fees and LP-position fees. The existing Curve-only Router remains immutable for existing launch entitlements.
5. The revenue mechanism must settle exact physical transfers, account for native/6-decimal ERC20 assets and be replay-proof per pool, stream and event/settlement sequence.
6. Independent creator/contributor claims and treasury Vault claims remain separate; governance cannot seize unclaimed third-party credit.
7. Vault spending remains delayed by the existing immutable 72h Timelock and is exercised through a verified Safe configuration.
8. UI/SDK/indexer read claimable onchain state and reflect disabled streams; no projected fee can be claimed until authenticated physical settlement.

## Milestone dependency DAG

### M6.0 — Baseline and security inventory
- Read `AGENT_GUIDE.md`, `AGENTS.md`, `.agent/STATE.json`, `.agent/CURRENT_GOAL.md`, local `contracts/AGENTS.md`, and venue-adapter skill.
- Inventory active Kuru/v4 paths, ABI bindings and deployed commitments.
- Triage 75 Slither findings; classify true issue / false positive / unconfirmed with evidence.
- Freeze economic invariants and runtime-code-size budget.
- Output baseline SHA, unmodified production manifests, risk register.

### M6.1 — Six-decimal stateful treasury campaign
- Add local ERC20 handler using actual Curve/Router/Vault/Timelock paths.
- Mix trades, settlements, claims, governance scheduling/execution, donations and unauthorized calls.
- Assert physical collateral, totalFunded=totalPaid+totalLiability, credit sum, independent claims and no unauthorized spend.
- Gate via Foundry CI, `FOUNDRY_PROFILE=test forge test --match-path 'test/v2/community-economy/treasury-integration/CommunityTreasuryUSDCInvariant.t.sol'`.
- **This is not a live Circle USDC/fork/venue/multisig test.**


### M6.1b — Successful local V4 behavior seam

- Test `test/v2/community-economy/treasury-integration/CommunityTreasuryV4Seam.t.sol` uses the existing V4 behavioral PoolManager, PositionManager and Permit2 test doubles with real V2 Curve, Router, Vault and Timelock.
- Exercise native and modeled six-decimal quote launches, successful simulated V4 graduation, LP NFT ownership/lock, zero post-graduation community hook fees, independent beneficiary entitlements, Vault claim, 72h spend and replay rejection.
- Gate in CI separately from the USDC stateful invariant campaign.
- **Explicit limit:** this is a behavioral seam (not live v4 fork/real deployed PoolManager or live USDC) and does not qualify external venue interoperability.

### M6.2 — Venue and fee-source feasibility
- Verify real chain-specific Uniswap PoolManager, PositionManager, hook, Permit2, quote policy and ERC20 bytecode on RPC.
- Develop fee-source protocol and mock-vs-real test separation.
- Select LP owned-fee collection or custom afterSwap/ beforeSwap hook fees through explicit fee policy. Require owner-accepted ADR for economic changes.
- Preserve Kuru deployed/existing commitments, remove only new-launch reliance once migration is proven.

### M6.3 — Research prototype then canonical V2
- Prove exact source authentication and fee custody in `contracts/src/v2-research-experiment/`.
- Red-team failure/retry, hook callback, token fee-on-transfer, native fallback, cross-launch injection, policy changes and pool replay.
- Only after Foundry, fork and design gates pass, promote the minimum compatible, permissionless venue integration to `contracts/src/v2/` under an accepted ADR.
- Do not insert new venue bytecode in Factory or modify locked deployed contracts.

### M6.4 — Real venue fork and governance
- Native and USDC fork: launch -> buy/sell -> secure -> successful venue graduation -> verify LP ownership and liquidity -> real swaps -> collect authenticated revenue -> distribute -> vault claim -> 72h timelock -> spend.
- Prove native/USDC exact conservation, physical asset custody, at-most-once credit, post-reorg indexer behavior and failure/retry safety.
- Verify Safe proposer/threshold execution on local or fork; EOA-only role tests are insufficient.
- Record pinned block/hash, chain ID, codehashes, contract addresses, exact test commands and receipts.

### M6.5 — Release authority
- Run original and incremental regressions; builder, ABI, bytecode/initcode and static analysis checks; independent audit.
- Record gas, low-volume economics, UX capability disclosures and operator runbook.
- Merge/release/deploy only after separate explicit authorization and independent security review.

## Non-negotiable invariants

- Physical fee assets always back credited/claimable funds.
- A revenue source can credit only its own launch, fee asset, policy epoch and monotonically unique settlement ID.
- No Curve fees, v4 hook fees or LP fees are double-counted or mislabeled.
- Old policy allocations remain immutable.
- Protected LP principal is never treasury revenue.
- Donation surplus is unclaimable unless deliberately governed by a separately qualified mechanism.
- Failed venue execution never destroys secured graduation obligations.
- Permissionless actions cannot bypass timelock, fee provenance or claim authorization.
- No new V2/V1/V3 deployment, broadcast or protocol economic change from research-only approval.

## Acceptance evidence checklist

- [ ] Current main/ref and pre-existing deployment manifests pinned
- [ ] USDC local stateful Foundry test PASS in CI
- [ ] Successful Treasury local V4 behavior seam PASS in CI (native + six-decimal)
- [ ] Original V2 unit and invariant CI remains PASS
- [ ] 75 Slither findings independently triaged
- [ ] Accepted fee-source and venue-deprecation ADRs
- [ ] Monad-targeted actual v4 codehashes verified
- [ ] Real successful native v4 fork graduation
- [ ] Real successful six-decimal ERC20 v4 fork graduation
- [ ] Genuine fee collection and zero duplicate credit
- [ ] Safe multisig/timelock end-to-end
- [ ] Independent audit and external deployment authorization

If any gate remains open, status is PARTIAL or BLOCKED, never RELEASE_QUALIFIED.

## Current-turn limitations (2026-11-04)

GitHub connector supports repository inspection and branch/PR writes, but local Foundry/solc and external RPC tools are not available in this session. The added test and CI wiring require the GitHub Actions run before any PASS claim. No canonical financial contract has been modified; this is a deliberately additive qualification increment, not completion of M6.

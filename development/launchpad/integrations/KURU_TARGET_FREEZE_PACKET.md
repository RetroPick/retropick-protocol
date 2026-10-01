# Kuru target freeze packet — 2026-09-29 (INCOMPLETE / PROPOSED)

This packet qualifies the *target interface* for Launchpad Core V2 on Monad Testnet. It does not authorize the production executor, accept ADR-009/011/021, deploy a market, or clear `BLOCK-KURU-TARGET`. The machine-readable [read-only chain snapshot](../../../evidence/launchpad/kuru/target-snapshot-2026-09-29.json) and the exact [seed model](../../../research/integration/kuru/launchpad_seed_model.py) are the new evidence. Historical Hackathon-P0 material is retained unmodified.

## 2026-09-30 qualification increment

The current [B1 environment manifest](../../../evidence/launchpad/kuru/environment-manifest-2026-09-30.json) independently rechecked public source heads and block-pinned Router/implementation/code identity. A [candidate profile matrix](../../../evidence/launchpad/kuru/parameter-profile-matrix-2026-09-30.json) now derives terminal `T` from original launch supply: a one-million-token 100/100 launch has terminal `T=500,000` tokens and proposed `B=250,000` tokens, not `T=1,000,000`. A [real Kuru fork fixture](../../../evidence/launchpad/kuru/fork-deploy-seed-2026-09-30.md) deployed and seeded native MON and two distinct six-decimal `USDC`-symbol contracts. It caught and corrected an erroneous first-bid denominator in the research oracle. The [quote identity packet](../../../evidence/launchpad/kuru/quote-qualification-2026-09-30.md) records that Kuru's listed testnet USDC differs from Circle's listed Monad Testnet USDC. See the [B1–B12 benchmark gate](KURU_BENCHMARK_GATE.md) for current scoped row statuses. No ADR has been accepted, no complete phase-2 or live transaction has been proven, and the target remains **NOT FROZEN**.

Protocol-owner P0 direction identifies `0x534b2f3A21130d7a60830c2Df862319e593943A3` as canonical Circle test USDC on chain 10143. Kuru-listed `0x3bA3d39AFcf8bb994f7964B3e0171Ea2Ba361570` is only `KURU_TEST_USDC`, a compatibility fixture. Neither address inherits qualification from the symbol `USDC`; Circle's real transfer, allowance and vault-deposit path needs pinned-fork and live evidence. The owner also selected dedicated non-withdrawable LP/excess-token custody and permissionless atomic retry with no P0 rescue shortcut. These directions narrow the research; they do not replace the missing benchmark or silently accept the ADRs.

A subsequent [pinned Circle custody increment](../../../evidence/launchpad/kuru/circle-custody-fork-increment-2026-09-30.md) verifies one real Router/Vault deposit profile: exact caller debit, exact vault allowance consumption and exact **MarginAccount** physical quote-balance increase. The vault itself does not retain the Circle ERC20 balance after deposit. This corrects the physical-custody assumption for later postconditions, but does not complete B2, the gas matrix or live funding/usability.

## 2026-10-01 technical benchmark boundary

The [final custody/drift/gas increment](../../../evidence/launchpad/kuru/final-custody-drift-gas-increment-2026-10-01.md) upgrades the research architecture to a bound no-exit lock and completes B7–B10 only within the pinned research-fixture domain. Real native-MON and canonical-Circle first deposits send LP plus excess launch tokens to the lock; creator/operator/arbitrary authority negatives pass. Observable Router/Margin runtime-codehash and implementation-getter drift stops before market creation and allows retry after restoration. The deterministic MON/Circle small/medium/large failed/retry/replay gas matrix peaks at 1,896,521 gas against the recorded 150,000,000 fork limit. These are not integrated Factory/Core measurements, distributions or an operational SLO.

Accordingly B1 and B5–B10 are technical research passes, B2–B4 remain decision-gated, and B11–B12 remain post-implementation. `KURU_TECHNICAL_BENCHMARK = PASS` in that declared domain, but `KURU_TARGET_FROZEN = DECISION_REQUIRED`; no ADR is accepted here.

## CURRENT / TARGET / DELTA / MIGRATION ORDER

- **CURRENT:** V2 Factory holds the launch record and uses a V4-oriented two-phase `NotGraduated → Swept → PoolCreated` path. Curve secures reserves first; `createGraduatedPool` is retryable. No Kuru call exists in V2 production source.
- **TARGET:** launch token/quote reserves secured in `GRADUATING`, then one atomic Kuru phase-2 transaction deploys/verifies market and vault, seeds a price-preserving first deposit, locks LP shares, and records `GRADUATED` only after all checks.
- **DELTA:** replace only the destination boundary after current financial behavior is qualified. Kuru precision, vault seed, LP custody and external upgrade policy need explicit accepted decisions; they are not implied by the V4 implementation.
- **MIGRATION ORDER:** qualify Core Factory/Curve/Token/Fee behavior → accept target network/quote/parameter/LP/retry ADRs → implement Kuru controller/executor → replay bonding fixtures → prove failure/retry and live target integration → consider V4 retirement separately under ADR-020.

## Verified source and environment

At inspection, public [Kuru contracts](https://github.com/Kuru-Labs/Kuru-contracts-dex-public/tree/2060bb2736080c175d80d568bfdb6226bb5abd04) and [SDK](https://github.com/Kuru-Labs/kuru-sdk/tree/636509c2eafd63479d3f399703354e0d09f51e18) `main` still matched their previous pins. Official [testnet addresses](https://docs.kuru.io/contracts/Contract-addresses) and Monad [testnet documentation](https://docs.monad.xyz/developer-essentials/testnet) were rechecked. A read-only RPC at block `66703769` reported chain ID `10143`, Router `0x7EFbE105Ca7415dE98F96622173458ac1c054630`, Router getter MarginAccount `0xd029C2D98ff85D8F64799017fE00a59B1159CE02`, testnet USDC `0x3bA3d39AFcf8bb994f7964B3e0171Ea2Ba361570` with six decimals. Router's current OrderBook implementation is `0x72caE0a99C19B574e8a6De558F43fc1D019c9374`; vault implementation is `0x4d54e0d60CaB0cec0100cdA8e00897bC933C5Bb6`. Runtime code hashes, proxy implementations and timestamp are in the snapshot. These identities are **mutable external state**, not protocol constants.

Router source at that commit declares `deployProxy(uint8,address,address,uint96,uint32,uint32,uint96,uint96,uint256,uint256,uint96)` (selector `0xce186ec3`); market type `0` is ERC20/ERC20 and type `2` has native quote. `MonadDeployer` is not the ordinary graduation path because RetroPick already owns the launch token. The SDK `calculatePrecisions` helper uses JavaScript numbers and is only a compatibility cross-check; it cannot be the authoritative financial derivation.

## Exact constraints and invalid historical packet

`Router.deployProxy` requires a nonzero tick and power-of-ten size/price precision. `OrderBook.initialize` requires `makerFeeBps ≤ takerFeeBps < 10_000`, `0 < spread < 500`, `spread % 10 == 0`, and `0 < minSize < maxSize`. The type widths add `uint96`/`uint32` bounds. [Exact predicate tests](../../../research/integration/kuru/test_launchpad_seed_model.py) cover those necessary conditions, including a permanent negative for spread zero. They are not sufficient to prove market deployability.

The old [Hackathon-P0 parameter packet](../../../research/hackathon-p0/KURU_P0_PARAMETER_PACKET.md) proposes `kuruAmmSpread = 0`; this is **incompatible with the current OrderBook source**, which rejects zero. The old artifact must remain historical. No RetroPick parameter tuple has yet been accepted. Creator-supplied raw values remain prohibited by the target policy.

## Market identity and later executor verification contract

Kuru `Router.computeAddress` hashes the current OrderBook implementation into the CREATE2 init code; `computeVaultAddress` likewise hashes the current vault implementation. Pair and parameters alone do not determine either address. The future executor must re-read Router, implementation addresses and code hashes, MarginAccount and the accepted parameter tuple in the same transaction context before relying on a precomputed identity. If the pinned environment or code identity differs, **stop graduation** for review; do not silently adapt to an upgraded implementation.

An external proxy's EIP-1967 implementation slot is read **offchain by RPC** for the versioned target manifest. Solidity cannot `SLOAD` another contract's private slot. The onchain executor can check chain ID, accepted Router identity, Router-exposed implementation/MarginAccount getters, code presence and observable implementation code hashes, then verify deployed market/vault state and asset movement. This does not remove Kuru's external upgrade authority; operational drift monitoring must stop new graduations pending requalification.

Proposed phase-2 verification, all before committing `GRADUATED`:

1. Require the launch is exactly in secured `GRADUATING`, assets remain accounted, destination unset, approved base token and same-quote asset match the launch record, and current Kuru identities/code hashes match the accepted environment manifest.
2. Compute expected market and vault addresses from the live Router implementation getters plus the immutable accepted parameter tuple; reject pre-existing addresses unless a separate adoption decision has been accepted. Check both new addresses have code after `deployProxy`.
3. Compare returned market, Router `verifiedMarket(market)`, OrderBook `getMarketParams`, its Router/owner and `getVaultParams` vault/spread against the accepted tuple. Verify vault token1/base, token2/quote, market, MarginAccount, spread and Router/owner getters. Do not trust the return address or `MarketRegistered` event alone.
4. Seed physical base/quote, verify actual consumed balances, minted LP shares and receiver, and require the vault's first ask and both nonzero order sizes satisfy the accepted price/size bounds. Only then record the unique destination and `GRADUATED`.

The preferred execution is one atomic phase-2 transaction. Any revert restores phase-2 local changes while leaving the earlier secured `GRADUATING` state intact and permissionlessly retryable. No ordinary curve trade resumes; P0 has no rescue shortcut or alternate path to `GRADUATED`. A [research-only pinned-fork increment](../../../evidence/launchpad/kuru/atomic-retry-increment-2026-09-30.md) proves five injected post-boundary reverts, same-launch retry, replay rejection and two environment-drift stops for a native-quote sketch. It does **not** complete the required failure matrix, multi-quote gas benchmark or Core-integrated retry proof; ADR-023 remains PROPOSED. Kuru Router/OrderBook/Vault upgrade and market pause authority are external trust risks even when RetroPick LP shares are locked.

## Price continuity and first liquidity

Let `T` be terminal tracked launch-token units, `P` phantom quote, and `Q` *physically secured* real quote. The terminal reference ratio in raw units is `(P+Q)/T`. Existing V4 seed math chooses `B = floor(T×Q/(P+Q))` base units and leaves `T−B` excess tokens locked; this is the candidate Kuru first-base deposit. Depositing all `T` against only `Q` would instead open at `Q/T`, a lower price because phantom quote is not physical. Kuru's first-deposit ask is `floor(Q×10^baseDecimals×10^18/(B×10^quoteDecimals))`, and first LP shares to receiver equal `floor(sqrt(B×Q))−1000`. Its spread and size precision must also yield both nonzero vault order sizes. The exact model and tests cover 6-decimal USDC, 18-decimal native quote, nondivisible rounding and a tiny unseedable case. `B=0`, ask=0, LP≤0, or zero vault order size means **do not graduate**. The accepted maximum price deviation, bounded configuration classes, excess-token custody, and onchain gas/overflow domain remain undecided.

The later [exact price-continuity bound](../../../evidence/launchpad/kuru/seed-price-continuity-bound-2026-09-29.md) proves under stated integer assumptions that the unrounded seed/reference price ratio is `1 + e/(B(P+Q))`, where `e=TQ−B(P+Q)` and `0≤e<P+Q`. Thus relative upward drift is strictly below `1/B`; a conservative 1e18-scaled absolute bound is also recorded and checked over 14,096 small integer cases. This narrows the mathematics, **not** the protocol decision: the acceptable error threshold and configuration classes are still not frozen.

## Decision ledger and open gates

| Decision | Current status / missing acceptance |
| --- | --- |
| ADR-009 Kuru default venue | PROPOSED; current target interface known, but no real RetroPick market/liquidity proof. |
| ADR-011 quote policy | PROPOSED; P0 native MON + one specifically qualified testnet USDC is the candidate. Exact-transfer, non-rebasing, callback, issuer-freeze and Kuru compatibility checks remain. |
| ADR-021 market parameters | PROPOSED; source constraints verified, but exact integer derivation, accepted fee/spread/tick/size classes and price-error bound remain. |
| ADR-020 V4 retirement | PROPOSED; no V4 removal is authorized here. |
| [ADR-022 LP-share custody](../../../decisions/ADR-022-kuru-lp-share-custody.md) | PROPOSED; dedicated non-creator-controlled lock recommended. Withdrawal/emergency, unrelated-asset recovery and excess-token ownership require human economic decision. |
| [ADR-023 retry/verification](../../../decisions/ADR-023-kuru-graduation-atomic-retry-and-verification.md) | PROPOSED; atomic phase-2 is the candidate. Fork gas and explicit recovery authority require acceptance. |

`KURU_TARGET_FROZEN = BLOCKED / DECISION_REQUIRED` and `READY_FOR_DEV4_KURU_EXECUTOR = BLOCKED`. The [B1–B12 machine-readable gate](../../../evidence/launchpad/kuru/kuru-benchmark-gates-2026-09-30.yaml) records scoped B1/B5–B10 technical passes, B2–B4 decisions and B11–B12 post-implementation gates. Source/code snapshots, models and research-fixture proofs do not accept ADRs or authorize production integration. No live Kuru transaction was sent.

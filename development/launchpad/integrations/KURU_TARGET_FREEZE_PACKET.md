# Kuru target freeze packet — 2026-09-29 (INCOMPLETE / PROPOSED)

This packet qualifies the *target interface* for Launchpad Core V2 on Monad Testnet. It does not authorize the production executor, accept ADR-009/011/021, deploy a market, or clear `BLOCK-KURU-TARGET`. The machine-readable [read-only chain snapshot](../../../evidence/launchpad/kuru/target-snapshot-2026-09-29.json) and the exact [seed model](../../../research/integration/kuru/launchpad_seed_model.py) are the new evidence. Historical Hackathon-P0 material is retained unmodified.

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

Proposed phase-2 verification, all before committing `GRADUATED`:

1. Require the launch is exactly in secured `GRADUATING`, assets remain accounted, destination unset, approved base token and same-quote asset match the launch record, and current Kuru identities/code hashes match the accepted environment manifest.
2. Compute expected market and vault addresses from the live Router implementation getters plus the immutable accepted parameter tuple; reject pre-existing addresses unless a separate adoption decision has been accepted. Check both new addresses have code after `deployProxy`.
3. Compare returned market, Router `verifiedMarket(market)`, OrderBook `getMarketParams`, its Router/owner and `getVaultParams` vault/spread against the accepted tuple. Verify vault token1/base, token2/quote, market, MarginAccount, spread and Router/owner getters. Do not trust the return address or `MarketRegistered` event alone.
4. Seed physical base/quote, verify actual consumed balances, minted LP shares and receiver, and require the vault's first ask and both nonzero order sizes satisfy the accepted price/size bounds. Only then record the unique destination and `GRADUATED`.

The preferred execution is one atomic phase-2 transaction. Any revert restores phase-2 local changes while leaving the earlier secured `GRADUATING` state intact and retryable. No ordinary curve trade resumes; recovery/rescue is a distinct, governed state transition. Fork gas/atomicity testing and an accepted retry ADR remain open. Kuru Router/OrderBook/Vault upgrade and market pause authority are external trust risks even when RetroPick LP shares are locked.

## Price continuity and first liquidity

Let `T` be terminal tracked launch-token units, `P` phantom quote, and `Q` *physically secured* real quote. The terminal reference ratio in raw units is `(P+Q)/T`. Existing V4 seed math chooses `B = floor(T×Q/(P+Q))` base units and leaves `T−B` excess tokens locked; this is the candidate Kuru first-base deposit. Depositing all `T` against only `Q` would instead open at `Q/T`, a lower price because phantom quote is not physical. Kuru's first-deposit ask is `floor(Q×10^baseDecimals×10^18/(B×10^quoteDecimals))`, and first LP shares to receiver equal `floor(sqrt(B×Q))−1000`. Its spread and size precision must also yield both nonzero vault order sizes. The exact model and tests cover 6-decimal USDC, 18-decimal native quote, nondivisible rounding and a tiny unseedable case. `B=0`, ask=0, LP≤0, or zero vault order size means **do not graduate**. The accepted maximum price deviation, bounded configuration classes, excess-token custody, and onchain gas/overflow domain remain undecided.

## Decision ledger and open gates

| Decision | Current status / missing acceptance |
| --- | --- |
| ADR-009 Kuru default venue | PROPOSED; current target interface known, but no real RetroPick market/liquidity proof. |
| ADR-011 quote policy | PROPOSED; P0 native MON + one specifically qualified testnet USDC is the candidate. Exact-transfer, non-rebasing, callback, issuer-freeze and Kuru compatibility checks remain. |
| ADR-021 market parameters | PROPOSED; source constraints verified, but exact integer derivation, accepted fee/spread/tick/size classes and price-error bound remain. |
| ADR-020 V4 retirement | PROPOSED; no V4 removal is authorized here. |
| [ADR-022 LP-share custody](../../../decisions/ADR-022-kuru-lp-share-custody.md) | PROPOSED; dedicated non-creator-controlled lock recommended. Withdrawal/emergency, unrelated-asset recovery and excess-token ownership require human economic decision. |
| [ADR-023 retry/verification](../../../decisions/ADR-023-kuru-graduation-atomic-retry-and-verification.md) | PROPOSED; atomic phase-2 is the candidate. Fork gas and explicit recovery authority require acceptance. |

`KURU_TARGET_FROZEN = BLOCKED` and `READY_FOR_DEV4_KURU_EXECUTOR = BLOCKED`. A source/code snapshot and model are progress, not a complete target freeze. No live Kuru transaction was sent.

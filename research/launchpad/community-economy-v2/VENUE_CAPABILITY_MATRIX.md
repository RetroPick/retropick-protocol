# Venue capabilities

| Venue | Collector and actual rights | Routing status | Evidence / limitation |
|---|---|---|---|
| Experimental curve | Curve collects F/T; protocol P belongs to protocol escrow; C belongs to selected community policy | IMPLEMENTED; actual buy/sell, checkpoint, funding and claims tested locally | Experimental curve `_sweepCommunityFees`; exact-transfer quotes only |
| New registered Uniswap v4 CE pool | LP swap fees belong to LP position; hook creator/community rights need separate adapter | BLOCKED for continuous community fees; snapshots hookFee=0, creatorTax=0, buyback=false | Experimental v4 executor registration; real hook with stateful venue test seams |
| Canonical/legacy v4 pool | Existing pool-specific hook snapshot owns its original rights | EXISTING, unchanged | Canonical hook and executor read-only; cannot retrofit pool identity |
| Kuru order book | Venue maker/taker fees and volume do not establish RetroPick entitlement | BLOCKED_EXTERNAL_CAPABILITY | No authenticated creator/builder claim adapter or deployment entitlement demonstrated |
| Kuru LP/MM vault | Position custody and market-making returns are distinct from creator fees | BLOCKED for claimed community fee harvesting | Permanent LP locking is not a claim-right proof |
| External unrelated DEX | Venue-specific LP fee ownership | UNSUPPORTED | Vanilla ERC-20 imposes no arbitrary external trading fee |

Current primary-source checks: [Kuru documentation index](https://docs.kuru.io/llms.txt), [public OrderBook implementation](https://github.com/Kuru-Labs/Kuru-contracts-dex-public/blob/main/contracts/OrderBook.sol), [Router](https://github.com/Kuru-Labs/Kuru-contracts-dex-public/blob/main/contracts/Router.sol), [MarginAccount](https://github.com/Kuru-Labs/Kuru-contracts-dex-public/blob/main/contracts/MarginAccount.sol). These sources did not establish the alleged October-2026 approved-builder entitlement, target deployment, eligibility, recipient or claim flow. This is an unresolved capability, not proof that no newer private or public integration exists. Require dated official implementation, target identity, approval and executable claim proof before changing the blocker.

No trading-volume number is recorded as claimable revenue. No live RPC, swap or broadcast was used.

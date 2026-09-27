# V2 Launchpad Architecture

## IMPLEMENTED TODAY

V2 has the same ten contracts, three interfaces, and two libraries as V1 under `contracts/src/v2`; see [SOURCE_MAP.md](SOURCE_MAP.md). Its implemented runtime is the same **Uniswap V4** launch-token curve, graduation, Hook, escrow-credit, buyback-vault, locker, and Doorway-reference topology described for V1. The source-normalized comparison establishes no V2 behavioral architecture delta.

The lifecycle is `NotGraduated → Swept → PoolCreated`, with retryable permissionless V4 pool creation and owner-only delayed `Swept → Rescued` recovery. Curve custody and economics are unchanged:

```text
realQuote      = trackedQuote - quoteFeeBalance - creatorTaxBalance
quoteReserve   = phantomQuote + realQuote
reservedTokens = floor(supply * phantomQuote / (phantomQuote + graduationThreshold))
ready          = sellableTokens() == 0
poolTokens     = floor(sweptTokens * sweptQuote / (sweptQuote + phantomQuote))
```

The terminal-curve/opening-pool price-continuity objective is attained by locking excess sweep tokens; it does not introduce a new constant. The Factory/deployer/curve/token/guard/executor/PoolManager/PositionManager/hook/locker/vault call chain and roles are source-identical to V1. Refer to [V1_ARCHITECTURE.md](V1_ARCHITECTURE.md) for the complete flow, custody, external-call, recovery, Doorway, and trust-boundary explanation; names simply carry the `V2` suffix.

## TARGET KURU ARCHITECTURE (not source implemented)

The repository’s target product documents describe Kuru as the desired secondary-trading/CLOB layer for RetroPick outcome and PRISM assets. That target is intentionally not shown as an implemented V2 runtime node: V2 has no Kuru import, address, ABI, call, or deployment flow. Nor do the V2 launchpad sources import/call a prediction-market engine or PRISM structured-asset system. Any future Kuru path must be separately specified and gated; it cannot be inferred from the V2 label.

## Doorway and documented gaps

V2 Doorway remains a reference accounting/state machine with no ERC-20 pull, representation mint/burn, bridge settlement, or token adapter call. `ATTESTATION_DELAY` is unused and zero-hash Monad→Solana attestations share a latch. Snipe-tax settings/exemption calls do not produce runtime tax; documented CREATE2 `salt` is not used by Deployer; no launchpad runtime test suite exists apart from V1 Doorway coverage. `IRetroPickFeeEscrowV2` remains an ABI-only dependency.

## Source/documentation contradiction record

The source contradicts claims that V2 has an implemented Kuru integration, active bridge settlement, actual snipe tax, CREATE2 launch addressing, or a behavioral improvement over V1. The only current text difference is trailing whitespace in `hooks/RetroPickMemeHookV2.sol:19`.

See `v2/01-architecture.*` through `v2/07-doorway.*` for source-to-diagram mapping and the parallel V2 artifact set.

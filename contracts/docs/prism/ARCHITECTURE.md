# PRISM Contract Architecture

**Status:** TARGET DESIGN

The Solidity architecture is downstream of `docs/prism/protocol/` and `docs/prism/math/`.

## Native prediction contracts

```text
PredictionMarketFactory
  -> PredictionMarket
  -> CompleteSetVault
  -> YES OutcomeToken
  -> NO OutcomeToken
  -> Resolution module
```

The native issuance invariant is conceptually:

```text
1 collateral -> 1 YES + 1 NO
1 YES + 1 NO -> 1 collateral
```

## PRISM contracts

```text
PrismSeriesFactory
  -> PrismSeriesERC20
  -> PrismBackingVault
  -> PrismMintController
  -> PrismRedemptionRouter
  -> PrismSettlementEngine
```

Minting is backing-first. The mint controller may increase supply only after every post-mint component requirement is satisfied.

## External boundaries

Kuru is secondary execution/liquidity infrastructure. Indexers are derived read models. Resolution orchestration does not replace onchain resolution commitment. None of these systems is backing authority for same-chain PRISM collateral.

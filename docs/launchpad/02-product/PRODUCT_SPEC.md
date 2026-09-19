# RetroPick Launchpad Product Specification

**Status:** DRAFT CANONICAL  
**Owner:** Product + Protocol  
**Authority:** Product requirements

## Product

RetroPick is a modern launchpad on Monad. Creators launch fixed/capped ERC-20 assets into a bonding-curve primary market. Traders discover, buy and sell while launch progress increases. Qualified launches graduate safely into Kuru for mature secondary trading.

## P0 user promise

```text
CREATE -> DISCOVER -> BUY/SELL -> GRADUATE -> TRADE ON KURU
```

Creators configure token metadata, supply/economic parameters allowed by the chosen template, quote asset and creator settings. Traders receive explicit price, slippage, fees, launch progress and graduation state before signing.

## P0 product constraints

- Meme/cultural and standard/project token templates.
- Fixed/capped ERC-20 supply semantics.
- Bonding-curve primary price discovery.
- MON plus one qualified stable quote where deployment supports it.
- Transparent protocol/creator/buyback fees.
- Safe, retryable graduation.
- Kuru mature-market target.
- Discovery, create, launch, portfolio and activity UX.
- Indexed event history with RPC fallback for critical state.

## P1/P2

P1 adds creator/community and AI/agent templates, referrals and analytics. P2 may add direct-market launches, revenue/tax modules, registered external assets and additional venues.

## Non-goals

Prediction and PRISM are separate systems. P0 does not promise arbitrary ERC-20 quote compatibility, cross-chain settlement, unrestricted user-supplied Solidity, hidden mint authority or multi-venue liquidity fragmentation.

## Acceptance

A creator can launch, two users can trade, progress updates, a launch graduates, Kuru is usable, and the same lifecycle is demonstrable from the browser with transaction evidence.

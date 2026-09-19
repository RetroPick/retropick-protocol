# RetroPick Modern Launchpad — Executive Summary

**Status:** ACTIVE  
**Owner:** Product + Protocol  
**Authority:** Human-facing launchpad overview.

RetroPick is a modern token launchpad on Monad. It bootstraps new assets in a purpose-built primary market and graduates successful launches into mature secondary-market infrastructure.

## P0

```text
Creator
-> fixed/capped ERC-20
-> bonding curve
-> approved quote asset
-> launch progress
-> safe graduation
-> Kuru secondary market
```

The product separates supply policy, launch mechanism, quote asset and secondary venue. Fixed supply and bonding are complementary: supply defines how many units may exist; the bonding mechanism defines initial distribution and price discovery.

## Product priorities

P0: meme/cultural and standard/project tokens, MON plus a qualified stable quote, core discovery/trading UI and Kuru graduation.

P1: creator/community and AI/agent templates, referrals, richer analytics and more qualified quote assets.

P2: direct-market launches, revenue/tax modules, registered external assets, RWA quote assets and additional venues.

## Engineering principle

Contracts are the economic source of truth. The indexer is a read model. The backend may orchestrate metadata/cache but cannot custody launch reserves or redefine price/graduation.

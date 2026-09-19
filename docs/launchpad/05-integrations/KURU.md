# Kuru Integration

**Status:** DRAFT / REQUIRES CURRENT API PIN  
**Owner:** Integrations + Smart Contracts  
**Authority:** External integration contract

## RetroPick requirement

Graduation must be able to create or identify a usable mature market for the launched base asset against the configured quote asset, initialize required liquidity/inventory, validate market parameters, and persist/emit the resulting market identifier without risking secured graduation assets.

## Must verify before LP-KURU-1

- supported network/deployments
- exact market-creation contract/SDK methods
- base/quote ordering rules
- price and size precision
- tick/lot/minimum-order constraints
- fee configuration
- backstop AMM/liquidity requirements
- market identifier semantics
- required approvals/transfers
- failure and retry behavior

Concrete APIs are intentionally not invented in this document. Pin the official Kuru contracts/SDK/docs version before implementation.

## Acceptance

A deployed RetroPick launch graduates into a real supported Kuru market, the market is usable, and the launch page can resolve it deterministically from onchain/evidence data.

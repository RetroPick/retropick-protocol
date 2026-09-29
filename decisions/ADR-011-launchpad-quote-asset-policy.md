# ADR-011: Launchpad Quote Asset Policy

**Status:** PROPOSED  
**Date:** 2026-09-20  
**Scope:** RetroPick Launchpad V2

## Decision proposed

Use an explicit allowlist/policy for trusted quote assets rather than arbitrary ERC-20 acceptance.

P0 should target native MON plus one qualified canonical stable asset where available. Additional assets require compatibility testing for decimals, transfer behavior, callbacks, rebasing/fees, freeze/blacklist risk and Kuru support.

## 2026-09-30 evidence and decision options (status remains PROPOSED)

The [quote qualification packet](../evidence/launchpad/kuru/quote-qualification-2026-09-30.md) found two distinct Monad Testnet contracts both labeled `USDC`: [Kuru's list](https://docs.kuru.io/contracts/Contract-addresses) gives `0x3bA3d39AFcf8bb994f7964B3e0171Ea2Ba361570`, while [Circle's issuer list](https://developers.circle.com/stablecoins/usdc-contract-addresses) gives `0x534b2f3A21130d7a60830c2Df862319e593943A3`. They differ in runtime code and token name. Both passed a block-pinned real Kuru market/vault transfer path in a fork; that does not make their provenance equivalent. The Circle-listed contract exposes pause, blacklist and mint authorities, an explicit external trust risk. A protocol-owner approval of a token address alone cannot prove exact-transfer or non-rebasing behavior forever.

Decision options:

1. **Recommended:** P0 stable quote means the exact Circle-listed testnet address, conditional on issuer-risk disclosure, fresh code/role checks and an accepted onchain/operational allowlist boundary. Kuru's listed token is not automatically substituted.
2. Use the Kuru-listed address as a separate, explicitly named test asset after independent issuer/provenance and risk review; do not call it Circle-issued USDC.
3. Launch native MON only initially and defer the stable quote until its identity and risk policy are accepted.

Whichever option is accepted, preserve the [sender-surcharge and externally reducible token counterexamples](../evidence/launchpad/core/factory-asset-authority-increment-2026-09-29.md). Current onchain owner approval is a trust boundary, not a compatibility oracle. This ADR remains **PROPOSED** until a human protocol decision and all affected qualification rows are recorded.

# RetroPick Launchpad Security Model

**Status:** ACTIVE / NOT AN AUDIT  
**Owner:** Security + Smart Contracts

## Trust boundaries

The launchpad contracts custody launch inventory, quote reserves, accrued fees and graduation assets. Any owner, factory, fee operator, creator-recipient or external venue capability must be explicitly enumerated and tested.

## Required properties

- no unauthorized mint
- reserve and fee conservation
- bounded fees
- slippage enforcement
- no double graduation
- no lost graduation assets
- retryable external-market failure
- state monotonicity after terminal graduation
- quote-token behavior explicitly qualified
- reentrancy protections around transfers and venue interactions

## Static-analysis baseline

Previous scans of the current code reported high-severity-pattern findings in dependency math and complex DeFi external-call paths. These are not automatically safe; V2 release qualification must triage each current finding on current code.

## Doorway reference limitations

The current Doorway implementation is experimental and must not custody production funds without a complete bridge model. Known limitations include:
1. Monad-to-Solana migrations use a zero source transaction hash, so replay protection can latch after the first attestation.
2. request/migration paths account for liquidity without actually pulling ERC-20 funds.
3. `ATTESTATION_DELAY` is declared but not enforced.
4. pausing blocks execution of already-attested migrations.
5. execution does not enforce `minAmountOut`.

These limitations are launchpad-adjacent reference behavior, not a production bridge authorization.

## Qualification

Use Forge unit/fuzz/invariant tests plus Slither, Aderyn, Solhint, manual review and end-to-end transaction validation. High/critical findings introduced by V2 changes block release until resolved or explicitly rejected with evidence.

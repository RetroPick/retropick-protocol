# Core P0 supported-asset buyback/vesting increment — 2026-10-01

**Status:** scoped executable evidence; `CORE_BASELINE_P0_QUALIFIED` remains **BLOCKED**.  **Branch:** `codex/kuru-freeze-smart-contract-spec`.  **HEAD before this increment:** `88e957cb207a770b81f6c25a70a2c89163b91a9a`.  **Fork:** Monad Testnet chain 10143, block 66752717.  **Tools:** Foundry 1.8.3, solc 0.8.26, Python 3.12.3. No production Solidity changed and no live transaction was sent.

## Qualified behavior

The increment extends `contracts/test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol` through the real Factory, Deployer, launch token, Curve, production FeeEscrow and BuybackVault for both admitted quote classes: native MON and canonical chain-10143 Circle test USDC (`0x534b2f3A21130d7a60830c2Df862319e593943A3`).

1. **Near-graduation fold-back.** A buy of 101.3 quote units leaves sellable tokens outstanding and a positive buyback earmark. Sweeping folds the earmark into creator fees instead of executing a near-terminal internal swap. Fee, tax and earmark buckets clear; real quote reserve is unchanged; physical Curve quote equals `trackedQuote`; FeeEscrow records the exact protocol/creator split in native balance or actual Circle balance.

2. **Repeated sweeps and vesting.** Two buys and operator sweeps on one launch produce two BuybackVault lock deposits. After each sweep Curve fee/tax/earmark buckets are zero and Curve physical quote equals `trackedQuote`. Vault launch-token custody equals `totalLocked`. At half of the five-year vesting duration, creator release is nonzero and strictly less than locked; after the remaining duration, the release completes exactly to locked, vault custody reaches zero, and FeeEscrow token custody equals its recorded token liability.

## Reproduction

From `contracts/` with `MONAD_TESTNET_RPC_URL` exported from `.env.local`:

```bash
forge test --match-path test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol --summary
forge test --match-path test/v2/integration/RetroPickV4GraduationBehavior.t.sol --summary
```

Observed:

- Factory/Token/Curve/FeeEscrow/BuybackVault integration: **21 passed, 0 failed**.
- V4 behavioral oracle: **12 passed, 0 failed**.
- Exact completion/terminal-Q research models: `python3 -m unittest discover -s research/integration/kuru -p 'test_*.py'` — **37 passed**.

Representative gas observations: native fold-back 4,040,927; Circle fold-back 20,112,711; native repeated sweep/vest 5,371,965; Circle repeated sweep/vest 21,578,690. Gas is local fork evidence only.

## Remaining blockers

Successful native and Circle V4 graduation/retry/replay, all FeeEscrow callback faults, broader Factory/escrow/custody stateful coverage, Factory code extraction from the 11-byte EIP-170 margin, accepted venue/quote/envelope/custody/retry ADRs, and the exact terminal-Q graduation ceiling remain open. This evidence narrows the Core blocker but does not promote any gate.

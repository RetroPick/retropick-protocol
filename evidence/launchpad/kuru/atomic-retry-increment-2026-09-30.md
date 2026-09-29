# Atomic Kuru phase-2 research increment — 2026-09-30

**Classification:** partial real-fork evidence for B7/B8/B9/B10; none of those complete benchmark rows is `PASS`. The contracts live only in `contracts/test/v2/integration/`; they are deliberately **not** the production executor or accepted liquidity lock.

At Monad Testnet block `66752717`, `KuruAtomicResearchTest` deployed a current V2 launch token, separated original supply from terminal tracked token reserve, and committed 500,000 tokens plus 100 native MON to a research-only `GRADUATING` coordinator in phase 1. The real Kuru Router and vault were invoked in one separate phase-2 call. Foundry `1.8.3`, solc `0.8.26`, optimizer 200, `via_ir=true`: six tests passed, zero failed/skipped with:

```bash
cd contracts
set -a
source .env.local
set +a
forge test --match-contract KuruAtomicResearchTest -vv
```

Injected reverts immediately after environment validation, market/vault deployment, allowance, first vault deposit, and excess-token lock transfer each rolled back the entire phase-2 transaction. After every revert, `phase=GRADUATING`, destination/vault unset, the coordinator held the same 500,000 tokens and 100 MON, no market/vault code existed at the deterministic addresses, the no-exit lock held no assets, and the vault allowance was zero. The *same* secured launch then completed successfully. A second completion reverted before creating a second destination or moving assets. Additional fork tests forced the real Router deployment call to revert and returned false market-registry data after deployment; both preserved secured state and succeeded on retry after removing the injected fault. Separate tests changed OrderBook or vault implementation code and mocked an incorrect MarginAccount getter; all halted before deployment with secured state intact.

The native full research phase-2 `gasleft()` delta was **1,626,025 gas**. This is one input shape and one fork run, not a p50, target-chain transaction measurement or operational headroom claim. The narrower direct fork fixture measured Router deployment and vault deposit separately, but those cannot be added to infer production total gas.

The candidate no-exit receiver has no external transfer, approval, arbitrary-call or withdrawal method. The native fork fixture additionally demonstrated that an unrelated caller cannot use the lock's vault shares or excess launch tokens through `withdraw`/`transferFrom`; unknown `transfer`, `approve` and `execute` calls to the lock failed. That is a **candidate security negative**, not ADR-022 acceptance or a complete inherited-hook/rescue audit.

Still missing for full B8/B9/B10: actual Core Factory finalization semantics; adversarial returned market identity, wrong vault/token/spread/LP receiver; base/quote transfer failures; wrong or zero LP shares; seed-price/size rejection; remaining-approval/reentrancy probes; changed Router address/getter and observable pause; complete MON and selected-USDC small/medium/large gas distributions with target-chain block-gas context. The research `failAt` injection hook is intentionally unsafe for production and must not be copied into `contracts/src/v2/*`. No live transaction was sent.

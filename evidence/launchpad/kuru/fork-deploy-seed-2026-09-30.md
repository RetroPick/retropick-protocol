# Pinned Kuru fork deploy and first deposit — 2026-09-30

**Classification:** KURU-B5-FORK-DEPLOY `PASS` and KURU-B6-VAULT-SEED `PASS` for the declared research fixture at Monad Testnet block `66752717`. This does **not** pass quote policy, atomic phase-2, custody, gas feasibility, live testnet or `KURU_TARGET_FROZEN`.

Run from `contracts/` after loading the existing local environment without printing secrets:

```bash
set -a
source .env.local
set +a
forge test --match-contract KuruForkResearchTest -vv
```

Foundry `1.8.3`, solc `0.8.26`, optimizer 200, `via_ir=true`; pinned public Kuru contracts source `2060bb2736080c175d80d568bfdb6226bb5abd04`. Three fork tests passed, zero failed, zero skipped. The fixture deploys the **actual current V2 launch-token code** on the fork, derives terminal tracked reserve from the current Curve's 100/97 or 100/100 economics, and calls the real Kuru Router and vault. It is not a production graduation executor or an actual Core Factory integration.

| Quote | Router `deployProxy` gas inside fixture | First vault `deposit` gas inside fixture | Outcome |
| --- | ---: | ---: | --- |
| Native MON | 1,122,456 | 503,239 | Market/vault addresses and complete Router/OrderBook tuple match; physical 250,000-token + 100-MON seed and LP arithmetic match |
| Circle-listed testnet USDC `0x534b…43A3` | 1,285,609 | 635,237 | Real market/vault deployed; 97 USDC transferred exactly into vault/MarginAccount path |
| Kuru-listed testnet USDC `0x3bA3…1570` | 1,255,053 | 592,310 | Real market/vault deployed; 97 units of this distinct six-decimal token transferred exactly |

For every case, `computeAddress` and `computeVaultAddress` matched deployed code, `verifiedMarket` matched the entire independent `getMarketParams()` tuple, vault base/quote/market/MarginAccount/Router-owner/spread matched, and LP shares landed in a research-only no-exit receiver. Native physical balance and both ERC-20 transfer balances reconciled exactly. The first ask, bid, nonzero vault sizes and `sqrt(B×Q)−1000` receiver shares were checked. The 1,000 minimum shares remained in Kuru's MarginAccount as current source specifies.

The first native fork run **falsified the Python oracle's opening-bid formula**: the old model used `20,000/(20,000+spread)` and predicted `398009950248756`, while the real vault reported `396039603960396`. Pinned Kuru source uses `mulDivRound(ask, 10,000, 10,000+spread)` for the bid; `20,000` applies to vault order *sizes*, not bid price. The oracle, matrix and permanent regression test were corrected before these passing results. Historical failure is retained here as `COUNTEREXAMPLE_FOUND` against the old research oracle, not against Kuru.

USDC fork funding used Foundry's fork-only storage `deal` helper. It exercises each deployed token's transfer/allowance code but **does not prove issuer mint policy, long-term non-rebasing behavior, or live actor liquidity**. Actors A/B held zero of both USDC contracts at inspection. Circle's pause/blacklist authorities remain external trust risks. No live transaction was sent.

The gas figures are individual in-test call deltas, **not** complete atomic phase-2 gas, production transaction gas or a chain feasibility verdict. B7–B10 still require a secured-state coordinator, protected-custody adversarial matrix, atomic fault/retry tests and whole-transaction gas. A future execution must repeat B1 drift checks against fresh live state before relying on this fork block.

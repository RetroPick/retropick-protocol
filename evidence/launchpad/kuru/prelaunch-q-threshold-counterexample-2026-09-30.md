# Terminal secured quote is not the configured threshold

**Classification:** `COUNTEREXAMPLE_FOUND` for the simplifying equation `Q = graduationThreshold`. This is not evidence that the candidate Kuru seed itself fails on these two inputs. It is evidence that a launch-admission predicate computed only at the threshold is not a proof about the actual secured quote.

**Source baseline:** `8195573` on `codex/kuru-freeze-smart-contract-spec`. **Path:** one threshold-crossing buy, 1,000,000-token initial supply, 100-unit phantom quote, 100-unit graduation threshold, 100-bps curve fee, 50-bps creator tax, buyback disabled, no prior trades. The separate Circle test uses the actual canonical chain-10143 token on a fork at block `66752717`; neither test broadcasts.

`RetroPickBondingCurveV2.initialize` fixes terminal token reserve `T = floor(LP/(P+threshold)) = 500,000` tokens. For a one-shot clamped crossing buy, `BondingCurveMathV2.getAmountIn` calculates net quote `P + 1` raw unit. Grossing up by the two fees and flooring each fee separately yields physical terminal quote `Q = threshold + 2` raw units. `graduate()` sweeps the fee buckets, leaving this `Q` as the Factory's secured quote. The exact Python [fixture](prelaunch-q-threshold-counterexample-2026-09-30.json) and the Solidity [native/Circle behavioral tests](../../../contracts/test/v2/integration/RetroPickV4GraduationBehavior.t.sol) independently assert those values.

| Quote | Threshold raw | Actual secured Q raw | Base seed if Q = threshold | Base seed with actual Q | Difference in launch-token raw units |
| --- | ---: | ---: | ---: | ---: | ---: |
| native MON (18 decimals) | 100000000000000000000 | 100000000000000000002 | 250000000000000000000000 | 250000000000000000002499 | 2499 |
| Circle USDC (6 decimals) | 100000000 | 100000002 | 250000000000000000000000 | 250000002499999975000000 | 2499999975000000 |

Reproduce the exact model and committed JSON:

```bash
python3 research/integration/kuru/prelaunch_quote_witness.py
python3 -m unittest discover -s research/integration/kuru -p 'test_*.py' -v
```

Observed Python result: **16 tests passed**. With `MONAD_TESTNET_RPC_URL` loaded from `contracts/.env.local`, `forge test --match-path test/v2/integration/RetroPickV4GraduationBehavior.t.sol --summary` passed **2/2**, with no skips. The V4 seam is synthetic; the Circle token and Curve/Factory transfers are real on the pinned fork.

## Consequence for prelaunch admission

The committed [candidate profile matrix](parameter-profile-matrix-2026-09-30.json) explicitly assumes `Q = configured threshold`; it is a useful scenario, not the reachable-Q envelope. At launch creation, actual later `Q` is unknown. Earlier buys, sells, fee rounding and buyback behavior can change it. This witness alone does not give the minimum or maximum Q across all valid trading histories.

A complete Kuru prelaunch admission rule must either prove that **every reachable Q** under the accepted launch policy satisfies `B > 0`, min/max vault sizes, representable nonzero price/ticks, LP shares, arithmetic bounds and the accepted seed-error cap, or constrain Core's future trading/terminal path so that an accepted launch cannot leave that domain. A phase-2 check using measured Q is still mandatory, but it cannot retroactively satisfy the goal that an unsafe Kuru-bound launch be rejected *before* public bonding. No finite reachable-Q interval or corresponding invariant has yet been proven. `KURU-B3`, `KURU-B4`, and `KURU_TARGET_DEV_FROZEN` remain unqualified.

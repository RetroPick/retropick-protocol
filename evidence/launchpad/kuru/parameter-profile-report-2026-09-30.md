# Candidate Kuru parameter and seed envelope — 2026-09-30

**Classification:** reduced exact-integer research model; KURU-B3-PARAMETERS and KURU-B4-SEED are `DECISION_REQUIRED`, not `PASS`. No market tuple, seed tolerance or supported launch envelope has been accepted. Phase-2 gas is `NOT_MEASURED_FORK_PENDING` for every row.

The [machine-readable matrix](parameter-profile-matrix-2026-09-30.json) is reproducibly emitted by `python3 research/integration/kuru/benchmark_launch_profiles.py`; the test suite compares the committed artifact with generator output. It has five candidate supported profiles for each of native MON and six-decimal testnet USDC, plus one permanent negative for the Factory's one-token minimum. Both quote columns use nominal asset units; **no MON/USDC exchange-rate or value parity is assumed**.

The later [one-shot crossing counterexample](prelaunch-q-threshold-counterexample-2026-09-30.md) now proves that even the standard 100/100 Core launch secures `threshold + 2` raw quote units, not exactly the configured threshold, for both native MON and canonical Circle USDC. Thus the matrix's `Q = threshold` rows are scenario fixtures, not a launch-admission proof over reachable terminal Q.

## Source-derived terminal reserve

The earlier abstract seed fixture passed one million tokens directly as `T`. That is not the actual terminal reserve for a one-million-token launch. Current `RetroPickBondingCurveV2.initialize` reserves `T = floor(L × P / (P + threshold))`, where `L` is original launch supply and `P` is phantom quote. For the existing one-million-token, 100/100 fixture, `T` is 500,000 tokens; if physically secured quote `Q` equals the threshold, the Kuru seed is then `B = floor(T × Q / (P + Q)) = 250,000` tokens, not 500,000. The matrix derives `T` from `L` and records `L`, `T`, `P`, `Q`, `B` and `T−B` separately. It assumes `Q` exactly reaches the configured threshold; actual swept `Q` must be measured and the calculation repeated on fork/live evidence.

## Candidate tuple and profile results

The research tuple is `sizePrecision=10^8`, `pricePrecision=10^8`, `tickSize=1`, `minSize=10^6` (0.01 base token), `maxSize=10^16` (100 million base tokens), maker fee 0 bps, taker fee 30 bps, and AMM spread 100 bps. It satisfies the pinned Router/OrderBook predicates and type widths. These values are **candidates**, not product policy or SDK examples copied into protocol authority. The full JSON records first ask/bid, LP shares, raw vault sizes, integer bounds, exact seed-error ratio and tick-grid errors per quote.

| Profile | Original supply (tokens) | P/Q (quote units) | Terminal T (approx. tokens) | B (approx. tokens) | First ask (quote/token) | Ask tick error | Reduced-model result |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Factory minimum negative | 1 | 1/1 | 0.5 | 0.25 | 4 | 0 bps | Unsupported: vault ask size 0.00124378 token is below candidate 0.01-token minimum |
| Minimum candidate supported | 1,000 | 1/1 | 500 | 250 | 0.004 | 0 bps | Eligible in reduced model |
| Small | 100,000 | 10/11 | 47,619.05 | 24,943.31 | 0.00441 | 0 bps | Eligible in reduced model |
| Medium | 1,000,000 | 100/97 | 507,614.21 | 249,942.02 | 0.00038809 | 0 bps | Eligible in reduced model |
| Large | 100,000,000 | 1,000/1,001 | 49,975,012.49 | 24,999,993.75 | 0.00004004001 | 0.00250 bps | Eligible in reduced model |
| Maximum candidate supported | 1,000,000,000 | 10,000/9,500 | 512,820,512.82 | 249,835,634.45 | 0.000038025 | 1.31493 bps | Eligible in reduced model |

The normalized first prices and tick errors match between MON and USDC because both profile sets use the same *nominal* quote amounts and proper decimal normalization. Raw LP-share quantities differ sharply by quote decimals, as the JSON shows. `MAXIMUM_SUPPORTED_CANDIDATE` means the upper row in this proposed P0 envelope; it is **not** a proof of the global maximum that the Factory or Kuru can encode.

## Seed-price recommendation for decision

The proven exact floor identity still gives relative upward unrounded seed drift `< 1/B`; no new proof is claimed here. In the candidate matrix the largest observed ask-price tick-floor error is 1.31493 bps. Across the proposed supported rows the minimum first ask is 3,802.5 units at `pricePrecision=10^8`, so a one-unit tick truncation is below `10,000 / 3,802.5 ≈ 2.63` bps. A **proposed 5-bps combined seed-plus-tick limit** leaves margin above this candidate-domain bound without admitting a materially coarser tick. Acceptance would require exact cross-multiplied checks for both unrounded seed drift and limit-price tick deviation, nonzero distinct bid/ask ticks, and the accepted envelope. This is a recommendation for ADR-021, not an auto-accepted cap; other enabled Factory configs may violate it.

## Falsification and remaining work

- The Factory's one-token minimum passes its own supply floor but is outside the proposed Kuru min-size policy. If P0 promises *every* currently Factory-valid launch can graduate, this is a concrete policy contradiction. Either restrict future admitted launch configs or revise the min-size/envelope after adversarial and fork evidence; do not quietly call this row supported.
- The reduced model does not prove Router deployment, vault transfer behavior, quote-token compatibility, Kuru order placement or gas. B5/B6/B10 and live B11/B12 remain open.
- The final tuple must be checked against the current Kuru implementation and actual measured terminal `T`/`Q` for each launch. External implementation drift invalidates this packet's source premise.
- The user must decide the accepted fee/spread/tick/min-size classes, supported configuration envelope and maximum price error. Until then B3/B4 remain `DECISION_REQUIRED`.

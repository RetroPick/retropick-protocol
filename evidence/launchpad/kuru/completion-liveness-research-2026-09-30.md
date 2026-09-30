# Generic graduation-completion liveness research

**Classification:** `COUNTEREXAMPLE_FOUND` for threshold-only and current-reserve-only admission; `SUPPORTED_BY_DIFFERENTIAL_TESTS` for the exact immediate-completion oracle in the tested domain. This is research, not an accepted ceiling policy or production Curve change. **Source:** current `RetroPickBondingCurveV2` and `RetroPickBondingCurveMathV2`. **Fork:** Monad Testnet block 66752717 for canonical Circle test USDC; native cases run with chain ID 10143. No live transactions or signer use.

## Smallest verified pump and its scope

For the 1,000,000-token, `P=threshold=100` launch with 100-bps curve fee, 50-bps creator tax and buyback disabled, a **one-raw-unit buy** yields a positive token amount but selling exactly those tokens has zero gross quote output and reverts. A **two-raw-unit buy** has zero individually floored fee/tax, and selling exactly its token output returns one raw quote unit. The tracked token reserve returns to its original value while `realQuoteReserve` increases by one. This is the smallest positive round trip at this tested initial state and quote-unit granularity; it is not a global minimization over every possible launch configuration.

The native and real Circle-on-fork Solidity tests verify 16 successive two-unit cycles, each with `ΔrealQuoteReserve=+1`, then a terminal crossing at `threshold+34`. The independent exact-integer Python oracle verifies 1, 16 and 1,000 such cycles; at 1,000, terminal secured quote is `threshold+2002`. [Machine fixture](completion-liveness-witness-2026-09-30.json). There is no configured history/volume limit in `LaunchConfig`. The global `uint256` ceiling is a trivial finite bound; this evidence does **not** prove mathematical unboundedness or a maximum reachable `Q`. It does prove that the configured threshold, one-shot `Q`, and any fixed small rounding allowance are not all-history bounds. In accordance with the research priority, work stops on a tight all-history envelope for the unrestricted current machine and moves to a generic liveness constraint.

For a zero-fee two-leg cycle at token reserve `t` and virtual quote `v`, the buy takes `x=floor(g*t/(v+g))` tokens for gross quote `g`; selling those `x` tokens returns `floor(x*(v+g)/t)` gross quote. When `x>0`, `v+g<t`, and `g*t` is not divisible by `v+g`, the latter is `g−1`, giving one raw unit of reserve drift. The tested two-unit path satisfies those conditions in its enumerated states. The caller loses one raw quote unit per cycle plus gas; this is a liveness/admission issue, not a demonstrated profit or solvency extraction.

### Exact lower endpoint, not an upper envelope

Under the current accepted exact-transfer Curve arithmetic, let `k=(P+R)*t` for tradeable real quote `R` and tracked token reserve `t`. A buy with net tradeable input `a` leaves `t'=t−floor(a*t/(P+R+a))=ceil(t*(P+R)/(P+R+a))`, hence `(P+R+a)*t' >= k`. A sell of `x` tokens pays gross `floor(x*(P+R)/(t+x))`, so its post-trade virtual quote is `ceil((P+R)*t/(t+x))` and the product again cannot fall. An executed internal buyback has the same buy-side reserve transformation; a fee-only sweep leaves `R` and `t` unchanged. This is a mathematical identity **under those transition and exact-backing assumptions**, not a proof about a malicious quote token or an unaudited transition.

If initial token reserve is `L`, `T=floor(L*P/(P+threshold))` is the fixed terminal token reserve, and the tradeable product never falls, then every terminal state satisfies `Q >= ceil(L*P/T)−P >= threshold`. The [oracle](../../../research/integration/kuru/completion_terminal_quote.py) computes that integer lower endpoint. A 63×32×32 small-parameter grid (valid `T` cells only) and the bounded stateful campaign checked it. The upper endpoint still requires an accepted generic ceiling; the global `uint256` limit is not a usable Kuru admission policy.

## Exact immediate-completion oracle

Let `R=trackedQuote−quoteFeeBalance−creatorTaxBalance`, `t=trackedTokens`, `T=reservedTokens`, `n=t−T` and `v=phantomQuote+R`. For `n>0`, the [Python oracle](../../../research/integration/kuru/completion_terminal_quote.py) follows production's checked arithmetic:

```text
net   = floor((n * v * 10000) / (T * 10000)) + 1
gross = ceil(net * 10000 / (10000 - curveFeeBps - creatorTaxBps))
fee   = floor(gross * curveFeeBps / 10000)
tax   = floor(gross * creatorTaxBps / 10000)
completionTerminalQuote(state) = R + gross - fee - tax
```

The oracle also checks the initial `getAmountOut` path reaches `n`, the Solidity intermediate/`uint256` widths, fee-bucket additions, and the final buy's slippage RHS. For `n=0`, no buy is needed and the immediate graduation value is `R`. The proposed transaction submits exactly `gross`, `minTokensOut=0`, with an exact-transfer quote asset and sufficient buyer funds/allowance. Graduation skips internal buyback, clears/pays pending and new fees, and sweeps the remaining tradeable quote. Those funding, token-liveness, gas, and destination assumptions are explicit; the formula is not a claim that any third party will fund completion.

The [Solidity differential tests](../../../contracts/test/v2/integration/RetroPickV4GraduationBehavior.t.sol) compute this expression using the *production* `getAmountIn` and `Math.mulDiv`, snapshot each real Curve state, execute the immediate terminal buy, compare predicted quote against the Factory's physically secured quote, then restore the state. Cases cover untouched, tiny partial buy, reserve-gaining round trip, larger partial buy with pending fee/tax, sell after that buy, explicit sweep, and buyback-enabled before/after an internal sweep. Both native MON and canonical Circle paths are represented. The V4 destination seam is synthetic; this differential is about Core terminal quote, not real V4 compatibility.

## Research-only liveness ceiling attack

Choose an **illustrative, unaccepted** generic ceiling `C=threshold+10 raw units`. At the untouched state, immediate completion is `threshold+2`. After four two-unit round trips it is `threshold+10`, still accepted. The fifth buy leaves completion at `C`; the fifth sell would leave `R=5` raw units, so `R<=C`, but completion becomes `threshold+12>C`. The current Curve accepts that sell. A research semantic guard that reverts the fifth sell keeps the previous after-buy state, which the differential test immediately completes at `C`. Python and Solidity agree for native and Circle.

The proposed invariant is: after launch initialization and every accepted buy, sell, fee sweep, buyback sweep, and any other economic state mutation, `completionTerminalQuote(state) <= immutable graduationQuoteCeiling` and the oracle's exact execution path remains valid. Inductively, an accepted state then has an *arithmetic* immediate-completion path under the stated exact-asset/funded-buyer assumptions. Checking only `R<=ceiling` is insufficient. The Curve need not know the venue; a separate accepted graduation policy would derive `graduationQuoteCeiling` at launch and commit it immutably. No production implementation or ADR acceptance follows from this report.

A separate [bounded stateful model campaign](curve-liveness-campaign-2026-09-30.json) applies this proposed post-transition guard to current-style buy/sell/sweep/toggle actions for one aggregate holder. It runs three fixed seeds for each of 18- and 6-decimal quote classes, 300 randomized attempts per history plus eight deliberately boundary-reaching calls: **1,848 total attempts**, **1,032 accepted**, **285 ceiling rejections**, **531 invalid calls**, and no accepted state above the illustrative ceiling. Invalid calls are expected rejects, not invariant failures. The buyback-enabled sweep arithmetic is modeled, but ERC20 callbacks, authorization, physical balance loss, full Core/Factory state, and an actual onchain guard are outside this bounded model. The result tests the proposed rule; it is not a production invariant PASS.

## Reproduction and remaining falsifiers

`python3 -m unittest discover -s research/integration/kuru -p 'test_*.py' -v` passes **33/33** including fixture regeneration, minimal pump, ceiling rejection, lower-bound grid, stateful campaign, bounded all-Q candidate cells and `uint256` negative. With the existing `contracts/.env.local` loaded, `forge test --match-path test/v2/integration/RetroPickV4GraduationBehavior.t.sol --summary` passes **12/12**, no skips. Forge 1.8.3, solc 0.8.26, optimizer 200, viaIR as locally configured.

Still required before B3/B4 or Core liveness can pass: a *committed-onchain* generic guard design, full transition inventory (including unusual fee rescue), randomized/stateful accepted-transition campaign, buyer/approval/gas feasibility, accepted ceiling policy, and Kuru endpoint/precision/size proof for every `Q` in the chosen interval. External Circle issuer freeze/blacklist remains a liveness risk outside this arithmetic theorem. `KURU_TARGET_DEV_FROZEN` remains blocked.

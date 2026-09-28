# ADR-R03 decision packet — settlement payout semantics

**Recommendation: REVISE.** ADR-R03 remains `PROPOSED`. The global cumulative cursor repairs aggregate underpayment, but the economic rule has not specified whether individual holders may lose an amount that grows with redemption fragmentation and ordering. This packet does not replace the canonical oracle or authorize production Solidity.

## Problem and old rule

The canonical `FixedPointSettlement.redeem` pays `floor(q * payoutWad / D)` independently on each call, with `D = 10^18 * 10^(18 - settlementDecimals)`. `CX-FP-SETTLEMENT-001` is minimal: supply 2, payout `D-1`, two 1-unit redemptions pay 0+0 while the one-shot floor is 1. Exact ceil funding is 2, so the old rule leaves 2 raw units that a sweep could capture. Funding remains solvent; the defect is lost aggregate holder payment. The old rule and this witness remain permanent negative controls.

## Candidate and what is proved

For one globally shared redeemed cursor `R`, the candidate pays

```text
floor((R + q) * payoutWad / D) - floor(R * payoutWad / D).
```

For a partition `q_1,...,q_k` of fixed initial supply `S`, summing consecutive differences cancels every interior term and gives `floor(S * payoutWad / D) - floor(0)`. With balance exactly `ceil(S * payoutWad / D)`, the final residual is `ceil(x)-floor(x)`, hence 0 or 1 raw unit. A single call receives its isolated floor or one additional raw unit. These are `PROVEN_UNDER_ASSUMPTIONS` for nonnegative integers, positive `D`, no later mint, one global cursor, full redemption, and transfers that preserve actual token balances. They say nothing about the total allocated to one holder across interleaved calls. A per-holder cursor and the independent per-call floor both fail the aggregate identity on the original two-holder witness.

Historical bounded evidence covers 378,530 states and 2,542,061 transitions for the candidate, plus a separate composition extension through supply 16. The current Solidity research kernel matched the seven committed Python fixtures, and its 6/8/18 precision differential fixture historically matched 129 fitting cells. Twenty-four zero-supply cells and 15 products were outside that Solidity fixture domain. These are bounded/executable claims, not a universal EVM proof. The existing stateful settlement suite passed again on seed 20260928: 256 runs, depth 128, 32,768 calls, zero reverts/discards, checking five aggregate/funding invariants.

## New holder-allocation counterexample

`CX-FP-CUM-HOLDER-001` falsifies a distinct proposed entitlement: that each holder receives at least `floor(its redeemed units * payoutWad / D)` regardless of fragmentation and ordering. Set `payoutWad = WAD/2 + 1`; at settlement decimals `d`, redeem chunks of `10^(18-d)` series units. A and B each own `n` chunks and redeem in `A,B` order `n` times. For `1 <= n <= WAD/4`, A receives 0 raw units and B receives `n`; each isolated holder floor is `floor(n/2)`. Aggregate payment remains `n` and exact-ceil residual remains 1. Z3 5.1.0 found the negation of each step, isolated-floor, aggregate, and funding identity unsatisfiable over that declared domain. The same integer family applies to admitted decimals 0..18 after scaling each chunk.

The Python oracle executed `n={2,10,1000}` at decimals 6, 8, and 18. At `n=1000`, A receives 0 versus an isolated floor of 500 and B receives 1000 versus 500. Solidity replayed the `n=10` cases at decimals 6, 8, and 18: 0 and 10 versus isolated floors of 5 each. Machine-readable source, fixture, and result: `evidence/research/prism/holder-fairness-2026-09-28.json`. This does not refute aggregate telescoping or the 0/1 residual bound. It establishes a potentially material allocation choice that prior aggregate-only invariants do not decide.

The order is reachable when holders fragment redemptions. A single full-balance redemption has at most a one-unit difference from its isolated floor, so the large deviation requires repeated calls and advantageous ordering. A single measured gas example used about 40,041 gas for a zero-payout redemption and 52,188 gas for the following paying redemption. These are one local sample, not a gas distribution or proof of profitable MEV. Reordering incentives and actual cost on the target chain remain to be measured before characterizing exploitability.

## Fixed-point and EVM domain

The candidate declares settlement decimals 0..18, giving `10^18 <= D <= 10^36`. Solidity `Math.mulDiv` computes full-precision quotients for fitting results; the constructor's allocation sum uses checked uint256 addition, and redemption quantities remain bounded by allocated supply. However `payoutWad` is not capped at construction. Admission must reject any supply/payout configuration for which ceil funding or any cumulative quotient exceeds uint256; otherwise a deployed candidate can later revert at funding or payout calculation. Z3 integer identities do not prove those EVM bounds. The historical precision matrix explicitly excluded overflowing products. No universal uint256 claim is made here.

## Funding, balance changes, and residual ownership

`makeRedeemable` rejects a balance below exact ceil funding; the new callback test shows a reentrant settlement-token transfer reverts the entire redemption and preserves the cursor, payout, supply, and balances. Existing tests show a fee-on-transfer shortfall blocks opening. Existing rebasing tests show that balance loss after opening can leave `redeemable=true` while a later payout reverts; therefore admission of a token whose balance can fall externally is a solvency decision, not a successful guard proof.

The 0/1 residual bound applies only to exact ceil funding with no later token balance change. A larger end balance may include overfunding or direct ERC20 transfers. The current kernel accepts an external token balance and records no funding provenance, so it cannot identify which raw unit is rounding residual versus donation. No sweep is implemented. The separate residual-policy packet must decide ownership and accounting before any sweep or archive transfer exists.

## Decision required

1. State the holder entitlement precisely. If only aggregate payment is promised, explicitly accept order-dependent carry allocation and document the transaction-order exposure. If holders are owed an order-independent floor or bounded deviation, revise the settlement mechanism and prove the chosen bound across transfers and fragmentation.
2. Set admissible payout, supply, decimal, and settlement-token domains so the onchain quotient fits uint256 and balances cannot shrink externally.
3. Resolve residual ownership separately, with an explicit treatment of donations and overfunding.

The current recommendation is **REVISE** rather than ACCEPT because the proposed series is a transferable fungible claim and the holder-level allocation rule has not been approved. A future acceptance of the aggregate-only rule would require that economic promise and its ordering consequences to be explicit; acceptance of a holder-fair rule requires a new oracle, machine fixtures, Solidity differential replay, and stateful holder-level invariants. In either case, after human acceptance the canonical fixed-point oracle, theorem registry, candidate architecture, and affected tests must be updated together. Until then, `MATH-1D` and `MATH-1` remain `FAIL` and `CONTRACT-1` remains unmet.

The recommendation would be falsified by a proved order-independent holder allocation satisfying the accepted entitlement with feasible uint256 arithmetic, or by an explicit human decision that aggregate-only settlement with the measured ordering exposure is the intended economic rule. Neither has occurred.

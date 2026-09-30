# Wide terminal-Q sufficient bound for the candidate Kuru tuple

**Classification:** `PROVEN_UNDER_ASSUMPTIONS` for the named reduced-model checks over the specified continuous integer-Q intervals; `NOT_YET_VALIDATED` for accepted P0 admission and real fork integration. The upper endpoint is **100× configured threshold solely as a stress input**, not a recommended `graduationQuoteCeiling` or economic policy. The profiles and fixed tuple remain candidates.

The [proof checker](../../../research/integration/kuru/terminal_q_interval.py) takes the product-invariant lower Q and an arbitrary finite upper Q. It does not enumerate the raw-Q domain. For `B(Q)=floor(TQ/(P+Q))`, positive `P,T` make `B` nondecreasing. Consequently the minimum/maximum base seed, vault ask/bid sizes and first-mint `sqrt(BQ)−1000` shares are bounded by their respective endpoints. All relevant candidate size limits and checked arithmetic intermediates are tested at safe endpoint maxima.

For every `Q` in `[Qlo,Qhi]`, the vault's first ask price `A(Q)=floor(Q·baseScale·1e18/(B(Q)·quoteScale))` obeys:

```text
A(Q) >= floor((P+Qlo)·baseScale·1e18/(T·quoteScale))
A(Q) <= floor(Qhi·baseScale·1e18/(B(Qlo)·quoteScale))
```

The pinned first bid is a monotone half-up function of `A`. Its ask-minus-bid gap is nondecreasing because the bid slope is below one and each one-unit ask increment raises the rounded bid by at most one. A lower bound on that gap, converted to price units, guarantees distinct nonzero tick floors; the ask upper bound guards the `uint32` tick domain. Flooring either price to an executable tick loses strictly less than one tick, so the bid lower bound supplies a uniform tick-error bound. The seed-relative drift is strictly less than `1/B(Qlo)`. With seed drift `s` and tick loss `d` measured against its vault price, the conservative terminal-reference bound is `s+d+s·d`. The checker requires that bound to fit the unaccepted five-bps cap. A failed sufficient condition means **not proven**, not automatically unseedable.

The [machine summary](terminal-q-wide-bound-2026-09-30.json) records ten positive profile/quote rows and two negative controls. The five non-minimum research profiles for MON and for canonical six-decimal Circle test USDC satisfy every reduced-model sufficient condition from the proven Q lower bound through 100× their threshold. The one-token Factory-minimum profile fails candidate minimum-size and tick-representability sufficient checks in both quote classes. It already fails exact bounded cells on min size; the extra wide-bound tick failure is only a failed sufficient condition and is not claimed to occur at every Q. Deterministic random spot checks at 100 Q values per positive row and exhaustive small intervals independently challenge the proof implementation; they do not replace its algebra.

This is a **technical range result for ten isolated candidate configurations**, not a freeze of LaunchConfig. It does not prove the Core can or should admit a 100×-threshold terminal quote, nor cover every supply/phantom/threshold combination between profile points. The next dependencies remain: owner-selected launch and quote envelope, accepted seed/tick tolerance, an immutable generic completion ceiling, onchain transition-guard qualification, and pinned real-Router/vault boundary tests. No live transactions were sent and no production Solidity was changed.

Reproduce: `python3 -m unittest discover -s research/integration/kuru -p 'test_*.py'` and `python3 research/integration/kuru/wide_q_envelope.py`.

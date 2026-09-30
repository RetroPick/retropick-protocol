# Bounded all-Q Kuru envelope, research only

**Classification:** `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN` for 155 raw-Q cells in twelve illustrative intervals under the pinned reduced Kuru arithmetic; `NOT_YET_VALIDATED` for the actual P0 launch envelope. This does not freeze B3/B4 or ADR-021. No live transaction was sent.

The [executable validator](../../../research/integration/kuru/terminal_q_interval.py) computes `T=floor(LP/(P+threshold))`, the proven lower terminal-Q endpoint `ceil(LP/T)−P`, and every raw integer `Q` through a caller-supplied ceiling. The [matrix driver](../../../research/integration/kuru/bounded_q_envelope.py) uses the existing research tuple and an **illustrative** ceiling of exact initial immediate-completion Q plus ten raw quote units. It checks both native MON and the six-decimal canonical chain-10143 Circle quote class. The five-bps combined seed/tick bound is also a **candidate**, not an accepted economic tolerance.

| Quote | Cells | Valid cells | Negative-control failure |
| --- | ---: | ---: | --- |
| MON | 80 | 66 | Factory-minimum one-token launch violates candidate vault min size in all 14 cells |
| Circle test USDC | 75 | 62 | Same failure in all 13 cells |
| Total | **155** | **128** | **27 expected invalid cells** |

The five non-minimum profiles per quote passed every cell of their tiny interval in the reduced model. The machine-readable [summary](terminal-q-bounded-envelope-2026-09-30.json) and generator preserve the input and reproducible result. The named `MAXIMUM_SUPPORTED_CANDIDATE` profile is a research candidate, not a protocol maximum.

The combined candidate price-error check is conservative in terminal-reference units: if `s` is relative seed drift and `d` is the larger relative ask/bid tick loss against its respective vault price, it checks `s + d + s*d <= 5/10,000`. The product term matters because the two errors use different denominators. Rechecking with this term leaves the 155-cell classification unchanged.

`B(Q)=floor(TQ/(P+Q))` is nondecreasing for positive `P,T`; the pinned first-deposit order-size formulas and LP shares are likewise nondecreasing in `B` and `Q` within their valid domain. The validator checks these observed relations but does **not** extrapolate tick representability or combined price error from endpoints: floors and tick-grid transitions may create interior failures. It refuses intervals wider than its explicit cell budget instead of claiming an endpoint proof over 18-decimal raw-Q space. The all-Q production requirement therefore remains open.

The hard negative is material: current Factory supply admission permits the one-token case, while the proposed fixed Kuru min-size policy rejects it for every tested Q. A Kuru-bound launch cannot inherit Factory's current broad supply floor without a separate policy restriction or parameter class. The Curve's proposed generic liveness guard and the economically accepted ceiling are both absent from production. Future qualification must decide a supported configuration envelope, prove or exhaustively check the full Q range with safe breakpoint reasoning, then exercise representative boundaries on the real pinned fork. The candidate tuple and cap need explicit owner acceptance.

Reproduce: `python3 -m unittest discover -s research/integration/kuru -p 'test_*.py'` (33 tests pass), then `python3 research/integration/kuru/bounded_q_envelope.py`. No production contract was changed.

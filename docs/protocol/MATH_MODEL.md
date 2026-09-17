# PRISM Phase-1 Mathematical Model

**Status:** CANONICAL MATH-1 specification  
**Scope:** exact-backed long-only replicated outcome assets  
**Reference implementation:** `research/prism-model/`  
**Contract implication:** Solidity must later match this model under an explicit fixed-point tolerance.

---

## 1. Scientific classification

Every claim in this document belongs to one of three classes.

### A. Formal / deductive

A statement derived for all states satisfying explicit assumptions.

Status label:

```text
PROVEN_UNDER_ASSUMPTIONS
```

### B. Exhaustive finite-domain verification

A property verified for all states/actions inside a declared finite test domain.

Status label:

```text
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
```

### C. Market / empirical

A claim depending on traders, orderbook depth, latency, market makers or external behavior.

Status labels:

```text
SUPPORTED_BY_SIMULATION
NOT_YET_VALIDATED
```

Market simulation cannot promote an unsafe accounting property to a proof.

---

## 2. Assumptions

The Phase-1 exact-replication theorems require:

1. admitted component payoff functions are deterministic at terminal resolution;
2. component terminal payoffs are non-negative;
3. the canonical component identities and weights cannot mutate after activation;
4. series-scoped backing accounting cannot double-count the same reserved units;
5. component transfers into/out of the vault follow the modelled state transition;
6. the resolver eventually commits the correct canonical terminal state according to the market's immutable ResolutionSpec;
7. final settlement cannot be paid before the settlement-funding invariant holds;
8. the exact-arithmetic model is translated to Solidity using a separately proven fixed-point policy.

The model does not assume secondary-market liquidity or rational arbitrage is always available.

---

## 3. Core payoff space

Let terminal worlds be:

```math
\Omega = \{\omega_1,\ldots,\omega_m\}
```

For each component asset `A_i`, define terminal payoff:

```math
g_i(\omega) \ge 0
```

Construct payoff matrix:

```math
G =
\begin{bmatrix}
g_1(\omega_1) & \cdots & g_n(\omega_1)\\
\vdots & & \vdots\\
g_1(\omega_m) & \cdots & g_n(\omega_m)
\end{bmatrix}
```

Let the PRISM replication vector be:

```math
x=(x_1,\ldots,x_n), \qquad x_i\ge0
```

Then one PRISM token has terminal payoff:

```math
\boxed{h=Gx}
```

or:

```math
\boxed{h(\omega)=\sum_i x_i g_i(\omega)}
```

The feasible long-only payoff set is the non-negative cone:

```math
\boxed{\mathcal{C}=\{Gx\mid x\ge0\}}
```

A payoff outside `C` is not admitted by Phase 1.

---

## 4. Series admission modes

### 4.1 Basket mode

The creator supplies `x` directly. The system computes:

```math
h=Gx
```

and stores/commits the canonical representation.

No spanning solve is necessary.

### 4.2 Payoff mode

The creator supplies target payoff `h*`. Admission solves:

```math
Gx=h^*
```

subject to:

```math
x\ge0
```

If no exact solution exists in the canonical numeric domain:

```text
PRODUCT_NOT_REPLICABLE
```

For multiple exact solutions, a later admission policy may minimize executable cost:

```math
\min_x p^T x
```

subject to:

```math
Gx=h^*,\quad x\ge0
```

Cost optimization does not change the solvency theorem; it only chooses among valid exact replicas.

---

## 5. Component-backing invariant

Let:

- `S` = outstanding PRISM supply;
- `B_i` = vault/accounted units of component `i` backing this series;
- `x_i` = component units required per PRISM token.

Require:

```math
\boxed{B_i\ge Sx_i \qquad \forall i}
```

Define backing margin:

```math
M_i = B_i-Sx_i
```

A negative `M_i` is forbidden.

---

## 6. Theorem A — valid mint preserves backing

Suppose the backing invariant holds before mint.

Mint `Q>0` PRISM only after depositing/allocating:

```math
Qx_i
```

for every component.

Then:

```math
S' = S+Q
```

```math
B_i'=B_i+Qx_i
```

Because:

```math
B_i\ge Sx_i
```

we have:

```math
B_i+Qx_i \ge Sx_i+Qx_i=(S+Q)x_i
```

therefore:

```math
\boxed{B_i'\ge S'x_i}
```

and:

```math
M_i'=(B_i+Qx_i)-(S+Q)x_i=M_i
```

So exact-backed minting preserves existing margin.

**Status:** `PROVEN_UNDER_ASSUMPTIONS`.

---

## 7. Theorem B — in-kind redemption preserves backing

Redeem `Q` where:

```math
0<Q\le S
```

Burn liability `Q` and release:

```math
Qx_i
```

for every component.

Then:

```math
S'=S-Q
```

```math
B_i'=B_i-Qx_i
```

From `B_i >= Sx_i`:

```math
B_i-Qx_i \ge Sx_i-Qx_i=(S-Q)x_i
```

thus:

```math
\boxed{B_i'\ge S'x_i}
```

and:

```math
M_i'=M_i
```

**Status:** `PROVEN_UNDER_ASSUMPTIONS`.

---

## 8. Theorem C — exact component backing implies terminal solvency

Terminal backing value in world `omega`:

```math
V_B(\omega)=\sum_i B_i g_i(\omega)
```

Outstanding PRISM liability:

```math
L_P(\omega)=S h(\omega)
```

Since:

```math
h(\omega)=\sum_i x_i g_i(\omega)
```

and:

```math
B_i\ge Sx_i
```

with:

```math
g_i(\omega)\ge0
```

then:

```math
B_i g_i(\omega)\ge Sx_i g_i(\omega)
```

for each component. Summing:

```math
\sum_i B_i g_i(\omega)
\ge
S\sum_i x_i g_i(\omega)
```

therefore:

```math
\boxed{V_B(\omega)\ge L_P(\omega)\qquad\forall\omega\in\Omega}
```

**Status:** `PROVEN_UNDER_ASSUMPTIONS`.

This is why Phase 1 does not need to enumerate terminal worlds inside every mint transaction: exact replication is proved at admission; component backing is enforced at runtime.

---

## 9. Canonical pFEDBTC model

Define components:

```text
F = FED_YES
B = BTC_NO
```

with worlds ordered as:

1. Fed No, BTC No
2. Fed No, BTC Yes
3. Fed Yes, BTC No
4. Fed Yes, BTC Yes

Then:

```math
G=
\begin{bmatrix}
0&1\\
0&0\\
1&1\\
1&0
\end{bmatrix}
```

and:

```math
x=
\begin{bmatrix}
0.6\\
0.4
\end{bmatrix}
```

so:

```math
h=Gx=
\begin{bmatrix}
0.4\\
0\\
1\\
0.6
\end{bmatrix}
```

Canonical payoff table:

| Fed | BTC condition | FED_YES | BTC_NO | pFEDBTC |
|---|---|---:|---:|---:|
| No | No | 0 | 1 | 0.40 |
| No | Yes | 0 | 0 | 0.00 |
| Yes | No | 1 | 1 | 1.00 |
| Yes | Yes | 1 | 0 | 0.60 |

For supply:

```math
S=1000
```

exact backing is:

```text
600 FED_YES
400 BTC_NO
```

The `Fed=YES, BTC=NO` world is the maximum payout state and pays `1.00`, not `0.60`.

---

## 10. Non-replicability counterexample

Let:

```math
A=(0,0,1,1)
```

```math
B=(0,1,0,1)
```

and desired AND payoff:

```math
h_{AND}=(0,0,0,1)
```

Any non-negative linear combination has form:

```math
xA+yB=(0,y,x,x+y)
```

Matching the second coordinate requires:

```math
y=0
```

Matching the third requires:

```math
x=0
```

which forces fourth coordinate:

```math
x+y=0
```

instead of `1`.

Therefore:

```math
\boxed{h_{AND}\notin\mathcal C}
```

for this component basis.

**Status:** formal counterexample.

A future StatePool/SLE mechanism may expand the payoff basis, but it is not part of Phase 1.

---

## 11. Partial resolution

Suppose:

```math
P=0.6A+0.4B
```

and `A` resolves to `a*` while `B` remains uncertain.

Then a mark based on remaining component price is:

```math
P_t=0.6a^*+0.4P_B(t)
```

If `A=1`:

```math
P_t=0.6+0.4P_B(t)
```

If `A=0`:

```math
P_t=0.4P_B(t)
```

General form with resolved set `R` and unresolved set `U`:

```math
\boxed{NAV_t=\sum_{i\in R}x_i r_i+\sum_{j\in U}x_jP_j(t)}
```

This is a valuation identity given the supplied marks. It does not force an exchange price.

### 11.1 Payoff-equivalent backing transformation

A canonically resolved component may be redeemed into settlement cash if the transformed portfolio preserves all remaining obligations.

For a component resolving to `r_i`, replacing `x_i` units of that component by `x_i r_i` settlement value is safe only under the accepted component/settlement semantics and deterministic accounting rules.

---

## 12. Final settlement theorem

After all payoff-relevant components resolve to terminal world `omega*`, define:

```math
R=h(\omega^*)
```

Outstanding cash liability:

```math
L=S R
```

The series may enter `REDEEMABLE` only if:

```math
\boxed{SettlementBalance\ge SR}
```

A final redemption of `Q` burns `Q` PRISM and pays:

```math
Q R
```

After redemption:

```math
S'=S-Q
```

```math
SettlementBalance'=SettlementBalance-QR
```

If the funding invariant held before redemption:

```math
SettlementBalance-QR\ge SR-QR=(S-Q)R
```

so it remains funded for all remaining supply.

**Status:** `PROVEN_UNDER_ASSUMPTIONS`.

---

## 13. Native binary complete-set model

For a valid binary market:

```math
YES(\omega)+NO(\omega)=1
```

for every terminal world.

If `C` units of collateral are split:

```text
C collateral
-> C YES
-> C NO
```

then before any asymmetric protocol error:

```math
S_Y=S_N=C_{locked}
```

A merge burns equal amounts of YES and NO and returns the corresponding collateral.

### 13.1 Open interest

For the fully collateralized binary complete-set market:

```math
\boxed{OI=S_Y=S_N=C_{locked}}
```

assuming valid split/merge accounting.

Do not define:

```math
OI=S_Y+S_N
```

because that counts both sides of one complete collateral set.

---

## 14. Complete-set executable parity

The conceptual terminal identity is:

```math
YES+NO=1
```

but trading arbitrage must use executable sides of the orderbook.

### Split-and-sell opportunity

If:

```math
Bid_Y+Bid_N > 1 + C_{split}
```

then an arbitrageur can, subject to executable depth:

```text
lock 1 collateral
-> mint 1 YES + 1 NO
-> sell both at bids
```

### Buy-and-merge opportunity

If:

```math
Ask_Y+Ask_N < 1 - C_{merge}
```

then an arbitrageur can:

```text
buy 1 YES + 1 NO
-> merge
-> receive 1 collateral
```

where `C_split` and `C_merge` include fees, gas, slippage and operational costs.

This is a market incentive, not an instantaneous price guarantee.

---

## 15. PRISM create/redeem valuation band

For one PRISM token with component weights `x_i`, define executable creation cost:

```math
C_{create}=\sum_i x_i Ask_i+F_{create}
```

Define executable in-kind redemption value:

```math
V_{redeem}=\sum_i x_i Bid_i-F_{redeem}
```

Normally:

```math
V_{redeem}\le C_{create}
```

If market price `P` is persistently above executable creation cost, there may be a create-and-sell opportunity.

If `P` is persistently below executable redemption value, there may be a buy-redeem-sell-components opportunity.

Idealized no-arbitrage relation:

```math
V_{redeem}\lesssim P\lesssim C_{create}
```

Practical relation with risk terms:

```math
\boxed{V_{redeem}-\rho_r\lesssim P\lesssim C_{create}+\rho_c}
```

where `rho` may include:

- latency;
- capital cost;
- inventory risk;
- orderbook depth/slippage;
- transaction failure;
- resolution proximity;
- operational risk.

**Status:** market hypothesis, not formal invariant.

---

## 16. Post-resolution ERC20/ERC20 pricing identity

Once final payout is fixed at `R` settlement units, event uncertainty is gone.

If settlement is USD-like and quote ERC-20 `Q` has USD price `P_Q`, then idealized relative value is:

```math
\boxed{P_{PRISM/Q}=\frac{R}{P_Q}}
```

before fees, delay and residual risk.

Example:

```text
final PRISM payout = $0.60
MON = $2.00
```

then:

```math
P_{PRISM/MON}=0.30
```

If MON falls to `$1.00`, then:

```math
P_{PRISM/MON}=0.60
```

without any change in PRISM's resolved event payoff.

This separates:

```text
EVENT_VOLATILITY
```

from:

```text
QUOTE_ASSET_VOLATILITY
```

A zero-payout token has zero protocol redemption value, even if residual speculative/dust trading remains technically possible.

---

## 17. Supply elasticity

PRISM supply is endogenous:

```math
S_{t+1}=S_t+Mint_t-Redeem_t
```

Supply can expand when backing is supplied and minting is permitted.

Supply contracts when PRISM is burned for its backing or final settlement.

This is economically closer to an ETF-like creation/redemption mechanism than to a fixed-supply token.

---

## 18. What mathematics does not prove

The model does not prove:

- Kuru orderbooks will have adequate depth;
- arbitrageurs will always act;
- prices will instantly converge to NAV;
- market makers will remain profitable near resolution jumps;
- users will demand PRISM;
- cross-chain wrappers are safe;
- legal/regulatory treatment;
- sponsor integrations will remain unchanged.

Those require simulation, live evidence, product validation, legal analysis or separate protocol proofs.

---

## 19. MATH-1 work packages

### MATH-1A — Exact accounting kernel

- exact payoff calculation;
- exact backing requirements;
- mint/redeem conservation;
- terminal solvency;
- final settlement funding.

### MATH-1B — Exhaustive small-state verification

Enumerate bounded domains for:

- supply;
- backing;
- legal lifecycle transitions;
- terminal worlds;
- representative rational weights.

### MATH-1C — Adversarial/property testing

Attempt:

- over-mint;
- double redemption;
- backing withdrawal before burn;
- illegal state resurrection;
- duplicate resolution;
- underfunded final settlement;
- malformed weights;
- duplicated component accounting;
- extreme values.

### MATH-1D — Symbolic/formal checks

Use symbolic algebra / SMT where appropriate for:

- mint preservation theorem;
- redemption preservation theorem;
- terminal solvency theorem;
- settlement funding preservation;
- lifecycle reachability constraints.

### MATH-1E — Fixed-point translation

Define:

- scale;
- token decimal normalization;
- multiplication/division order;
- round-up versus round-down rules;
- dust ownership;
- maximum cumulative error;
- exploit search for repeated rounding cycles.

### MATH-1F — Market microstructure simulation

Only after accounting safety is stable, simulate:

- complete-set parity arbitrage;
- PRISM create/redeem arbitrage;
- Kuru-like spreads/depth;
- stale orders around resolution;
- market-maker inventory;
- resolution jumps;
- quote-token volatility;
- arbitrage convergence time.

---

## 20. MATH-1 gate

Possible verdicts:

```text
PASS
CONDITIONAL_PASS
FAIL
```

`PASS` requires the formal accounting/safety properties and deterministic implementation boundary to be accepted.

`CONDITIONAL_PASS` may be used where protocol accounting is safe but market behavior remains materially assumption-dependent.

`FAIL` is required if a valid sequence can create unbacked liabilities, over-redemption, false replication acceptance, illegal lifecycle transitions, or settlement insolvency.

The final MATH-1 verdict authorizes `CONTRACT-ARCH-1`; it does not automatically authorize production deployment.

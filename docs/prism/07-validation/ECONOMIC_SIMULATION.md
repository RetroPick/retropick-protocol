# Economic Simulation Plan

**Status:** MARKET-THESIS VALIDATION LAYER  
**Important:** this document does not define protocol solvency.

The accounting kernel is proven/tested separately. Economic simulation asks whether the tradable asset behaves plausibly under realistic liquidity, latency, inventory and resolution conditions.

---

## 1. Claims simulation may support

Simulation may provide evidence for:
- PRISM price tracking executable component value;
- mint/redeem arbitrage reducing persistent mispricing;
- liquidity required for target spread/slippage;
- market-maker inventory requirements;
- resolution-jump losses;
- stale-order risk;
- post-resolution pair behavior against volatile quote assets;
- impact of gas/fees/latency on arbitrage bands.

Simulation may not prove:
- future user demand;
- guaranteed liquidity;
- guaranteed MM profitability;
- guaranteed price convergence;
- legal viability;
- bridge/oracle reliability.

---

## 2. Deterministic pricing primitives

These are exact reference calculations, not stochastic simulation:

### Complete set

Split-and-sell profit:

```math
Pi_split = Bid_Y + Bid_N - 1 - C_split
```

Buy-and-merge profit:

```math
Pi_merge = 1 - Ask_Y - Ask_N - C_merge
```

### PRISM creation

```math
C_create = sum_i x_i Ask_i + F_create
```

### PRISM in-kind redemption

```math
V_redeem = sum_i x_i Bid_i - F_redeem
```

### Practical reference band

```math
V_redeem-rho_r <= P_PRISM <= C_create+rho_c
```

This is a no-arbitrage reference relation under behavioral/execution assumptions, not an enforced bound.

### Partial resolution

```math
NAV_t = sum_(i in R) x_i r_i + sum_(j in U) x_j P_j(t)
```

### Post-resolution pair

For USD-like payout `R` and quote token USD price `P_Q`:

```math
P_(PRISM/Q) ~= R / P_Q
```

before costs/risk.

---

## 3. Underlying probability/price process

Prediction assets require bounded event probabilities and jump behavior.

Do not rely only on geometric Brownian motion.

Candidate synthetic models:

### Logistic-normal diffusion

Model latent log-odds `z_t`, then:

```math
p_t = 1/(1+e^{-z_t})
```

with stochastic evolution in `z_t`.

### Event jump process

At information arrival:

```math
z_(t+) = z_(t-) + J
```

so probability can reprice discontinuously.

### Bayesian scenario process

Generate discrete signals with likelihood ratios and update posterior odds.

All synthetic processes must be labelled `SIMULATED`.

---

## 4. Multi-event correlation

For two binary events `A` and `B`, model joint state probabilities:

```math
P00, P01, P10, P11 >= 0
```

and:

```math
P00+P01+P10+P11=1
```

Do not assume independence unless the scenario explicitly says so.

For linear replicated PRISM baskets, terminal payoff is still `Gx`; correlation affects expected valuation and trading dynamics, not the exact backing theorem.

For nonlinear desired payoffs such as `A AND B`, marginal claims may be insufficient for replication. That is an admission/payoff-basis issue, not something simulation can repair.

---

## 5. Agent classes

Minimum agent-based experiment:

### Noise traders
Trade based on random/behavioral signals.

### Informed traders
Observe synthetic event signals earlier or with less noise.

### PRISM arbitrageurs
Compare:
- PRISM orderbook price;
- executable component creation cost;
- executable in-kind redemption value.

Act only when expected profit exceeds fees/risk thresholds.

### Market maker
Quotes around a reference value while managing inventory and maturity risk.

### Optional liquidity shock trader
Consumes depth to test recovery and slippage.

---

## 6. Resolution regime

Model at least three phases:

```text
ACTIVE
-> event occurred / canonical resolution pending
-> RESOLVED / settlement funding pending
-> REDEEMABLE
```

Important variables:
- event time;
- canonical-resolution delay;
- settlement-funding delay;
- quote-token price movement during delay.

Test stale maker orders around discrete outcome information.

---

## 7. Market-maker model

Start simple.

Reference value can use midpoint/component NAV, but quotes must include:
- spread;
- inventory skew;
- volatility/jump allowance;
- time-to-resolution allowance;
- execution cost.

PnL decomposition:

```math
PnL = spread revenue
    + arbitrage revenue
    - hedge/execution cost
    - inventory loss
    - resolution jump loss
    - gas/fees
```

Only add Avellaneda-Stoikov-style machinery if it materially improves the experiment.

---

## 8. Experiments

### E1 Complete-set parity recovery
Shock YES/NO quotes and measure whether modeled arbitrage closes profitable executable gaps.

### E2 PRISM premium
Start `P_PRISM > C_create`; measure create-and-sell response.

### E3 PRISM discount
Start `P_PRISM < V_redeem`; measure buy-redeem-sell response.

### E4 Low liquidity
Reduce depth and show wider persistent deviations/slippage.

### E5 Resolution jump
Move terminal expectation sharply and measure stale-order/MM losses.

### E6 Partial resolution
Resolve one component and verify reference NAV simplifies correctly.

### E7 Post-resolution quote volatility
Fix PRISM payout and vary MON/USD; measure PRISM/MON relative movement.

### E8 Funding delay
Resolve payout but delay settlement funding; model discount/residual risk before `REDEEMABLE`.

---

## 9. Metrics

Track:
- absolute premium/discount to executable reference;
- time to return inside 1%, 2%, 5%, 10% bands;
- spread;
- depth;
- user slippage;
- arbitrage PnL;
- market-maker PnL;
- inventory variance;
- loss around resolution;
- capital required to maintain target depth;
- volume;
- unresolved-to-resolved price jump.

Do not optimize only average results. Report tails/worst cases.

---

## 10. Classification of results

Each output must be labelled:

```text
SIMULATED
```

and conclusion status one of:

```text
SUPPORTED_BY_SIMULATION
NOT_SUPPORTED_BY_SIMULATION
INCONCLUSIVE
COUNTEREXAMPLE_FOUND
```

Only real deployment/user/orderbook evidence may later use:

```text
SUPPORTED_BY_LIVE_EVIDENCE
```

---

## 11. Separation from MATH-1 safety

Simulation failure may invalidate the **market thesis** without invalidating exact protocol solvency.

Example:
- exact PRISM remains fully backed;
- but arbitrage is too slow/expensive to maintain useful market quality.

Then accounting can remain `PASS` while economic product viability becomes `CONDITIONAL` or `FAIL` for the targeted market design.

Conversely, excellent simulated liquidity can never justify an accounting invariant failure.

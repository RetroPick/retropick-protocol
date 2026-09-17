# Economics

**Status:** CANONICAL ECONOMIC INTERPRETATION  
**Formal source:** `../protocol/MATH_MODEL.md`

This document explains the economic meaning of the protocol without promoting market assumptions into protocol invariants.

---

## 1. Native binary market economics

For one unit of collateral `C` in the canonical binary complete-set model:

```math
1C \rightarrow 1YES + 1NO
```

Before final resolution:

```math
1YES + 1NO \rightarrow 1C
```

At terminal resolution exactly one winning outcome redeems to the collateral unit in the ordinary valid binary case.

The core conservation identity is:

```math
YES_{supply}=NO_{supply}=CollateralLocked
```

for the simple fully collateralized model.

Therefore native economic open interest is not `YES_supply + NO_supply`. That sum double-counts the same complete-set collateral.

Canonical OI:

```math
OI = CollateralLocked = YES_{supply}=NO_{supply}
```

when conservation holds exactly.

---

## 2. Executable complete-set parity

The conceptual identity `YES + NO = 1` is not itself an executable arbitrage condition.

Split-and-sell is economically attractive when:

```math
Bid_{YES}+Bid_{NO}>1+Costs_{split/sell}
```

Buy-and-merge is economically attractive when:

```math
Ask_{YES}+Ask_{NO}<1-Costs_{buy/merge}
```

Using mid prices or one-sided prices as if they were executable creates false arbitrage signals.

---

## 3. PRISM economic object

A Phase-1 PRISM token is a fully backed structured claim with immutable component vector:

```math
x=(x_1,...,x_n),\quad x_i\ge0
```

and payoff:

```math
h=Gx
```

One token economically represents the locked portfolio:

```math
x_1A_1+...+x_nA_n
```

This is closer to an event-linked basket/structured note than to an unconstrained synthetic derivative.

The product cannot claim arbitrary payoff expressiveness. If a desired payoff is outside:

```math
\mathcal C=\{Gx\mid x\ge0\}
```

Phase 1 rejects it.

---

## 4. Supply elasticity

PRISM supply is endogenous:

```math
S_{t+1}=S_t+Mint_t-Redeem_t
```

Minting requires new backing. Redemption burns supply and releases backing or final settlement value.

The protocol therefore does not rely on a fixed token supply to create scarcity. Economic anchoring comes from convertibility and backing.

---

## 5. Creation and redemption values

For one PRISM unit with component weights `x_i`, executable creation cost is approximately:

```math
CreateCost=\sum_i x_i Ask_i + Fees_{create}
```

Executable in-kind redemption value is approximately:

```math
RedeemValue=\sum_i x_i Bid_i - Fees_{redeem}
```

Under idealized instantaneous execution, price outside:

```math
RedeemValue \le P_{PRISM}\le CreateCost
```

creates an arbitrage incentive.

This is not a protocol-enforced price range. Real prices may temporarily or persistently deviate because of depth, latency, inventory, gas, capital constraints, resolution risk, mint cutoffs, or absent arbitrageurs.

---

## 6. Partial resolution

When some components resolve while others remain uncertain:

```math
NAV_t=\sum_{i\in R}x_i r_i + \sum_{j\in U}x_j P_j(t)
```

The resolved component contributes fixed value while unresolved components retain event uncertainty.

This is a valuation identity under supplied marks, not a guarantee of exchange price.

---

## 7. Final resolution

Once all payoff-relevant states are known:

```math
R=h(\omega^*)
```

The PRISM token changes economic character from uncertain event exposure into a fixed-value redeemable claim.

It can remain transferable and trade against another ERC-20. Against quote token `Q` with USD-like price `P_Q`:

```math
P_{PRISM/Q}\approx\frac{R}{P_Q}
```

before fees, liquidity effects, settlement delay and residual risk.

A resolved PRISM/USDC pair should converge toward `R` under reliable redemption, while a resolved PRISM/MON pair can continue moving because MON itself moves.

---

## 8. Economic claims that are NOT protocol proofs

The following require simulation or live evidence:

- secondary price stays near NAV;
- arbitrage closes deviations quickly;
- Kuru depth is sufficient;
- market makers remain profitable;
- resolution jumps are manageable;
- users prefer PRISM to trading legs independently;
- tokenization creates demand.

These must be classified as empirical market properties, never solvency invariants.

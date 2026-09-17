# Token Model

**Status:** CANONICAL TOKEN SEMANTICS FOR PHASE 1

RetroPick exposes two distinct token classes.

---

## 1. Native outcome ERC-20s

A binary market issues:

```text
YES ERC20
NO  ERC20
```

through complete-set collateralization.

For quantity `Q`:

```math
Q\ collateral \rightarrow Q\ YES + Q\ NO
```

and, before resolution where merge is allowed:

```math
Q\ YES + Q\ NO \rightarrow Q\ collateral
```

Properties:
- event-linked;
- bounded terminal payoff;
- transferable;
- secondary-market tradable;
- redeemable;
- complete-set collateralized;
- maturity/resolution dependent.

---

## 2. PRISM Series ERC-20

Each PRISM series is a fungible ERC-20 representing an immutable exact-backed basket of supported outcome assets.

Canonical component vector:

```math
x=(x_1,...,x_n),\quad x_i\ge0
```

Terminal payoff:

```math
h=Gx
```

Runtime backing:

```math
B_i\ge Sx_i
```

where `S` is outstanding PRISM supply.

---

## 3. Series immutables

After activation, a series must bind:
- component identities;
- units-per-share weights;
- replication hash;
- payoff/definition hash where used;
- settlement asset;
- maturity/resolution references;
- precision domain;
- lifecycle rules.

The economic definition cannot mutate while liabilities exist.

---

## 4. Mint/burn supply model

PRISM supply is elastic but always liability-coupled:

```math
S_{t+1}=S_t+Mint_t-Redeem_t
```

Mint is permitted only after required backing is allocated.

Pre-resolution in-kind redemption burns PRISM and releases proportional component backing.

Final redemption burns PRISM and pays deterministic settlement value after the settlement funding gate is satisfied.

---

## 5. Retail trading versus issuance

These are different actions.

### BUY/SELL

```text
wallet
-> Kuru PRISM/quote market
-> ordinary ERC20 transfer after execution
```

No backing changes merely because ownership changes.

### CREATE/REDEEM

```text
component basket
-> PRISM vault/controller
-> mint PRISM
```

or inverse redemption.

Primary creation is mainly an issuer/AP/market-maker/arbitrage path.

---

## 6. Lifecycle-dependent economic character

Before final resolution:

```text
PRISM = uncertain event-linked structured asset
```

After final resolution:

```text
PRISM = fixed-value redeemable claim
```

The token can remain transferable after resolution, but product UX should prioritize redemption over treating it as a new unresolved market.

---

## 7. Quote pairs

Preferred consumer pair:

```text
PRISM / USDC-like quote
```

because the price can be interpreted directly against a settlement-like unit.

Other pairs such as:

```text
PRISM / MON
```

remain valid ERC20/ERC20 markets. After PRISM resolves, pair movement can continue due to the quote token's price.

---

## 8. Non-goals

Phase 1 does not define:
- governance token economics;
- protocol token emissions;
- leveraged/unbounded PRISM liabilities;
- approximate replication;
- arbitrary nonlinear derivative issuance;
- cross-chain wrapped external outcomes.

Those require separate specifications and cannot be inferred from the Series ERC-20 design.

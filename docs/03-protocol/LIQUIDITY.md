# Liquidity

**Status:** CANONICAL LIQUIDITY POLICY  
**Economic source:** `ECONOMICS.md` and `../protocol/MATH_MODEL.md`

Backing collateral is not liquidity capital. Exchange deployment does not imply usable market depth.

---

## 1. Accounting separation

These balances must remain conceptually and operationally distinct:

```text
backing collateral
!=
settlement collateral
!=
LP inventory
!=
market-maker inventory
!=
protocol fees
!=
creator revenue
```

No liquidity strategy may borrow from backing that is already reserved for outstanding liabilities.

---

## 2. Native YES/NO liquidity

Each native market can expose:

```text
YES / quote
NO  / quote
```

on Kuru.

The initial liquidity plan may use:
- creator/bootstrap quote inventory;
- fully collateralized YES/NO inventory created via split;
- CLOB maker quotes;
- Kuru-supported liquidity mechanisms where verified.

But LP/maker capital must be separately funded from the collateral vault.

---

## 3. Complete-set arbitrage

Executable split-and-sell condition:

```math
Bid_{YES}+Bid_{NO}>1+Costs
```

Executable buy-and-merge condition:

```math
Ask_{YES}+Ask_{NO}<1-Costs
```

These mechanisms create an economic incentive toward complete-set parity but do not guarantee instantaneous convergence.

---

## 4. PRISM liquidity

A PRISM series should normally expose a quote market such as:

```text
pFEDBTC / USDC
```

Normal retail users buy/sell existing PRISM through the exchange.

Primary create/redeem flows are issuer/AP/market-maker/arbitrage mechanisms that support secondary liquidity and NAV anchoring.

The protocol should not force every retail buyer through multi-leg component acquisition.

---

## 5. Create/redeem reference band

For exact basket weights `x`:

```math
CreateCost=\sum_i x_i Ask_i+Fees_{create}
```

```math
RedeemValue=\sum_i x_i Bid_i-Fees_{redeem}
```

Persistent prices above create cost or below redeem value may create arbitrage opportunity.

A practical band must also account for:

```text
execution latency
inventory risk
orderbook depth
market impact
gas
fees
mint cutoff
resolution risk
capital cost
```

Therefore the idealized no-arbitrage interval is a market model, not an onchain invariant.

---

## 6. Resolution jump risk

Near event resolution, outcome-token prices may reprice discontinuously.

For CLOB market makers this creates stale-order pickoff risk.

Operational controls should include:
- cancel/requote around resolution windows;
- wider spreads when uncertainty is binary and close to expiry;
- inventory caps;
- explicit resolution-status feeds;
- no assumption that passive liquidity is protected from information jumps.

For resolved claims, market making becomes relative-value quoting around known redemption value rather than prediction probability.

---

## 7. Success metrics

Liquidity validation should measure:
- best bid/ask spread;
- executable depth at defined notional;
- slippage;
- premium/discount to executable NAV;
- convergence time after dislocation;
- maker inventory/PnL;
- resolution-jump losses;
- amount of separate capital required to maintain target depth.

These are empirical metrics.

---

## 8. Failure classification

If accounting remains solvent but no realistic amount of market-maker/arbitrage capital can keep markets usable, classify the market thesis as `CONDITIONAL` or `NOT_YET_VALIDATED`.

Do not redefine backing or relax solvency constraints merely to manufacture liquidity.

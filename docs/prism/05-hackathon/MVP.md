# Metropolis MVP

**Status:** CANONICAL HACKATHON SCOPE  
**Target:** prove the asset class and protocol mechanics with the smallest coherent end-to-end product.

---

## 1. MVP thesis

RetroPick proves that generic ERC-20 spot markets can become prediction-market infrastructure when RetroPick supplies:
- event semantics;
- complete-set collateralization;
- outcome issuance;
- resolution;
- redemption;
- exact-backed structured composition through PRISM.

Kuru supplies secondary-market microstructure.

---

## 2. Required native market

Ship at least one binary market with:

```text
1 collateral
-> 1 YES + 1 NO
```

and inverse merge.

Required proof:
- collateral balance;
- YES supply;
- NO supply;
- split tx;
- merge tx;
- deterministic resolution;
- winning redemption.

---

## 3. Required Kuru markets

At minimum:
- `YES / quote`;
- `NO / quote`;
- one `PRISM / quote` market.

Required evidence:
- Kuru market IDs/addresses;
- seeded/quoted depth;
- at least one executed trade per demonstrated market class;
- orderbook snapshot;
- executable spread/depth observation.

Deployment alone is not considered liquidity.

---

## 4. Required PRISM series

Use one exact, explainable basket-mode series.

Canonical example:

```math
pFEDBTC = 0.6 FED_YES + 0.4 BTC_NO
```

Payoff table:

| Fed | BTC condition | final payout |
|---|---|---:|
| No | No | 0.40 |
| No | Yes | 0.00 |
| Yes | No | 1.00 |
| Yes | Yes | 0.60 |

For `1000` PRISM:

```text
600 FED_YES
400 BTC_NO
```

must be locked before mint.

Do not use the historical incorrect `Fed=YES, BTC=NO -> 0.60` example.

---

## 5. Required PRISM actions

### Primary CREATE

```text
provide exact basket
-> lock backing
-> verify B_i >= (S+Q)*x_i
-> mint Q PRISM
```

### Retail TRADE

```text
user -> Kuru PRISM/quote -> existing PRISM changes owner
```

### Pre-resolution redeem

```text
burn Q PRISM
-> receive Q*x_i components
```

### Final settlement

```text
resolve all components
-> compute R=h(omega*)
-> fund settlement
-> require SettlementBalance >= Supply*R
-> REDEEMABLE
-> burn PRISM for Q*R
```

---

## 6. Required math/evidence story

Judges should be able to inspect:
- `h=Gx`;
- feasible-payoff limitation;
- component backing invariant `B_i >= S*x_i`;
- exact mint/redeem conservation;
- terminal solvency theorem;
- non-replicable AND counterexample;
- corrected complete-set open interest;
- executable bid/ask parity conditions;
- final settlement funding gate.

The demo must distinguish proven accounting properties from market-behavior hypotheses.

---

## 7. Integration scope

### P0
- Kuru trading;
- Envio index/read model;
- CRE resolution orchestration;
- account/funding path required for usable product.

### P1
- MetaMask Agent automation;
- Nansen intelligence;
- passkey-protected strategy data;
- richer cross-chain funding routes.

P1 integrations are cut before protocol correctness.

---

## 8. Explicit non-goals

MVP does not require:
- Polymarket backing;
- BackingMirror;
- external custody/bridge;
- arbitrary AND/OR structured payoff;
- StatePool/SLE;
- production compliance system;
- many PRISM series;
- guaranteed market-maker profitability.

---

## 9. Golden demo

```text
1. User/account ready.
2. Create/open native prediction market.
3. Split collateral into YES + NO.
4. Show Kuru YES/NO markets and execute trade.
5. Show complete-set accounting/parity.
6. Create exact PRISM series.
7. Primary-create PRISM from exact backing.
8. Trade PRISM on Kuru as ordinary ERC-20.
9. Resolve one component / show remaining structured exposure if demo supports it.
10. Finalize all components.
11. Fund settlement and prove funding gate.
12. Redeem PRISM for deterministic payout.
13. Show Envio/evidence trail.
```

The MVP is successful when this path is real and inspectable, not when the repository contains the largest number of sponsor integrations.

# RetroPick + PRISM Executive Summary

**Status:** CANONICAL HUMAN-FACING OVERVIEW  
**Date:** 2026-09-17  
**Target:** Monad Metropolis 2026  
**Primary track:** Onchain Finance & Trading  
**Current phase:** `P1 SPEC -> P2 MATH-1`  
**Production Solidity:** NOT AUTHORIZED until `MATH-1` and `CONTRACT-ARCH-1` pass

---

## 1. What RetroPick is

RetroPick turns real-world events into portable, fully collateralized onchain financial assets.

The native RetroPick product is a prediction-market launchpad on Monad. A market creator defines an event and immutable resolution rules, locks collateral through a complete-set mechanism, and creates transferable ERC-20 outcome assets such as:

```text
BTC150-YES
BTC150-NO
FEDCUT-YES
FEDCUT-NO
```

Those assets can trade on Kuru like ordinary spot ERC-20 assets while retaining deterministic event-linked redemption semantics.

The product thesis is:

> **Kuru provides exchange microstructure. RetroPick provides prediction-market financial semantics.**

RetroPick owns:
- event definition;
- collateralization;
- issuance;
- payoff semantics;
- resolution rules;
- redemption;
- PRISM structured composition.

Kuru owns:
- spot order books;
- matching;
- limit/market execution;
- exchange liquidity infrastructure.

The purpose is not merely to put a prediction-market UI on top of an exchange. The objective is to create a new class of event-linked ERC-20 assets that can be traded, indexed, composed, held in wallets, and integrated into broader onchain infrastructure.

---

## 2. Native RetroPick market model

For a canonical binary market, one collateral unit creates one complete set:

```math
1\ collateral \rightarrow 1\ YES + 1\ NO
```

Before final resolution, the inverse operation is possible when both complementary claims are available:

```math
1\ YES + 1\ NO \rightarrow 1\ collateral
```

At valid terminal resolution:

```text
winning outcome -> 1 collateral unit
losing outcome  -> 0
```

The fundamental accounting identity for the simple fully collateralized model is:

```math
YES_{supply}=NO_{supply}=CollateralLocked
```

Therefore economic open interest is not `YES_supply + NO_supply`, which would double-count the same complete-set collateral.

Executable complete-set arbitrage depends on actual bid/ask prices:

```math
Bid_{YES}+Bid_{NO}>1+costs
```

creates a split-and-sell incentive, while:

```math
Ask_{YES}+Ask_{NO}<1-costs
```

creates a buy-and-merge incentive.

These relationships create an economic anchor without assuming that arbitrage is instantaneous or that liquidity appears automatically.

---

## 3. What PRISM is

PRISM is the structured-asset layer above RetroPick outcome assets.

Instead of trading only one binary event at a time, PRISM creates an ERC-20 claim backed by an immutable basket of supported outcome assets.

Example:

```math
pFEDBTC = 0.6\ FED\_YES + 0.4\ BTC\_NO
```

One unit of `pFEDBTC` is backed by:

```text
0.6 FED_YES
0.4 BTC_NO
```

The Phase-1 design is intentionally narrower than arbitrary programmable derivatives. It supports exact, non-negative, fully backed replication only.

That restriction is a safety feature. PRISM Phase 1 issues a structured asset only when the required terminal payoff can be represented exactly by the admitted component basis.

---

## 4. Canonical PRISM mathematics

Let terminal worlds be:

```math
\Omega=\{\omega_1,\ldots,\omega_m\}
```

Each supported component asset `A_i` has non-negative terminal payoff:

```math
g_i(\omega)\ge0
```

Collect component payoffs into matrix `G` and define replication vector:

```math
x=(x_1,\ldots,x_n),\qquad x_i\ge0
```

Then one PRISM token has terminal payoff:

```math
\boxed{h=Gx}
```

The feasible long-only payoff set is:

```math
\boxed{\mathcal C=\{Gx\mid x\ge0\}}
```

A requested payoff outside this cone is not Phase-1 PRISM.

### Basket mode

The creator supplies the basket directly:

```text
60% FED_YES
40% BTC_NO
```

The system computes:

```math
h=Gx
```

This is the default hackathon path.

### Payoff mode

An advanced creator supplies desired payoff vector `h*` and the admission engine solves:

```math
Gx=h^*,\qquad x\ge0
```

If no exact solution exists:

```text
PRODUCT_NOT_REPLICABLE
```

Approximate replication is outside Phase 1.

---

## 5. Runtime solvency model

Admission math and runtime solvency are intentionally separated.

The replication relation is proved once at series admission. Solidity does not need to enumerate every possible terminal world on every mint.

Let:
- `S` = outstanding PRISM supply;
- `B_i` = backing units reserved for component `i`;
- `x_i` = units of component `i` required per PRISM token.

The runtime invariant is:

```math
\boxed{B_i\ge Sx_i\qquad\forall i}
```

For mint quantity `Q`, backing must be deposited or allocated first:

```math
Qx_i
```

and only then may supply increase.

For a valid exact-backed mint:

```math
S'=S+Q
```

```math
B_i'=B_i+Qx_i
```

The backing invariant is preserved.

Pre-resolution in-kind redemption performs the inverse operation:

```math
S'=S-Q
```

```math
B_i'=B_i-Qx_i
```

The liability is reduced before proportional backing is released.

The core terminal-solvency theorem is:

```math
h=Gx
```

plus:

```math
B_i\ge Sx_i
```

plus non-negative component payoffs implies:

```math
\boxed{V_B(\omega)\ge S\,h(\omega)\qquad\forall\omega\in\Omega}
```

where `V_B(omega)` is terminal value of the locked backing basket.

This is the mathematical foundation of the Phase-1 PRISM thesis.

---

## 6. Canonical pFEDBTC example

For:

```math
pFEDBTC=0.6\ FED\_YES+0.4\ BTC\_NO
```

the correct terminal payoff table is:

| Fed state | BTC condition | FED_YES | BTC_NO | PRISM payout |
|---|---|---:|---:|---:|
| No | No | 0 | 1 | 0.40 |
| No | Yes | 0 | 0 | 0.00 |
| Yes | No | 1 | 1 | 1.00 |
| Yes | Yes | 1 | 0 | 0.60 |

For 1,000 PRISM supply, exact backing is:

```text
600 FED_YES
400 BTC_NO
```

This example is canonical. Earlier research that described the `Fed=YES, BTC=NO` world as paying `0.60` was mathematically incorrect and has been superseded.

---

## 7. Partial resolution

A PRISM series does not need to stop trading merely because one component resolves before another.

For:

```math
P=0.6A+0.4B
```

if `A` resolves to `1` while `B` remains uncertain:

```math
P=0.6+0.4B
```

If `A` resolves to `0`:

```math
P=0.4B
```

More generally, if `R` is the set of resolved components and `U` the unresolved set:

```math
NAV_t=\sum_{i\in R}x_i r_i+\sum_{j\in U}x_j P_j(t)
```

This is a valuation identity given component marks. It does not guarantee that a live exchange price equals NAV.

A resolved component may be transformed into settlement collateral only when the transformation preserves the remaining payoff obligation.

---

## 8. Final resolution and redemption

The canonical lifecycle is:

```text
DRAFT
  -> ACTIVE
  -> MINT_PAUSED
  -> RESOLUTION_PENDING
  -> RESOLVED
  -> REDEEMABLE
  -> ARCHIVED
```

The distinction between `RESOLVED` and `REDEEMABLE` is critical.

`RESOLVED` means the final payout is known:

```math
R=h(\omega^*)
```

`REDEEMABLE` additionally requires actual settlement funding:

```math
\boxed{SettlementBalance\ge OutstandingSupply\times R}
```

Only then may final redemption proceed:

```text
burn Q PRISM
-> receive Q * R settlement asset
```

This prevents a protocol from knowing what it owes while lacking the assets required to pay holders.

---

## 9. Why these assets remain interesting after resolution

Before resolution, an outcome token or PRISM series trades as uncertain event exposure.

After final resolution, event uncertainty disappears and the token becomes economically similar to a fixed-value redeemable claim.

For a resolved PRISM claim worth `R` USD-like settlement units and a quote token worth `P_Q,USD`, an idealized relative value is:

```math
P_{PRISM/Q}\approx\frac{R}{P_{Q,USD}}
```

Therefore a resolved `PRISM/MON` pair can continue moving even though the prediction itself is finished. The remaining movement can come from MON rather than from event uncertainty.

A losing claim with final payout `0` may remain technically transferable but has zero protocol redemption value.

This changing financial character is one of the unusual properties of the asset class:

```text
uncertain event exposure
-> short-dated event claim
-> fixed redemption claim
-> redeemed/burned
```

---

## 10. Retail trading versus primary creation

Normal users should not be forced to reconstruct a PRISM basket manually.

### Retail BUY

```text
User
 -> Kuru PRISM/quote market
 -> buys existing PRISM
```

### Primary CREATE

```text
Issuer / AP / market maker / arbitrageur
 -> obtains all required components
 -> locks exact backing
 -> mints PRISM
 -> holds or sells it
```

This is analogous to the distinction between secondary ETF trading and primary creation/redemption.

Primary creation and in-kind redemption provide the economic mechanism that can connect secondary-market value with underlying component value.

---

## 11. Market-price thesis

Let executable creation cost be:

```math
C=\sum_i x_i Ask_i+F_c
```

and executable in-kind redemption value be:

```math
R_d=\sum_i x_i Bid_i-F_r
```

Persistent prices materially above creation cost create a creation-and-sell incentive.

Persistent prices materially below redemption value create a buy-and-redeem incentive.

An idealized no-arbitrage relation is therefore:

```math
R_d\lesssim P_{market}\lesssim C
```

but realistic risk broadens that region:

```math
R_d-\rho_r\lesssim P_{market}\lesssim C+\rho_c
```

where the risk terms can include:
- inventory risk;
- execution latency;
- orderbook depth;
- gas;
- capital costs;
- resolution risk;
- operational constraints.

This is **not** a protocol theorem. Price convergence, market-maker profitability, liquidity and adoption are empirical market properties that must be simulated and later measured with live evidence.

---

## 12. Hackathon architecture

The Metropolis critical path is intentionally same-chain and narrow.

```text
RETROPICK NATIVE MARKET

Event + ResolutionSpec
  -> PredictionMarketFactory
  -> PredictionMarket
  -> CompleteSetVault
  -> YES ERC20 / NO ERC20
  -> Kuru

PRISM

Supported YES/NO ERC20s
  -> series admission
  -> PrismSeriesFactory
  -> PrismBackingVault
  -> PrismMintController
  -> PrismSeriesERC20
  -> Kuru

RESOLUTION

ResolutionSpec
  -> accepted resolver / CRE orchestration
  -> canonical outcome
  -> native outcome settlement
  -> PRISM partial/final settlement
```

For Phase 1, the PRISM vault/accounting on Monad is authoritative for PRISM backing.

There is no need to send same-chain vault state through an offchain observer and then mirror it back to Monad.

---

## 13. Sponsor/integration roles

Integrations are bounded by protocol responsibility.

### Kuru
Secondary execution venue for YES, NO and PRISM spot markets.

### Envio
Indexed read model for contract and trading state. It is not the financial source of truth.

### Chainlink CRE
Resolution workflow orchestration where applicable. It is not an authority for same-chain PRISM vault balances.

### Mera
Account/passkey UX for normal users where technically supported.

### Aurora Intents
Cross-chain funding UX, not protocol backing logic.

### MetaMask Agent Wallet
Optional automation surface after core trading and safety gates are complete.

### Nansen
Optional intelligence/discovery layer, not a protocol oracle.

### Alchemy
RPC/WebSocket infrastructure, not financial truth.

Sponsor integrations must strengthen the product without redefining protocol invariants.

---

## 14. Explicit Phase-1 exclusions

The Metropolis kernel deliberately excludes:

- Polymarket/Polygon custody as a dependency;
- production external-market wrappers;
- custom cross-chain bridge design;
- same-chain `BackingMirror`;
- Merkle backing roots for Monad-native balances;
- arbitrary nonlinear payoff bytecode;
- generic shared-liquidity StatePool/SLE;
- approximate replication;
- leveraged or negative-liability PRISM instruments;
- state-space enumeration inside every Solidity mint;
- claims that market demand or liquidity are mathematically proven.

These may become later research phases after the native exact-backed system is proven and deployed.

---

## 15. Development and proof workflow

The project is intentionally math-first.

```text
BASELINE-1
  -> SPEC-1
  -> MATH-1
  -> CONTRACT-ARCH-1
  -> CONTRACT-1
  -> INTEGRATION-1 / PRODUCT-1
  -> E2E-1
  -> SUBMISSION-1
```

The current work is `P1 SPEC -> P2 MATH-1`.

MATH-1 includes:

```text
MATH-1A exact arithmetic reference model
MATH-1B bounded/exhaustive verification
MATH-1C adversarial/property testing
MATH-1D fixed-point and rounding model
MATH-1E theorem/formal assistance where useful
MATH-1F market-model classification/simulation
```

Production Solidity is blocked until the accounting model receives an explicit MATH-1 verdict and contract responsibilities are then derived through `CONTRACT-ARCH-1`.

---

## 16. Scientific evidence standard

RetroPick distinguishes protocol proof from market evidence.

Substantive claims must be classified as one of:

```text
PROVEN_UNDER_ASSUMPTIONS
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
SUPPORTED_BY_SIMULATION
SUPPORTED_BY_LIVE_EVIDENCE
NOT_YET_VALIDATED
COUNTEREXAMPLE_FOUND
```

Examples:

### Appropriate for mathematical proof / exhaustive verification
- valid mint preserves backing;
- valid in-kind redemption preserves backing;
- exact replication plus component backing implies terminal solvency;
- illegal lifecycle transitions are rejected;
- underfunded settlement cannot become redeemable;
- known non-replicable payoffs are rejected.

### Not mathematically provable from protocol code alone
- Kuru will have sufficient liquidity;
- arbitrage will close every price gap rapidly;
- market makers will be profitable;
- users will adopt the asset;
- exchange integrations will generate demand.

The project must attempt to falsify the mechanism, not merely demonstrate happy-path examples.

---

## 17. Current executable model

The canonical Python model lives under:

```text
research/prism-model/
```

It separates exact accounting from market-behavior modeling.

Current modules include:

```text
model.py
replication.py
settlement.py
lifecycle.py
market_math.py
bounded_verification.py
fixed_point.py
scenarios.py
```

The exact accounting layer uses Python `Fraction` arithmetic to avoid hiding economic bugs behind floating-point rounding.

The fixed-point module currently evaluates a conservative Solidity candidate policy in which backing requirements round up and releasable amounts round down. That precision policy remains subject to MATH-1D acceptance before Solidity is authorized.

---

## 18. Current decision state

The core Phase-1 architecture is now locked around these decisions:

```text
Native RetroPick -> ERC20 YES/NO -> Kuru
Native outcome ERC20s -> exact-backed PRISM -> PRISM ERC20 -> Kuru
```

Admission truth:

```math
h=Gx
```

Runtime truth:

```math
B_i\ge Sx_i
```

Final funding truth:

```math
SettlementBalance\ge Supply\times FinalPayout
```

The same token type may back multiple series, but the same reserved balance units may never be double-pledged.

`RESOLVED` does not mean `REDEEMABLE`.

Retail `BUY` does not mean primary `CREATE`.

Market simulation does not mean mathematical proof.

An attestation does not equal collateral custody.

---

## 19. Immediate next work

The next engineering priority is not production Solidity.

The correct order is:

```text
1. finish adversarial/property MATH-1 testing
2. complete fixed-point/rounding bounds
3. run fresh full reference-model validation
4. record MATH-1 verdict
5. derive CONTRACT-ARCH-1 from accepted invariants
6. implement Solidity kernel
7. differential-test Solidity against Python reference fixtures
8. integrate Kuru / Envio / CRE and product UX
9. run golden end-to-end demo
10. capture submission evidence
```

This preserves the central engineering discipline of the project:

> **The contracts must implement a proven mechanism. The implementation must not accidentally become the mechanism definition.**

---

## 20. Canonical reading map

For a fast understanding of the repository:

```text
README.md
  -> docs/prism/00-context/EXECUTIVE_SUMMARY.md
  -> docs/prism/00-context/REPORT_RECONCILIATION.md
  -> docs/prism/protocol/PRISM_PROTOCOL_SPEC.md
  -> docs/prism/protocol/MATH_MODEL.md
  -> docs/prism/protocol/INVARIANTS.md
  -> docs/prism/protocol/STATE_MACHINE.md
  -> docs/prism/05-hackathon/PHASE_GATES.md
  -> docs/prism/06-execution/ROADMAP.md
```

For implementation agents, `AGENTS.md` and `.agent/CURRENT_GOAL.md` remain mandatory control-plane entry points.

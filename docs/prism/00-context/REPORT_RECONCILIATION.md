# Architecture Report Reconciliation

**Status:** CANONICAL reconciliation record  
**Date:** 2026-09-17  
**Applies to:** RetroPick + PRISM Metropolis implementation  
**Supersedes:** contradictory implementation details in the earlier 40-page architecture report

## 1. Purpose

The earlier architecture report is retained as research input, but it is not implementation authority. This document records which ideas were accepted, modified, deferred, or rejected after mathematical and protocol review.

Canonical implementation authority is now:

1. `docs/protocol/PRISM_PROTOCOL_SPEC.md`
2. `docs/protocol/MATH_MODEL.md`
3. `docs/protocol/INVARIANTS.md`
4. `docs/protocol/STATE_MACHINE.md`
5. `docs/protocol/CONTRACT_REQUIREMENTS.md`
6. `docs/05-hackathon/RETROPICK_METROPOLIS_AGENT_DEVELOPMENT_WORKFLOW.md`
7. `docs/06-execution/ROADMAP.md`

If the old report conflicts with any file above, the canonical repository docs win.

---

## 2. Canonical architecture

```text
RETROPICK NATIVE MARKET

Event definition
    |
    v
PredictionMarketFactory
    |
    v
PredictionMarket + ResolutionSpec
    |
    v
CompleteSetVault
   /          \
YES ERC20     NO ERC20
   \          /
      Kuru CLOB

PRISM

Supported outcome ERC20s
    |
    v
Series admission
  - basket mode: x supplied, compute h = Gx
  - payoff mode: h supplied, solve Gx = h, x >= 0
    |
    v
PrismSeriesFactory
    |
    v
PrismBackingVault
    |
    v
PrismMintController
    |
    v
PrismSeriesERC20
    |
    v
Kuru CLOB

RESOLUTION

Immutable ResolutionSpec
    |
    v
CRE / accepted resolver orchestration
    |
    v
ResolutionRegistry
    |
    v
native outcomes settle
    |
    v
PRISM partial/final settlement
```

Phase 1 intentionally contains no cross-chain backing dependency, no BackingMirror, no custom bridge, and no per-state runtime solvency loop.

---

## 3. ACCEPT

The following ideas from the earlier report remain part of the canonical design:

- RetroPick owns event semantics, issuance, collateralization, resolution and redemption.
- Kuru owns spot-orderbook market microstructure and execution.
- Native binary markets issue ERC-20 YES/NO outcome tokens.
- Complete-set issuance is fully collateralized: one unit of collateral creates one YES and one NO claim.
- Complete-set merge is the inverse operation before final resolution when both complementary claims are available.
- PRISM v2 uses ERC-20 series.
- PRISM Phase 1 is exact-backed and long-only.
- Series admission uses the payoff relation `h = Gx`.
- A desired payoff supplied directly is admissible only if an exact non-negative replication `Gx = h`, `x >= 0` exists in the canonical numeric domain.
- Backing must exist before supply increases.
- Pre-resolution PRISM redemption can return the proportional underlying basket in kind.
- Partial resolution may transform a resolved component into settlement cash only when payoff equivalence is preserved.
- Final PRISM payout can be fractional.
- PRISM can trade as a normal ERC-20 on Kuru before resolution and may remain transferable after resolution.
- Envio is the indexed read model.
- CRE is resolution orchestration, not a substitute for onchain backing accounting.
- Mera, Aurora Intents, MetaMask Agent Wallet, Nansen and Alchemy remain bounded integrations rather than reasons to redesign the protocol.

---

## 4. MODIFY

### 4.1 Correct pFEDBTC payoff

For:

```math
pFEDBTC = 0.6 FED_YES + 0.4 BTC_NO
```

the terminal payoff table is:

| Fed state | BTC condition | FED_YES | BTC_NO | payout |
|---|---|---:|---:|---:|
| No | No | 0 | 1 | 0.40 |
| No | Yes | 0 | 0 | 0.00 |
| Yes | No | 1 | 1 | 1.00 |
| Yes | Yes | 1 | 0 | 0.60 |

The earlier example that treated `Fed=YES, BTC=NO` as a `0.60` payout was incorrect. It is `1.00`.

### 4.2 Runtime solvency rule

The generalized statewise condition remains useful as a proof object:

```math
V_B(omega) >= S h(omega)
```

but the Phase-1 runtime contract does not enumerate terminal worlds.

For an admitted exact-backed series, runtime enforces the stronger and cheaper component condition:

```math
B_i >= S x_i  for every component i
```

Admission proves `h = Gx`; runtime enforces backing of `x`.

### 4.3 Retail BUY versus primary CREATE

Normal retail trading:

```text
BUY PRISM -> Kuru PRISM/quote orderbook
```

Primary creation:

```text
CREATE PRISM -> acquire/provide backing -> lock backing -> mint PRISM
```

Primary creation is primarily an authorized-participant / market-maker / arbitrage path, not the default retail buy UX.

### 4.4 Market creation versus series creation

Native market creation and PRISM series creation are separate pipelines.

```text
POST /markets
  -> validate event + ResolutionSpec
  -> deploy native market + YES/NO

POST /series
  -> validate component set + replication
  -> deploy PRISM series
```

The Spanning Engine is never required to create a simple RetroPick binary market.

### 4.5 Lifecycle

Canonical PRISM lifecycle:

```text
DRAFT
 -> ACTIVE
 -> MINT_PAUSED
 -> RESOLUTION_PENDING
 -> RESOLVED
 -> REDEEMABLE
 -> ARCHIVED
```

`RESOLVED` means final payout is known. `REDEEMABLE` means enough settlement collateral is actually funded to pay every remaining holder.

### 4.6 Open interest

For a fully collateralized binary complete-set market before resolution:

```math
OI = YES_supply = NO_supply = collateral_locked
```

assuming the split/merge invariant holds.

Do not define open interest as `YES_supply + NO_supply`; that double-counts the same complete-set collateral.

### 4.7 Complete-set parity

Conceptual parity is `YES + NO ~= 1`, but executable arbitrage uses bid/ask sides:

```math
Bid_Y + Bid_N > 1 + split_costs
```

creates split-and-sell incentive, while:

```math
Ask_Y + Ask_N < 1 - merge_costs
```

creates buy-and-merge incentive.

### 4.8 PRISM NAV band wording

Creation/redemption does not force market price to remain inside the NAV band at every instant.

Correct claim:

> Persistent deviations outside executable create/redeem bounds create an arbitrage incentive when capital, inventory, liquidity, timing and operational constraints permit execution.

This is a market hypothesis, not a formal invariant.

### 4.9 Flash liquidity

Flash-borrowed components are not inherently an exploit. The protocol safety condition is that after every successful transaction all outstanding liabilities remain backed and backing cannot leave while those liabilities remain.

### 4.10 Outages

- Kuru outage can stop secondary trading while direct protocol redemption may remain available.
- Resolver/oracle outage can delay final resolution and therefore block final cash settlement.
- Pre-resolution in-kind redemption may remain available only where lifecycle rules and component state make it safe.

---

## 5. DEFER

The following belong to later phases and must not enter Metropolis Phase 1 unless separately approved:

- external Polymarket/ERC-1155 custody as backing;
- cross-chain wrapped prediction positions;
- custom bridge design;
- BackingMirror / Merkle backing roots;
- external-chain backing attestations;
- arbitrary shared-liquidity StatePool/SLE claims;
- nonlinear payoff synthesis that is not exactly representable by the admitted component basis;
- leveraged or negative-liability PRISM instruments.

A future external-wrapper phase must separately prove custody, replay protection, mint/burn/unlock synchronization and settlement transport.

---

## 6. REJECT FOR PHASE 1

Do not implement:

- BackingMirror in the same-chain Monad-native mint path;
- CRE as an authority for same-chain vault balances;
- terminal-state enumeration inside `mint()`;
- a mandatory per-mint BackingLot architecture when aggregate fungible backing is sufficient;
- one token address being prohibited from backing multiple series;
- a 12-sequential-week interpretation of W0-W12;
- unverified SDK method names or sponsor capabilities as if they were production APIs;
- legal conclusions such as assuming a passkey equals KYC or that a disclaimer resolves jurisdictional obligations.

The same component token type may back many PRISM series. The forbidden condition is double-allocation of the same reserved units, not reuse of the token address.

---

## 7. Phase-1 proof boundary

Phase 1 proves protocol accounting under explicit assumptions. It does not prove user demand or real exchange liquidity.

Formal / exhaustive targets:

- `h = Gx` payoff evaluation;
- exact replication admission/rejection;
- back-first mint safety;
- in-kind redemption conservation;
- terminal solvency;
- lifecycle monotonicity;
- settlement funding safety;
- deterministic precision bounds;
- no double allocation.

Simulation / live-evidence targets:

- PRISM price convergence to executable NAV bounds;
- market-maker profitability;
- Kuru depth and spread;
- arbitrage convergence speed;
- adoption and user demand.

---

## 8. Change-control rule

Future agents may not reintroduce a `DEFER` or `REJECT` item into Phase 1 without:

1. a new ADR;
2. updated mathematical assumptions;
3. updated invariant/test coverage;
4. explicit change to the active goal;
5. evidence that the change improves the hackathon critical path rather than merely increasing scope.

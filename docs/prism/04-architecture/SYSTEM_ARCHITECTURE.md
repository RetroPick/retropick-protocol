# System Architecture

**Status:** CANONICAL TARGET ARCHITECTURE FOR METROPOLIS  
**Current implementation phase:** SPEC + MATH  
**Runtime code:** intentionally gated until `MATH-1`

---

## 1. Architectural principle

RetroPick and PRISM are layered systems, not one undifferentiated contract graph.

```text
Layer 1  RetroPick native prediction issuance
Layer 2  PRISM exact-backed structured assets
Layer 3  Kuru secondary-market execution
Layer 4  Indexing / UX / orchestration integrations
```

Kuru supplies exchange microstructure. RetroPick/PRISM supply the financial semantics.

---

## 2. Native RetroPick market layer

```text
Creator
  |
  v
Market Definition + ResolutionSpec
  |
  v
PredictionMarketFactory
  |
  v
PredictionMarket
  |
  v
CompleteSetVault
 /             \
YES ERC20       NO ERC20
 |               |
 +------ Kuru ---+
```

Responsibilities:
- event definition;
- immutable resolution semantics;
- collateral custody;
- complete-set split;
- complete-set merge;
- outcome-token issuance;
- resolution;
- native redemption.

A native binary market does not use the PRISM spanning engine.

---

## 3. PRISM layer

Supported native outcome ERC-20s become components for structured series.

```text
YES/NO ERC20 source assets
          |
          v
Series Admission
  basket mode: x supplied -> h=Gx
  payoff mode: solve Gx=h, x>=0
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
Kuru PRISM/quote market
```

The Phase-1 runtime invariant is component-wise:

```math
B_i >= Sx_i
```

The generalized terminal solvency condition is proved from exact replication; it is not recalculated by enumerating world states during every mint.

---

## 4. Same-chain authority model

For Metropolis, source outcomes, PRISM backing, and PRISM issuance are Monad-native.

Therefore:

```text
PrismBackingVault state == authoritative backing state
```

Phase 1 has no `BackingMirror` in the mint path.

Do not route:

```text
Monad vault -> offchain observer -> CRE -> Monad mirror -> mint
```

for balances already visible on Monad.

CRE is reserved for resolution orchestration and later external-source workflows.

---

## 5. Retail trading versus primary creation

### Normal retail trade

```text
User
 -> Kuru orderbook
 -> buys/sells existing YES / NO / PRISM
```

No protocol backing changes when an already-issued token changes owner.

### Primary issuance

Native outcome:

```text
collateral -> CompleteSetVault -> YES + NO
```

PRISM:

```text
component basket -> PrismBackingVault -> PRISM mint
```

Primary PRISM creation is primarily an issuer/AP/market-maker/arbitrage path, not a required flow for every retail buyer.

---

## 6. Resolution architecture

```text
ResolutionSpec
    |
external/onchain source observations
    |
Chainlink CRE orchestration where applicable
    |
ResolutionRegistry / PredictionMarket
    |
YES/NO final values
    |
PRISM partial transformation or final payout
```

Resolution authority determines the canonical outcome.

Backing accounting independently determines whether the resulting liabilities are funded.

`RESOLVED` therefore precedes `REDEEMABLE` when settlement conversion/funding is still required.

---

## 7. Final settlement

```text
all payoff-relevant sources final
        |
        v
compute R = h(omega*)
        |
        v
RESOLVED
        |
redeem/transform resolved backing
        |
        v
SettlementVault funded
        |
verify SettlementBalance >= Supply * R
        |
        v
REDEEMABLE
        |
user burns PRISM -> receives deterministic settlement
```

---

## 8. Data and integration plane

```text
Contracts / Kuru
      |
      +--> Envio -> indexed read model -> frontend/backend analytics
      |
      +--> Alchemy RPC/WebSocket transport
      |
      +--> CRE resolution workflows
      |
      +--> Mera account UX
      |
      +--> Aurora Intents funding UX
      |
      +--> Nansen optional intelligence
      |
      +--> MetaMask Agent optional automation
```

Important: none of these offchain/integration systems is allowed to become the source of truth for PRISM same-chain backing.

---

## 9. Repository/runtime map

```text
apps/
  consumer/admin trading surfaces

packages/
  shared types, SDKs, math fixtures, API clients

contracts/
  native market + PRISM contracts after CONTRACT-ARCH-1

research/prism-model/
  canonical executable economic reference model

scripts/
  deployment, fixture, integration and evidence automation

tests/
  cross-layer/e2e tests after runtime implementation begins
```

---

## 10. Phase gates

```text
P1 SPEC + MATH
  -> formal semantics + exact reference model

P2 MATH VERIFICATION
  -> exhaustive/adversarial/fixed-point validation

P3 CONTRACT-ARCH-1
  -> storage, interfaces, authorization, events derived from proven semantics

P4 SOLIDITY KERNEL
  -> native complete-set + exact PRISM backing/mint/redeem

P5 INTEGRATIONS
  -> Kuru, Envio, CRE, account/funding surfaces

P6 FULLSTACK PRODUCT
  -> app/backend/indexed read model

P7 GOLDEN DEMO + EVIDENCE
  -> deployed end-to-end flow and submission artifacts
```

No later phase may weaken an earlier financial invariant merely to satisfy an integration or bounty requirement.

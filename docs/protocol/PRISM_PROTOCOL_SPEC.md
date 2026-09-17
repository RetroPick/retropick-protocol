# PRISM Protocol Specification — Phase 1

**Status:** CANONICAL  
**Scope:** exact-backed, long-only structured outcome assets on Monad  
**Production Solidity:** NOT AUTHORIZED until final `MATH-1` gate  
**Related:** `MATH_MODEL.md`, `INVARIANTS.md`, `STATE_MACHINE.md`, `CONTRACT_REQUIREMENTS.md`, `../00-context/REPORT_RECONCILIATION.md`

---

## 1. Purpose

PRISM creates a transferable structured ERC-20 whose terminal payoff is exactly replicated by a locked basket of supported outcome assets.

Phase 1 intentionally solves a narrower problem than arbitrary programmable derivatives.

A PRISM series is accepted only when its payoff is represented by a non-negative exact replication in the supported component basis. If that proof does not exist, the requested series is rejected.

The Phase-1 safety thesis is:

```text
prove the replication once at series admission
+
lock the replication basket before every mint
+
release backing only against burned liability
+
fund all terminal liabilities before final redemption
```

---

## 2. System boundary

### 2.1 RetroPick native market layer

RetroPick creates primitive outcome assets.

```text
Event definition
    |
    v
PredictionMarketFactory
    |
    v
PredictionMarket + immutable ResolutionSpec
    |
    v
CompleteSetVault
   /          \
YES ERC20     NO ERC20
   \          /
      Kuru spot markets
```

A native binary market is not a PRISM series and does not require replication solving.

### 2.2 PRISM layer

PRISM consumes supported outcome ERC-20s as components.

```text
Supported outcome ERC20s
       |
       v
Series admission
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
Kuru spot market
```

### 2.3 Phase-1 exclusions

The Metropolis Phase-1 mint path contains no:

- external-chain backing dependency;
- Polymarket custody dependency;
- BackingMirror;
- Merkle backing root;
- custom bridge;
- CRE-based attestation of same-chain vault balances;
- terminal-state enumeration inside Solidity mint logic.

CRE may orchestrate resolution, but same-chain collateral accounting remains onchain and authoritative.

---

## 3. Mathematical objects

Terminal worlds:

```math
\Omega = \{\omega_1,\ldots,\omega_m\}
```

Component `i` has non-negative terminal payoff:

```math
g_i : \Omega \rightarrow \mathbb{R}_{\ge 0}
```

Payoff matrix:

```math
G_{\omega i} = g_i(\omega)
```

Replication vector:

```math
x = (x_1,\ldots,x_n), \qquad x_i \ge 0
```

One PRISM token is backed by:

```math
x_1 A_1 + \cdots + x_n A_n
```

and has payoff:

```math
\boxed{h = Gx}
```

state-by-state:

```math
\boxed{h(\omega) = \sum_i x_i g_i(\omega)}
```

Feasible payoff cone:

```math
\boxed{\mathcal{C}=\{Gx \mid x\ge0\}}
```

Phase 1 does not claim every desired payoff belongs to `C`.

---

## 4. Two series-creation modes

### 4.1 Basket mode — hackathon default

The creator supplies the component basket directly.

Example:

```text
60% FED_YES
40% BTC_NO
```

Then `x` is supplied and the compiler computes:

```math
h = Gx
```

No optimization problem is required.

This is the default Metropolis MVP path because it is transparent, easy to explain, and easy to verify.

### 4.2 Payoff mode — advanced admission

The creator supplies a desired payoff vector `h*`.

The offchain admission engine attempts to solve:

```math
Gx = h^*, \qquad x\ge0
```

in the canonical deterministic numeric domain.

If no exact solution exists:

```text
PRODUCT_NOT_REPLICABLE
```

The series is not created.

Approximate replication is out of scope for Phase 1.

---

## 5. Series definition

An activated series commits at minimum to:

- `seriesId`;
- supported component token addresses/identifiers;
- units per share `x_i`;
- `replicationHash`;
- `payoffHash` or deterministic payoff derivation;
- settlement asset;
- maturity and mint cutoff;
- resolution references;
- precision/rounding domain;
- lifecycle rules.

After activation, the component set and replication vector are immutable.

The same component token address may appear in many PRISM series. What is forbidden is double-allocation of the same reserved balance units to more than one outstanding liability.

---

## 6. Backing model

Let:

- `S` = outstanding PRISM supply;
- `B_i` = series-scoped backing balance of component `i`;
- `x_i` = required units of component `i` per PRISM token.

The canonical runtime invariant is:

```math
\boxed{B_i \ge Sx_i \qquad \forall i}
```

This is the Phase-1 contract check.

The generalized terminal-state condition:

```math
V_B(\omega) \ge S h(\omega)
```

is a mathematical consequence of exact non-negative replication plus component backing; it is not re-enumerated on every mint.

### 6.1 Accounting domain

Backing collateral is distinct from:

- Kuru LP inventory;
- market-maker wallet inventory;
- protocol fees;
- settlement collateral already converted from resolved components.

No accounting system may silently count the same units in two domains.

---

## 7. Mint

For mint quantity `Q > 0` while the series is `ACTIVE`:

```math
required_i = Qx_i
```

The protocol must:

1. identify the canonical series and immutable `x`;
2. compute deterministic required backing;
3. transfer or otherwise allocate all required backing into the series vault/accounting domain;
4. verify post-deposit backing:

```math
B_i' \ge (S+Q)x_i \qquad \forall i
```

5. only then increase PRISM supply by `Q`.

For exact backing:

```math
S' = S+Q
```

```math
B_i' = B_i + Qx_i
```

A partial multi-leg exchange fill is not sufficient backing and cannot authorize minting.

---

## 8. Primary creation versus retail trading

These are different user actions.

### Retail BUY

Once a Kuru market exists:

```text
user -> Kuru PRISM/quote orderbook -> receives existing PRISM
```

No backing changes because ownership of existing supply changes only.

### Primary CREATE

```text
creator/AP/market maker
 -> provides/acquires all required components
 -> locks exact backing
 -> mints new PRISM supply
```

This path is the economic creation/redemption mechanism and may be used by market makers or arbitrageurs.

The product UI must not present a complex multi-leg CREATE flow as if it were required for every normal PRISM purchase.

---

## 9. Pre-resolution in-kind redemption

For `0 < Q <= S`, in a lifecycle state where in-kind redemption is permitted:

1. burn/decrease liability by `Q`;
2. release:

```math
Qx_i
```

units of each component.

After redemption:

```math
S' = S-Q
```

```math
B_i' = B_i-Qx_i
```

and therefore:

```math
B_i' \ge S'x_i
```

remains true.

Phase 1 prefers returning components directly rather than forcing an additional exchange sale.

---

## 10. Terminal solvency theorem

Terminal backing value:

```math
V_B(\omega)=\sum_i B_i g_i(\omega)
```

Outstanding liability:

```math
L_P(\omega)=S h(\omega)
```

Given:

```math
h=Gx
```

```math
B_i\ge Sx_i
```

and:

```math
g_i(\omega)\ge0
```

then:

```math
\boxed{V_B(\omega)\ge L_P(\omega)\qquad\forall\omega\in\Omega}
```

This theorem is proved in `MATH_MODEL.md` and implemented in the Python reference model.

---

## 11. Canonical pFEDBTC example

Define:

```math
pFEDBTC = 0.6 FED\_YES + 0.4 BTC\_NO
```

Then:

| Fed | BTC condition | FED_YES | BTC_NO | final payout |
|---|---|---:|---:|---:|
| No | No | 0 | 1 | 0.40 |
| No | Yes | 0 | 0 | 0.00 |
| Yes | No | 1 | 1 | 1.00 |
| Yes | Yes | 1 | 0 | 0.60 |

The canonical example must never state that `Fed=YES, BTC=NO` pays `0.60`; it pays `1.00`.

For 1,000 PRISM supply, exact backing is:

```text
600 FED_YES
400 BTC_NO
```

---

## 12. Partial resolution

A partially resolved PRISM series remains economically live whenever payoff-relevant uncertainty remains.

Let:

- `R` = resolved components;
- `U` = unresolved components;
- `r_i` = known terminal payout of a resolved component;
- `P_j(t)` = market mark of an unresolved component.

A valuation mark is:

```math
\boxed{NAV_t = \sum_{i\in R}x_i r_i + \sum_{j\in U}x_j P_j(t)}
```

This is a valuation identity given supplied component marks, not a protocol guarantee of exchange price.

### 12.1 Safe backing transformation

If a component is canonically resolved and redeemable, the vault may convert that component to settlement collateral only when the transformation preserves the remaining payoff obligation.

Example:

```text
0.6 FED_YES + 0.4 BTC_NO

BTC_NO resolves to 1

-> redeem 0.4 BTC_NO
-> retain 0.4 settlement asset
-> remaining backing:
   0.6 FED_YES + 0.4 cash
```

No PRISM supply changes during a payoff-equivalent backing transformation.

---

## 13. Final resolution and settlement

When all payoff-relevant components are final, define terminal world `omega*` and:

```math
R = h(\omega^*)
```

The series enters `RESOLVED` when `R` is canonically fixed.

`RESOLVED` does not imply users can yet be paid.

The series may enter `REDEEMABLE` only when:

```math
\boxed{SettlementBalance \ge OutstandingSupply \times R}
```

within the canonical integer precision policy.

Final redemption:

```text
burn Q PRISM
-> transfer Q * R settlement asset
```

When outstanding liability and supply are zero, the series can become `ARCHIVED`.

---

## 14. Secondary trading before and after resolution

PRISM remains an ERC-20 claim unless a later accepted policy changes transferability.

### Before final resolution

Price reflects uncertain future payoff, liquidity, fees, risk premia and exchange microstructure.

### After final resolution

The event uncertainty disappears. The token becomes economically similar to a fixed redemption claim.

If final payout is `R` units of USD-like settlement and quote asset `Q` trades at `P_Q,USD`, then an idealized relative value is:

```math
P_{PRISM/Q} \approx \frac{R}{P_{Q,USD}}
```

subject to redemption delay, fees, liquidity and residual protocol risk.

Therefore a resolved PRISM/MON pair may continue moving even though the prediction is finished; that movement can come from MON rather than event uncertainty.

A zero-payout claim may remain technically transferable but has zero protocol redemption value.

---

## 15. NAV and arbitrage thesis

Let executable creation cost be:

```math
C = \sum_i x_i Ask_i + F_c
```

and executable in-kind redemption value be:

```math
R_d = \sum_i x_i Bid_i - F_r
```

Under sufficiently liquid, reliable and fast execution, persistent deviations can create arbitrage incentives:

```math
R_d \lesssim P_{market} \lesssim C
```

More generally, risk terms widen the practical band:

```math
R_d - \rho_r \lesssim P_{market} \lesssim C + \rho_c
```

where `rho` may include inventory, latency, gas, capital, operational and resolution risks.

This is a market-equilibrium hypothesis to test through simulation and live evidence. It is not a formal protocol invariant.

---

## 16. Relationship to complete-set outcome markets

A native binary market has complementary payoff claims:

```math
YES(\omega)+NO(\omega)=1
```

for every valid terminal state.

If one collateral unit creates one YES and one NO, then before resolution:

```math
YES_{supply}=NO_{supply}=CollateralLocked
```

assuming no invalid accounting drift.

Economic open interest is therefore not `YES_supply + NO_supply`; that double-counts the same complete-set collateral.

Executable complete-set arbitrage is described in `MATH_MODEL.md`.

---

## 17. Security boundary

Phase 1 must reject any action that can produce:

- unbacked PRISM supply;
- backing withdrawal while corresponding liability remains;
- double allocation of reserved balance units;
- mutation of activated replication semantics;
- duplicate final resolution;
- `REDEEMABLE` with insufficient settlement funding;
- illegal lifecycle resurrection;
- positive-value rounding extraction beyond the accepted bound.

The provenance of deposited backing capital, including whether it was externally borrowed, is not itself a safety property. The safety property is that backing remains locked and sufficient while liability remains outstanding.

---

## 18. Phase-1 non-goals

Phase 1 does not claim:

- every desired payoff is replicable;
- arbitrary AND/OR payoffs can be synthesized from marginal claims;
- approximate replication is safe;
- bridge attestations equal custody;
- cross-chain wrapped outcomes are production-ready;
- liquidity appears merely because an ERC-20 pair is deployed;
- arbitrage always executes;
- market makers are profitable;
- simulation proves demand;
- a passkey equals legal identity/KYC;
- a disclaimer resolves jurisdiction-specific obligations.

---

## 19. MATH-1 implementation gate

Production Solidity begins only after the reference model establishes or bounds:

- exact payoff evaluation;
- replication admission/rejection;
- component backing preservation;
- redemption conservation;
- terminal solvency;
- lifecycle safety;
- settlement funding safety;
- deterministic fixed-point/rounding bounds;
- no double allocation;
- known counterexamples and unsupported payoff classes.

Market behavior is evaluated separately through simulation/live evidence and cannot upgrade an unsafe accounting model.

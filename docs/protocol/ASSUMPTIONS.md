# PRISM Phase-1 Assumptions Register

**Status:** CANONICAL MATH-1 INPUT  
**Purpose:** make every theorem/test boundary explicit.

A proof is only as strong as its assumptions. This file distinguishes protocol assumptions from market/integration assumptions so later docs do not accidentally promote behavior into safety.

---

## A. Protocol/accounting assumptions

### A-P01 Non-negative component payoffs

For every supported component `i` and terminal world `omega`:

```math
g_i(omega) >= 0
```

Required for the simple terminal-solvency implication from component backing.

### A-P02 Immutable activated replication

After activation, component identity/order and `x_i` do not change for that series generation.

### A-P03 Series-scoped reserved accounting

Backing counted toward one outstanding liability allocation is not simultaneously counted toward another.

### A-P04 Token transfer semantics

Supported backing tokens behave according to the accepted ERC-20 adapter assumptions. Fee-on-transfer/rebasing/non-standard tokens are unsupported unless explicitly normalized by a future adapter.

### A-P05 Resolution binding

The onchain resolution module commits exactly one canonical final outcome for a series generation under the immutable `ResolutionSpec`.

### A-P06 Settlement funding authority

The balance used for the `REDEEMABLE` gate is an actually spendable settlement balance controlled by the redemption path, not an offchain accounting number.

### A-P07 Precision implementation preserves the model within bounded error

The exact `Fraction` semantics are not directly representable in Solidity. MATH-1D must specify and bound implementation error.

---

## B. Native-market assumptions

### A-N01 Complete-set issuance

One canonical collateral unit splits into equal units of YES and NO in the normalized accounting domain.

### A-N02 Complete-set merge

Equal normalized YES and NO units can be burned/merged for the corresponding collateral while the market state allows it.

### A-N03 Binary exhaustiveness

For a valid resolved binary market:

```math
YES(omega)+NO(omega)=1
```

for every valid terminal state, subject to any separately specified invalid/void outcome policy.

If a market supports invalid/void outcomes, this assumption and the complete-set model must be extended before deployment.

---

## C. Resolution/oracle assumptions

### A-R01 Correct source interpretation

The resolution mechanism receives/interprets the source data required by the immutable market rules correctly.

Accounting proofs do not prove external factual truth.

### A-R02 Finality

A result used for final PRISM settlement is canonical/final according to the accepted resolution process.

### A-R03 Partial transformations use final component values

A resolved component is transformed into settlement collateral only after its payout is final and redeemable under source-market semantics.

---

## D. Market assumptions

These are NOT required for solvency theorems.

### A-M01 Executable depth exists

Arbitrage relations require sufficient executable bids/asks for the intended quantity.

### A-M02 Arbitrage capital/agents exist

A profitable theoretical deviation is corrected only if some participant can/will execute the trade.

### A-M03 Costs are modeled accurately enough

Gas, fees, slippage, latency, capital and operational costs affect practical arbitrage bands.

### A-M04 Marks are not protocol truth

Midpoints/component prices used for NAV are valuation inputs. They do not alter backing requirements or final contractual payoff.

### A-M05 Market makers can cancel/requote imperfectly

Resolution-jump experiments must allow stale orders/adverse selection; instant perfect repricing is not assumed.

---

## E. Integration assumptions

### A-I01 Kuru is execution infrastructure

Kuru controls orderbook execution/liquidity, not RetroPick issuance/backing truth.

### A-I02 Envio is a derived read model

Indexer state may lag/reorg and is not authoritative protocol accounting.

### A-I03 CRE is resolution orchestration in Phase 1

CRE may fetch/verify/orchestrate resolution according to accepted workflow, but is not used to mirror already-visible Monad backing balances.

### A-I04 Account UX does not imply legal identity

A passkey/account integration is an authentication/signing mechanism unless an independently verified identity/KYC layer is explicitly added.

---

## F. Deferred cross-chain assumptions

Not active in Metropolis Phase 1.

Any future wrapped external outcome architecture must separately define:
- custody authority;
- deposit finality;
- mint-message uniqueness;
- burn-before-unlock ordering;
- replay protection;
- bridge failure/recovery;
- wrapper supply vs locked-underlying invariant.

No future doc may infer that an attestation alone creates collateral.

---

## Assumption-change rule

If an implementation or integration violates an assumption used by an accepted theorem, the theorem cannot simply be reused. Update the model/ADR and re-run the relevant gate.

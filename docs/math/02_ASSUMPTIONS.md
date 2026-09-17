# 02 — Assumptions and Proof Dependencies

**Status:** CANONICAL MATH-1 ASSUMPTION PROJECTION  
**Source semantics:** `../protocol/ASSUMPTIONS.md`

This file does not invent a second assumption namespace. It reuses the canonical protocol assumption IDs and maps them to the mathematical claims they support.

If `docs/protocol/ASSUMPTIONS.md` changes, this dependency projection must be reviewed.

---

## 1. Proof-critical protocol/accounting assumptions

### A-P01 — Non-negative component payoffs

For every supported component `i` and terminal world `omega`:

```math
g_i(\omega)\ge0
```

Required by the simple terminal-solvency proof because multiplication of:

```math
B_i\ge Sx_i
```

by `g_i(omega)` must preserve the inequality direction.

If negative-payoff or negative-liability instruments are introduced, theorem `T-BS-003` cannot be reused unchanged.

### A-P02 — Immutable activated replication

Once a series generation activates, component identity/order and `x_i` are immutable.

Without this assumption, previously reserved backing can cease to correspond to the outstanding liability.

### A-P03 — Series-scoped reserved accounting

The same reserved balance units are not simultaneously counted toward two independent outstanding liabilities.

Token addresses may be reused across multiple series. Reserved **units** may not be double pledged.

### A-P04 — Supported token transfer semantics

The mathematical model assumes component deposits/releases equal the amounts accounted for.

Fee-on-transfer, rebasing or other non-standard assets are unsupported unless a future adapter proves equivalent normalized accounting.

### A-P05 — Resolution binding

Exactly one canonical final outcome is committed for a series generation according to its immutable resolution semantics.

The accounting proof does not establish the truth of the external fact; it assumes the accepted resolver delivers the canonical protocol result.

### A-P06 — Spendable settlement funding

`SettlementBalance` used by the `REDEEMABLE` gate represents assets that the redemption path can actually spend.

An offchain number, indexer balance or unspendable receivable is not settlement funding.

### A-P07 — Precision implementation preserves the accepted model

The exact `Fraction` oracle is not the production arithmetic domain.

The Solidity fixed-point implementation must conservatively preserve backing/funding and bound dust/extraction before exact-arithmetic theorems can be transferred to production claims.

---

## 2. Native complete-set assumptions

### A-N01 — Symmetric complete-set issuance

One normalized collateral unit creates one YES and one NO unit.

### A-N02 — Symmetric complete-set merge

Equal normalized YES and NO quantities can be burned for their corresponding collateral while merge is permitted.

### A-N03 — Binary exhaustiveness

For every valid resolved binary state:

```math
YES(\omega)+NO(\omega)=1
```

If invalid/void outcomes exist, the payoff basis and complete-set accounting must be extended before theorem reuse.

---

## 3. Resolution assumptions

### A-R01 — Correct source interpretation

The accepted resolution mechanism interprets source data according to the immutable `ResolutionSpec`.

This is an oracle/domain assumption, not an accounting theorem.

### A-R02 — Finality

A value used for final PRISM settlement is final under the accepted resolution process.

### A-R03 — Safe partial transformation

A component is replaced by settlement collateral only after its payout is final and actually redeemable, and the transformation preserves the remaining liability.

---

## 4. Market assumptions excluded from solvency proofs

The following assumptions are relevant to market behavior but are **not** premises of the backing-solvency theorems:

- `A-M01`: executable market depth exists;
- `A-M02`: arbitrage capital/agents exist;
- `A-M03`: costs are modeled accurately enough;
- `A-M04`: valuation marks are inputs, not protocol truth;
- `A-M05`: market makers do not reprice perfectly and instantaneously.

Therefore failure of Kuru liquidity, arbitrage participation or market-maker profitability does not by itself invalidate `T-BS-001` through `T-BS-004`.

---

## 5. Integration assumptions excluded from same-chain backing proofs

- `A-I01`: Kuru is execution infrastructure, not backing authority.
- `A-I02`: Envio is derived/read-model state, not accounting authority.
- `A-I03`: CRE may orchestrate resolution but does not mirror Monad-native PRISM balances for Phase 1.
- `A-I04`: account/passkey UX does not imply legal identity/KYC.

None of these integrations is a premise for component backing `B_i >= Sx_i`.

---

## 6. Deferred cross-chain assumptions

Cross-chain custody/wrapper assumptions are intentionally outside Phase 1.

The wrapper derivation from earlier research is not promoted into the active theorem set. A later phase must separately define custody, message uniqueness, burn-before-unlock ordering, replay protection and wrapper supply/locked-underlying invariants.

---

## 7. Theorem dependency matrix

| Theorem / claim | Required canonical assumptions | Notes |
|---|---|---|
| `T-REPL-001` exact payoff evaluation `h=Gx` | A-P02 | Matrix/vector definitions must be immutable for the admitted generation. |
| `T-BS-001` mint preserves backing | A-P02, A-P03, A-P04, A-P07* | Exact proof uses exact arithmetic; `A-P07` is required when transferring to integer implementation. |
| `T-BS-002` in-kind redemption preserves backing | A-P02, A-P03, A-P04, A-P07* | Liability must decrease before/equivalent to backing release in implementation. |
| `T-BS-003` component backing implies terminal solvency | A-P01, A-P02, A-P03 | Core exact-math theorem. |
| `T-BS-004` funded final redemption preserves funding | A-P05, A-P06, A-P07* | Requires fixed final payout and actually spendable settlement balance. |
| `T-NATIVE-001` complete-set conservation | A-N01, A-N02, A-P04, A-P07* | Native market theorem. |
| `T-NATIVE-002` complementary terminal payoff | A-N03, A-P05 | Applies only to valid binary terminal states. |
| `T-PARTIAL-001` partial-resolution NAV identity | A-R02, A-M04 | Valuation identity given supplied unresolved marks. Not an exchange-price theorem. |
| `T-QUOTE-001` resolved PRISM/quote relative-value identity | A-P05, A-M04 | Idealized ratio before costs/risk. |
| `CX-REPL-001` AND non-replicability in the stated basis | none beyond the defined finite payoff basis | Formal counterexample. |
| `H-MKT-001` arbitrage closes NAV divergence rapidly | A-M01, A-M02, A-M03, A-M05 | Empirical hypothesis, not theorem. |
| `H-MKT-002` sustainable market-maker profitability | A-M01, A-M03, A-M05 | Simulation/live-evidence question. |
| `H-LIQ-001` adequate Kuru liquidity | A-M01 | Live-evidence question. |

`A-P07*` means the exact rational theorem is already valid without fixed-point arithmetic; the assumption becomes mandatory before claiming the equivalent Solidity property.

---

## 8. Assumption failure policy

If a premise used by an accepted theorem becomes false:

```text
do not reuse theorem
-> classify affected claim as NOT_YET_VALIDATED
-> update ADR/spec if architecture changed
-> update proof/model
-> rerun relevant MATH-1 gate
```

Examples:

- introducing negative-liability components invalidates the current `T-BS-003` proof;
- allowing mutable weights invalidates all backing proofs tied to the old `x`;
- supporting fee-on-transfer assets invalidates naive deposit/release equalities;
- allowing approximate replication introduces residual basis error not covered by the exact-replication theorem;
- treating an unfunded receivable as settlement cash invalidates `T-BS-004`.

# 16 — Invariant Registry and Oracle Traceability

**Status:** CANONICAL MATH-1 TRACEABILITY REGISTRY  
**Source invariants:** `../protocol/INVARIANTS.md`  
**Executable oracle:** `../../research/prism-model/`

This document does not redefine invariant semantics. It maps every accepted invariant to its proof role, current Python enforcement/evidence, future contract target, and known coverage gaps.

Coverage labels:

```text
ORACLE_ENFORCED
ORACLE_CHECKED
DOC_CLASSIFIED
NOT_YET_MODELED
FUTURE_PHASE
```

`ORACLE_CHECKED` means a helper/test can evaluate the property; it does not necessarily mean every state mutation is guarded by that helper.

---

## 1. Native complete-set invariants

| ID | Mathematical / protocol statement | Current Python oracle | Coverage | Future Solidity / test target |
|---|---|---|---|---|
| `INV-N01` | Split `C` collateral -> `C YES + C NO` and locks `C` collateral | `market_math.assert_complete_set_conservation()` checks resulting identity, but no stateful split object exists yet | `ORACLE_CHECKED` | `CompleteSetVault.split`; invariant `YES_supply == NO_supply == collateralLocked` |
| `INV-N02` | Equal YES/NO merge releases corresponding collateral | No stateful native complete-set transition model yet | `NOT_YET_MODELED` | `CompleteSetVault.merge`; conservation/property tests |
| `INV-N03` | `YES(omega)+NO(omega)=1` in every valid binary terminal state | Can be represented/tested through payoff matrices; no dedicated named helper | `ORACLE_CHECKED` | Native resolution fixture/invariant suite |
| `INV-N04` | `OI = YES_supply = NO_supply = CollateralLocked` | `market_math.complete_set_open_interest()` + `assert_complete_set_conservation()` | `ORACLE_ENFORCED` | Envio/indexed OI derived from canonical contract accounting |
| `INV-N05` | Activated resolution spec/final result immutable | PRISM lifecycle models final-state monotonicity; native market resolution object not yet modeled | `NOT_YET_MODELED` | Immutable/pinned `ResolutionSpec`; finalization-once Foundry tests |

### Native gap

Before `CONTRACT-ARCH-1`, add a small stateful native complete-set oracle or explicitly keep native-market proofs outside PRISM MATH-1. Do not infer split/merge mutation safety merely from static parity helpers.

---

## 2. PRISM replication and backing invariants

| ID | Statement | Python mapping | Coverage | Proof / contract target |
|---|---|---|---|---|
| `INV-P01` | Activated series satisfies exact `h=Gx`, `x>=0` | `replication.normalize_matrix()`, `payoff()`, `find_exact_nonnegative_replication()`, `is_exactly_replicable()` | `ORACLE_ENFORCED` | `T-REPL-001`; admission compiler/registry stores immutable replication commitment |
| `INV-P02` | Activated component set/weights/semantics immutable | `PrismSeries.weights` is initialized once in model; no mutation API exists | `ORACLE_ENFORCED` structurally | Factory/registry immutability tests |
| `INV-P03` | `B_i >= S*x_i` for every component | `required_backing()`, `backing_margin()`, `assert_component_backed()` | `ORACLE_ENFORCED` | `T-BS-001..003`; runtime backing invariant |
| `INV-P04` | Backing first, mint second | `mint()` checks post-mint requirement before changing `supply`; `mint_with_exact_backing()` deposits then mints | `ORACLE_ENFORCED` | Mint controller must reserve/receive all backing before supply increase |
| `INV-P05` | In-kind redemption releases no more than `Q*x_i` and leaves remainder backed | `redeem_in_kind()` + `assert_component_backed()` | `ORACLE_ENFORCED` | `T-BS-002`; burn/decrease liability before proportional release |
| `INV-P06` | `V_B(omega) >= L_P(omega)` for every modeled terminal world | `terminal_solvency()`, `settlement.terminal_backing_value()`, `bounded_verification.verify_terminal_solvency_grid()` | `ORACLE_CHECKED` | `T-BS-003`; admission + component backing imply this property |
| `INV-P07` | Same reserved units cannot satisfy two independent liabilities | Single-series model has no global reservation ledger | `NOT_YET_MODELED` | Series reservation ledger / global allocation invariant; cross-series stateful test |
| `INV-P08` | Partial-resolution transformation preserves remaining payoff obligation | `market_math.partial_resolution_nav()` values resolved/unresolved mixture, but no stateful backing transformation is implemented | `NOT_YET_MODELED` | Explicit transformation rule + before/after payoff-equivalence assertion |
| `INV-P09` | `REDEEMABLE -> SettlementBalance >= Supply*FinalPayout` | `settlement_is_funded()`, `PrismSeries.make_redeemable()` | `ORACLE_ENFORCED` | `T-BS-004`; hard lifecycle funding gate |
| `INV-P10` | Final burn pays deterministic `Q*FinalPayout` and preserves funding | `PrismSeries.redeem_final()`, `verify_settlement_redemption_grid()` | `ORACLE_ENFORCED` / `ORACLE_CHECKED` | `T-BS-004`; payout/burn conservation |
| `INV-P11` | Lifecycle monotonicity; no resurrection | `lifecycle._ALLOWED`, `can_transition()`, `transition()` | `ORACLE_ENFORCED` | Stateful Foundry lifecycle invariant |
| `INV-P12` | Final resolution committed once | `resolve()` only from `RESOLUTION_PENDING`; transition then moves to `RESOLVED` | `ORACLE_ENFORCED` | Final-result immutability + duplicate-resolution revert |
| `INV-P13` | Backing != LP/MM inventory != fee balances | Model only represents series backing and settlement; external inventory domains are not modeled | `DOC_CLASSIFIED` | Separate storage/accounting domains; integration tests ensure no aliasing |
| `INV-P14` | Runtime mint does not enumerate terminal worlds | `mint()` uses `required_backing()` only; `terminal_solvency()` is separate diagnostic | `ORACLE_ENFORCED` structurally | Contract mint loops components only, never `Omega` |

---

## 3. Market/economic classification invariants

| ID | Statement | Python / docs mapping | Coverage | Required evidence |
|---|---|---|---|---|
| `INV-M01` | Market convergence/MM profitability/demand/depth are not called formal proofs | `docs/math/17_THEOREMS.md`, `docs/protocol/MATH_MODEL.md`, model README | `DOC_CLASSIFIED` | Simulation/live evidence only |
| `INV-M02` | Complete-set arbitrage uses executable bid/ask sides | `market_math.split_and_sell_profit()`, `buy_and_merge_profit()` | `ORACLE_ENFORCED` as reference math | Later Kuru depth-aware experiments |
| `INV-M03` | Retail secondary trade does not modify backing; primary CREATE does | No exchange/user state model currently | `DOC_CLASSIFIED` | E2E integration tests after Kuru contracts exist |

---

## 4. Fixed-point implementation invariants

The protocol invariant file refers to precision tolerance through `INV-P09/P10`, while the candidate implementation model lives in `fixed_point.py`.

Candidate MATH-1D rules:

```text
required backing -> ceil
releasable backing -> floor
```

Current helpers:

```text
mul_div_floor()
mul_div_ceil()
encode_fraction_floor()
encode_fraction_ceil()
required_backing_units()
releasable_backing_units()
round_trip_dust_units()
exact_required_fraction()
```

Current classification:

```text
IMPLEMENTED_CANDIDATE
NOT_YET_PROVEN_FOR_PRODUCTION
```

Before inheriting exact-theorem status in Solidity, add explicit invariants:

- integer post-mint requirement can never be below exact required backing after normalization;
- integer release can never exceed exact entitlement after normalization;
- cumulative dust has a deterministic upper bound;
- no cyclic mint/redeem sequence yields positive extraction;
- mixed component token decimals are normalized deterministically.

---

## 5. Invariant-to-theorem mapping

| Invariant | Theorem / classification |
|---|---|
| `INV-P01` | `T-REPL-001`, `CX-REPL-001` |
| `INV-P03` | `T-BS-001`, `T-BS-002`, `T-BS-003` |
| `INV-P04` | `T-BS-001` |
| `INV-P05` | `T-BS-002` |
| `INV-P06` | `T-BS-003` |
| `INV-P07` | Necessary premise for global solvency; implementation theorem pending |
| `INV-P08` | Partial-resolution transformation theorem pending |
| `INV-P09` | `T-BS-004` |
| `INV-P10` | `T-BS-004` |
| `INV-P11` | `T-LC-001` |
| `INV-P12` | `T-LC-002` |
| `INV-M02` | `H-MKT-001` uses these executable values but remains empirical |

---

## 6. Invariant-to-oracle action map

### Mint

```text
PrismSeries.mint()
  -> state must be ACTIVE
  -> quantity > 0
  -> required_backing(new_supply)
  -> verify backing >= requirement
  -> update supply
  -> assert_component_backed()
```

Protects primarily:

```text
INV-P03
INV-P04
INV-P14
```

### In-kind redemption

```text
PrismSeries.redeem_in_kind()
  -> allowed lifecycle state
  -> Q <= supply
  -> compute Q*x
  -> reduce supply
  -> release backing
  -> assert_component_backed()
```

Protects:

```text
INV-P03
INV-P05
```

### Resolution/funding/final redemption

```text
start_resolution()
resolve()
fund_settlement()
make_redeemable()
redeem_final()
archive()
```

Protects/checks:

```text
INV-P09
INV-P10
INV-P11
INV-P12
```

---

## 7. Bounded verification mapping

`bounded_verification.py` currently provides finite-domain evidence for:

```text
verify_mint_redeem_grid()
  INV-P03/P04/P05

verify_terminal_solvency_grid()
  INV-P06

verify_settlement_redemption_grid()
  INV-P09/P10
```

These results must be classified as:

```text
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
```

for the declared bounds, not universal proof.

The universal exact statements come from the algebraic proofs in `05_BACKING_SOLVENCY.md`.

---

## 8. Current MATH-1 coverage gaps

The following accepted invariants are not fully represented in the current executable oracle and must remain visible:

1. `INV-N02` stateful complete-set merge conservation;
2. `INV-N05` native ResolutionSpec/finalization immutability;
3. `INV-P07` global/cross-series reservation uniqueness;
4. `INV-P08` stateful payoff-equivalent partial backing transformation;
5. `INV-P13` separation from live Kuru LP/MM/fee accounting;
6. production fixed-point versions of `INV-P03/P05/P09/P10`;
7. retail trade vs primary creation in a real exchange-integrated state model.

No MATH-1 verdict may claim these are proven merely because related prose exists.

---

## 9. Future Solidity traceability contract

`CONTRACT-ARCH-1` must extend this table so every safety-critical invariant has:

```text
Invariant ID
-> contract/storage authority
-> mutating functions
-> require/revert condition
-> event evidence
-> Foundry unit test
-> Foundry stateful invariant
-> Python differential fixture
```

No safety-critical storage mutation should exist without an invariant owner.

# 16 — Invariant Registry and Oracle Traceability

**Status:** CANONICAL MATH-1 TRACEABILITY REGISTRY  
**Source invariants:** `../protocol/INVARIANTS.md`  
**Executable oracle:** `../../research/prism-model/`

Coverage labels:

```text
ORACLE_ENFORCED
ORACLE_CHECKED
DOC_CLASSIFIED
NOT_YET_MODELED
FUTURE_PHASE
```

---

## 1. Native complete-set invariants

| ID | Statement | Current Python oracle | Coverage | Future Solidity target |
|---|---|---|---|---|
| `INV-N01` | Split `C` collateral -> `C YES + C NO` and lock `C` | `native_market.BinaryCompleteSetMarket.split()` + `assert_invariants()` | `ORACLE_ENFORCED` | `CompleteSetVault.split`; supply/collateral stateful invariant |
| `INV-N02` | Equal YES/NO merge releases corresponding collateral | `BinaryCompleteSetMarket.merge()` | `ORACLE_ENFORCED` | `CompleteSetVault.merge`; conservation tests |
| `INV-N03` | `YES(omega)+NO(omega)=1` in valid binary terminal states | binary payoff fixtures + resolved native market model | `ORACLE_CHECKED` | resolution fixture/invariant suite |
| `INV-N04` | Active OI = `YES_supply = NO_supply = CollateralLocked` | `BinaryCompleteSetMarket.open_interest()` + static market helpers | `ORACLE_ENFORCED` | indexed OI derived from canonical contract state |
| `INV-N05` | Final native result cannot be committed twice | `BinaryCompleteSetMarket.resolve()` only from `ACTIVE` | `ORACLE_ENFORCED` for finalization-once; ResolutionSpec content immutability remains architectural | immutable `ResolutionSpec` + finalization-once tests |

After native resolution the stateful oracle enforces:

```math
CollateralLocked = RemainingWinningSupply
```

until winning claims are redeemed. Losing claims can be burned for zero before archive.

---

## 2. PRISM replication/backing invariants

| ID | Statement | Python mapping | Coverage | Contract target |
|---|---|---|---|---|
| `INV-P01` | Activated series satisfies exact `h=Gx`, `x>=0` | `replication.payoff()`, exact solver | `ORACLE_ENFORCED` | immutable admission commitment |
| `INV-P02` | Activated component/weight semantics immutable | no mutation API on `PrismSeries.weights`; conditioned resolution only narrows state space | `ORACLE_ENFORCED` structurally | immutable registry data |
| `INV-P03` | `B_i >= Sx_i` | `required_backing()`, `assert_component_backed()` | `ORACLE_ENFORCED` | runtime component requirement |
| `INV-P04` | Backing first, mint second | `mint()` and `mint_with_exact_backing()` | `ORACLE_ENFORCED` | supply changes only after backing established |
| `INV-P05` | In-kind redemption cannot leave remaining supply underbacked | `redeem_in_kind()`; `redeem_in_kind_mixed()` after partial resolution | `ORACLE_ENFORCED` | liability decrease then safe release |
| `INV-P06` | `V_B(omega) >= L_P(omega)` | conditioned `terminal_solvency()`, bounded verifier | `ORACLE_CHECKED` + exact proof | no state enumeration in mint |
| `INV-P07` | Same physical units cannot secure two independent liabilities | `reservation_ledger.ReservationLedger` | `ORACLE_ENFORCED` in reference transition system | global reservation ledger or equivalent vault partitioning |
| `INV-P08` | Finalized component -> settlement transformation preserves remaining obligations | `resolve_component()`, `possible_states`, `transformed_settlement`, mixed redemption | `ORACLE_ENFORCED` in exact oracle | state-conditioned backing transformation |
| `INV-P09` | `REDEEMABLE -> SettlementBalance >= Supply*FinalPayout` | exact settlement model + `FixedPointSettlement.make_redeemable()` | `ORACLE_ENFORCED` | hard funding gate |
| `INV-P10` | Final redemption preserves funding | exact `redeem_final()` + integer `FixedPointSettlement.redeem()` | `ORACLE_ENFORCED` | deterministic payout/burn |
| `INV-P11` | Lifecycle monotonicity/no resurrection | `lifecycle._ALLOWED` | `ORACLE_ENFORCED` | stateful Foundry invariant |
| `INV-P12` | Final PRISM resolution committed once | `resolve()` only from `RESOLUTION_PENDING` | `ORACLE_ENFORCED` | final-result immutability |
| `INV-P13` | Backing != LP/MM inventory != fees | protocol oracle models backing/settlement separately but not live Kuru/MM balances | `DOC_CLASSIFIED` | distinct storage/accounting domains + integration tests |
| `INV-P14` | Mint does not enumerate terminal worlds | `mint()` uses component requirement only | `ORACLE_ENFORCED` structurally | component loop only |

---

## 3. Cross-series reservation invariant

For physical asset `a`:

```math
\boxed{\sum_s Reserved_{s,a}\le PhysicalBalance_a}
```

`ReservationLedger` enforces this across:
- deposit;
- reserve;
- release;
- withdrawal.

A reservation request larger than currently unreserved balance is rejected atomically. A withdrawal that would consume reserved backing is rejected.

This closes the previous series-local `INV-P07` oracle gap for the reference transition system. Production storage authority still must implement equivalent semantics.

---

## 4. Partial-resolution invariant

When component `i` finalizes at payout `r_i`, the exact oracle conditions feasible terminal worlds to:

```math
\Omega' = \{\omega\mid g_i(\omega)=r_i\}
```

and replaces component backing value:

```math
B_i r_i
```

with equal settlement backing.

`PrismSeries.resolve_component()`:
- rejects duplicate resolution;
- rejects payout inconsistent with all remaining worlds;
- pauses mint on first payoff-relevant partial resolution;
- zeros transformed component backing;
- adds exact settlement replacement;
- narrows `possible_states`;
- re-checks backing.

`redeem_in_kind_mixed()` then releases unresolved components plus proportional transformed settlement while preserving the remaining requirement.

---

## 5. Fixed-point implementation invariants

Candidate normalized domain:

```text
series scale = 1e18
component decimals = 0..18
```

For component decimal factor `f_i=10^(18-d_i)`:

```math
Req_i(S)=ceil(S*x_i/(WAD*f_i)).
```

Integer model:

```text
research/prism-model/fixed_point_model.py
```

Current coverage:

| Precision property | Oracle | Coverage |
|---|---|---|
| post-mint raw backing never below conservative requirement | `FixedPointSeries.mint()` | `ORACLE_ENFORCED` |
| minimum incremental backing uses total-supply requirement delta | `minimum_incremental_backing()` | `ORACLE_ENFORCED` |
| redemption cannot underback remaining supply | `FixedPointSeries.redeem()` | `ORACLE_ENFORCED` |
| raw-to-normalized conversion for `0..18` decimals is deterministic/exact | `decimal_factor()`, `normalize_raw()` | `ORACLE_ENFORCED` |
| binary terminal backing covers conservative integer liability | `terminal_solvency_binary()` | `ORACLE_CHECKED` |
| dust cannot be swept while supply exists | `sweepable_dust()` | `ORACLE_ENFORCED` |
| final settlement cannot become redeemable while underfunded | `FixedPointSettlement.make_redeemable()` | `ORACLE_ENFORCED` |
| rounded final redemption preserves remaining required funding | `FixedPointSettlement.redeem()` | `ORACLE_ENFORCED` |

Production Solidity equivalence remains downstream work even where the candidate integer reference semantics are now proven/checked.

---

## 6. Market/economic classification invariants

| ID | Statement | Mapping | Coverage |
|---|---|---|---|
| `INV-M01` | Convergence/MM profitability/demand/depth are not called formal proofs | theorem registry + protocol docs | `DOC_CLASSIFIED` |
| `INV-M02` | Complete-set arbitrage uses executable bid/ask sides | `market_math.split_and_sell_profit()`, `buy_and_merge_profit()` | `ORACLE_ENFORCED` as reference math |
| `INV-M03` | Retail trade does not change backing; primary CREATE does | architecture docs; no real Kuru state model yet | `DOC_CLASSIFIED` |

---

## 7. Adversarial executable coverage

`adversarial.py` currently provides deterministic randomized runners for:

```text
fixed-point mint/redeem + all canonical pFEDBTC terminal states
cross-series reservation/release pressure
```

The regression suite also covers:
- over-allocation rejection;
- reserved-balance withdrawal rejection;
- native split/merge conservation;
- winner/loser redemption after resolution;
- archive preconditions;
- partial-resolution state conditioning;
- mint pause after partial resolution;
- mixed component/cash redemption;
- invalid terminal-state resolution after conditioning;
- 6-decimal normalization;
- integer terminal solvency;
- final-settlement underfunding rejection.

Randomized evidence does not replace the algebraic proofs in `05_BACKING_SOLVENCY.md`.

---

## 8. Invariant-to-theorem mapping

| Invariant | Theorem / classification |
|---|---|
| `INV-N01/N02/N04` | `T-NATIVE-001` |
| `INV-P01` | `T-REPL-001`, `CX-REPL-001` |
| `INV-P03/P04` | `T-BS-001`, `T-FP-001` |
| `INV-P05` | `T-BS-002`, `T-FP-002` |
| `INV-P06` | `T-BS-003` |
| `INV-P07` | `T-ALLOC-001` |
| `INV-P08` | `T-PARTIAL-002` |
| `INV-P09/P10` | `T-BS-004`, `T-FP-003` |
| rounding cycle safety | `T-FP-004` |
| `INV-P11/P12` | `T-LC-001/T-LC-002` |
| `INV-M02` | market-reference math; not a convergence theorem |

---

## 9. Remaining executable gaps

The prior core accounting gaps are now represented in the Python oracle. Remaining pre-Solidity work is narrower:

1. generate deterministic machine-readable Python fixtures for Solidity differential tests;
2. add explicit 6/8/18-decimal CI matrix and configured uint256 boundary tests;
3. decide final settlement-dust disposition after zero supply;
4. add fixed-point partial-resolution transformation if production Phase 1 requires partial conversion before final settlement;
5. encode theorem/algebra checks in Z3/SymPy where useful and emit machine-readable theorem status;
6. model/check live separation from Kuru LP/MM/fee balances during integration;
7. perform Solidity differential/stateful invariant testing after CONTRACT-ARCH-1.

No remaining market-behavior uncertainty is allowed to be confused with protocol solvency.

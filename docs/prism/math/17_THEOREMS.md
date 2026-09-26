# 17 — Theorem, Counterexample, and Market-Hypothesis Registry

**Status:** CANONICAL MATH-1 CLAIM REGISTRY  
**Purpose:** distinguish deductive protocol properties from bounded executable evidence and empirical market claims.

Allowed scientific statuses:

```text
PROVEN_UNDER_ASSUMPTIONS
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
SUPPORTED_BY_SIMULATION
SUPPORTED_BY_LIVE_EVIDENCE
NOT_YET_VALIDATED
COUNTEREXAMPLE_FOUND
```

Exact theorem status and future Solidity-equivalence status remain separate.

---

## 1. Core theorem registry

| ID | Claim | Scientific status | Proof/source | Executable oracle | Production implication |
|---|---|---|---|---|---|
| `T-REPL-001` | admitted basket payoff is exactly `h=Gx` | `PROVEN_UNDER_ASSUMPTIONS` | definitions/protocol math | `replication.payoff()` | admission commits immutable semantics |
| `T-BS-001` | exact-backed mint preserves component backing and margin | `PROVEN_UNDER_ASSUMPTIONS` | `05_BACKING_SOLVENCY.md` | exact model + bounded verifier | backing-first mint |
| `T-BS-002` | exact in-kind redemption preserves remaining backing | `PROVEN_UNDER_ASSUMPTIONS` | `05_BACKING_SOLVENCY.md` | exact model + bounded verifier | liability decrease before release |
| `T-BS-003` | exact non-negative replication + component backing implies terminal solvency | `PROVEN_UNDER_ASSUMPTIONS` | `05_BACKING_SOLVENCY.md` | `terminal_solvency()` | component checks suffice at runtime |
| `T-BS-004` | funded final redemption preserves remaining settlement funding | `PROVEN_UNDER_ASSUMPTIONS` | `05_BACKING_SOLVENCY.md` | exact settlement model | `RESOLVED != REDEEMABLE` |
| `T-ALLOC-001` | global reservation invariant `sum_s Reserved[s,a] <= PhysicalBalance[a]` is preserved by deposit/reserve/release/withdraw transitions | `PROVEN_UNDER_ASSUMPTIONS` for the reference transition system | `05_BACKING_SOLVENCY.md#6` | `ReservationLedger` | production needs equivalent authoritative reservation storage |
| `T-PARTIAL-002` | finalized component -> equal settlement value preserves backing value over the conditioned terminal state space | `PROVEN_UNDER_ASSUMPTIONS` | `05_BACKING_SOLVENCY.md#7` | `resolve_component()`, mixed redemption | partial transformation must condition states and preserve value exactly |
| `T-NATIVE-001` | canonical binary split/merge conserves complete-set collateral accounting | `PROVEN_UNDER_ASSUMPTIONS` | native complete-set semantics | `BinaryCompleteSetMarket` | stateful complete-set invariant in Solidity |
| `T-NATIVE-002` | valid binary terminal payoff satisfies `YES(omega)+NO(omega)=1` | `PROVEN_UNDER_ASSUMPTIONS` | accepted binary payoff basis | binary fixtures/native resolution | invalid/void policy must be specified separately |
| `T-LC-001` | canonical PRISM lifecycle has no resurrection into issuance | `PROVEN_UNDER_ASSUMPTIONS` | state-machine graph | `lifecycle.transition()` | Foundry stateful lifecycle invariant |
| `T-LC-002` | canonical final PRISM resolution cannot be committed twice | `PROVEN_UNDER_ASSUMPTIONS` | state-machine graph | `PrismSeries.resolve()` | immutable final result |
| `T-PARTIAL-001` | partial-resolution NAV decomposes linearly by resolved/unresolved sets | `PROVEN_UNDER_ASSUMPTIONS` | protocol math | `partial_resolution_nav()` | valuation identity only |
| `T-QUOTE-001` | resolved PRISM/quote idealized relative value is `R/P_Q` before costs/risk | `PROVEN_UNDER_ASSUMPTIONS` | algebraic identity | `post_resolution_pair_value()` | not a liquidity/price guarantee |

---

## 2. Fixed-point theorem transfer

Candidate domain:

```text
series scale = 1e18
component/settlement decimals = 0..18
raw normalization factor = 10^(18-decimals)
```

| ID | Claim | Scientific status for candidate Python integer model | Oracle | Solidity-equivalence status |
|---|---|---|---|---|
| `T-FP-001` | ceil total-supply component requirement prevents integer mint underreservation | `PROVEN_UNDER_ASSUMPTIONS` | `FixedPointSeries.required_backing_raw()`, `mint()` | pending CONTRACT-ARCH-1 differential proof |
| `T-FP-002` | requirement-delta redemption cannot leave remaining supply below conservative raw requirement | `PROVEN_UNDER_ASSUMPTIONS` | `FixedPointSeries.redeem()` | pending Solidity equivalence |
| `T-FP-003` | conservative aggregate settlement requirement plus guarded rounded redemption preserves funding | `PROVEN_UNDER_ASSUMPTIONS` for accepted transitions | `FixedPointSettlement` | pending Solidity equivalence/dust policy |
| `T-FP-004` | minimum-backing mint followed by inverse requirement-delta redemption has zero net component extraction | `PROVEN_UNDER_ASSUMPTIONS` | `FixedPointSeries` + randomized stress | pending Solidity equivalence |

These statuses apply to the **candidate integer reference semantics**, not deployed Solidity.

Executable tests additionally check mixed 18/6-decimal backing, canonical binary terminal states, randomized mint/redeem sequences, and underfunded final-settlement rejection.

---

## 3. Replication counterexample

### `CX-REPL-001` — marginal binary claims do not generally span conjunction payoffs

For:

```math
A=(0,0,1,1),\qquad B=(0,1,0,1)
```

and desired:

```math
h_{AND}=(0,0,0,1),
```

any non-negative combination is:

```math
xA+yB=(0,y,x,x+y).
```

Coordinates 2 and 3 force `x=y=0`, contradicting required fourth coordinate `1`.

Therefore:

```math
\boxed{h_{AND}\notin\mathcal C}
```

for that basis.

**Status:** `COUNTEREXAMPLE_FOUND`.

**Oracle:** exact replication solver rejects the canonical fixture.

---

## 4. Executable verification claims

The following are evidence over declared domains, not substitutes for deductive proofs.

| ID | Property | Executable evidence | Status after a recorded successful run |
|---|---|---|---|
| `E-BND-001` | bounded exact mint/redeem backing preservation | `verify_mint_redeem_grid()` | `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN` |
| `E-BND-002` | bounded terminal solvency in every enumerated world | `verify_terminal_solvency_grid()` | `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN` |
| `E-BND-003` | bounded exact settlement redemption preservation | `verify_settlement_redemption_grid()` | `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN` |
| `E-ADV-001` | deterministic randomized fixed-point mint/redeem stress keeps backing/terminal solvency | `adversarial.run_fixed_point_stress()` | supporting adversarial evidence, not universal proof |
| `E-ADV-002` | deterministic randomized cross-series reservations never exceed physical balance | `adversarial.run_reservation_stress()` | supporting adversarial evidence, not universal proof |
| `E-NATIVE-001` | stateful split/merge/resolve/redeem regression coverage | `test_executable_gaps.NativeCompleteSetTests` | executable regression evidence |
| `E-PARTIAL-001` | partial transformation/mixed redemption/conditioned final state regression coverage | `test_executable_gaps.PartialResolutionTests` | executable regression evidence |
| `E-FP-001` | integer backing/terminal/settlement boundary coverage | `test_executable_gaps.FixedPoint*` | executable regression evidence |

---

## 5. Market hypotheses: explicitly not theorems

### `H-MKT-001` — arbitrage closes PRISM/NAV divergence quickly

Creation/redemption economics can create an incentive, but execution depends on depth, capital, latency, gas, inventory and operational risk.

**Status:** `NOT_YET_VALIDATED`.

### `H-MKT-002` — market makers remain sustainably profitable through resolution jumps

**Status:** `NOT_YET_VALIDATED`.

### `H-LIQ-001` — Kuru markets achieve adequate depth/spreads

**Status:** `NOT_YET_VALIDATED`.

### `H-ADOPT-001` — users want to trade/own PRISM at meaningful scale

**Status:** `NOT_YET_VALIDATED`.

None of these may be promoted by a unit test, proof of solvency, sponsor integration, or one successful demo trade.

---

## 6. Remaining theorem/implementation gaps

The previous core executable gaps `T-ALLOC-001`, `T-PARTIAL-002`, and the candidate integer transfer `T-FP-001..004` now have explicit reference implementations and proofs/guards.

Remaining pre-production work is primarily **implementation equivalence and scope completion**, not a missing exact solvency kernel:

```text
machine-readable Python -> Solidity fixtures
6/8/18 decimal CI matrix
uint256/configured maximum-bound tests
final zero-supply settlement-dust policy (classified in section 11; the residual sits; no sweep was added)
fixed-point partial-resolution transform if required onchain
Z3/SymPy proof artifacts where useful
live Kuru LP/MM/fee-domain separation checks
Foundry differential + stateful invariant suite (candidate settlement suite recorded in section 12; kernel stays differential_research_kernel)
```

If any of those exposes a counterexample, theorem/assumption status must be downgraded and the economic model revisited.

---

## 7. MATH-1 gate

Exact/accounting theorem set now includes:

```text
T-REPL-001
T-BS-001..004
T-ALLOC-001
T-PARTIAL-001
T-PARTIAL-002
T-NATIVE-001..002
T-LC-001..002
T-FP-001..004   (candidate Python integer semantics)
```

The final MATH-1 verdict still requires:
- fresh captured full-suite evidence from repository state;
- remaining precision boundary/fixture work;
- adversarial coverage appropriate to configured bounds;
- explicit classification of every market claim;
- no unresolved accounting counterexample.

Production Solidity remains downstream of `CONTRACT-ARCH-1`.

---

## 8. Fresh evidence addendum — 2026-09-26

This addendum does not delete earlier rows. It records a new run and a counterexample.

Source: `research/prism-model/math1_probe.py`, test `test_math1_probe.py`, log classification in `research/prism/reports/PRISM_REPRODUCTION_REPORT.md`.

| ID | Claim | Status | Evidence |
|---|---|---|---|
| `CX-FP-SETTLEMENT-001` | Per-call `floor(q * payout / D)` settlement redemption can pay holders less than the one-shot floor. For supply 2, payout `10^18-1`, 18 decimals, required funding is 2, one-shot floor pays 1, two 1-unit redemptions pay 0, and `sweepable_dust()` is 2. | `COUNTEREXAMPLE_FOUND` | `math1_probe.settlement_fragmentation_counterexample` |
| `T-FP-003` | Guarded rounded redemption preserves the ceil funding requirement for remaining supply. | unchanged `PROVEN_UNDER_ASSUMPTIONS` for that narrower funding claim | the counterexample above stays solvent while underpaying holders |
| `T-FP-CUM-001` | Cumulative floor settlement pays `floor(supply * payout / D)` in total, and dust against exact ceil funding is 0 or 1. | `PROVEN_UNDER_ASSUMPTIONS` for integer division; grid of 240 cases had worst dust 1 | candidate repair, not an accepted replacement |
| `CX-REPL-001` | A, B, and the constant-1 column do not replicate AND. | reconfirmed `COUNTEREXAMPLE_FOUND` | existing solver returned None; Z3 5.1.0 reported unsat |
| `T-BS-003` | Two-component, one-state, non-negative backing implies terminal value at least supply times payoff. | reconfirmed `PROVEN_UNDER_ASSUMPTIONS` by Z3 unsat of the negation and by a SymPy 1.14.0 identity | not a substitute for the general write-up |

MATH-1D for the current per-call settlement payout rule is **FAIL**. The component requirement-delta mint/redeem round trip did not show extraction in 200 deterministic samples (seed 20260926) and is zero by construction of that delta. That does not repair settlement.

No PRISM settlement Solidity is authorized off this addendum. A human-accepted ADR would be required before replacing the payout rule.

## 9. Candidate cumulative floor — 2026-09-26

This section does not replace section 8 and does not mark MATH-1 PASS. `FixedPointSettlement.redeem` is unchanged.

Source: `research/prism-model/cumulative_settlement.py`, `cumulative_settlement_attack.py`, `tests/test_cumulative_settlement.py`.

| ID | Claim | Status | Evidence |
|---|---|---|---|
| `CX-FP-SETTLEMENT-001` | Per-call settlement floor. Supply 2, payout `10^18-1`, two 1-unit redemptions pay 0, sweepable dust 2. | still `COUNTEREXAMPLE_FOUND` | permanent regression |
| `T-FP-CUM-001` | Global-cursor payouts over any partition sum to `floor(supply * payout / D)`. Exact ceil funding leaves residual 0 or 1. One redemption pays the isolated floor or one more. | `PROVEN_UNDER_ASSUMPTIONS` | integer telescoping. Domain check `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN`: 378530 states, 2542061 transitions, 2.973316s, no new counterexample |

A holder who splits can miss a carry that another holder receives. That moves value between holders. It does not increase dust above the ceil-floor residual. The candidate has no mint function. No settlement Solidity was added.

## 10. Precision boundary — 2026-09-26

This section does not mark MATH-1 PASS and does not change either payout formula.

Configured domain, not a uint256 enumeration. Decimals are 6, 8, and 18. Supplies are 0, 1, 2, 2^8, 2^16, 2^32, and 2^64. Payouts are 0, 1, D/2, D-1, D, D+1, 2^128, and 2^256-1, where D = 10^18 * 10^(18-decimals). The matrix has 168 cells. Runtime 0.001788s. Evidence: `evidence/research/prism/precision-boundary-6-8-18-2026-09-26.json`.

Zero supply rejects a one-unit redemption. Exact ceil funding of that empty book leaves balance 0. No sweep runs. Supply 1 redeems the one-shot floor and leaves dust 0 or 1.

`CX-FP-SETTLEMENT-001` reproduces at decimals 6, 8, and 18. Supply 2 and payout D-1: two 1-unit per-call redemptions pay 0, the one-shot floor is 1, required funding is 2, and sweepable dust is 2. The same per-call underpayment appears on 48 cells. The smallest cell in this domain is supply 2, decimals 18, payout D/2 = 5*10^17, which pays 0 against one-shot 1. That is the same defect, not a new economic rule. The candidate cumulative floor matches the one-shot floor on every cell, and the ceil residual stays in {0, 1}.

Classification of this matrix: `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN`. Canonical MATH-1 stays FAIL.

## 11. Zero-supply settlement dust — 2026-09-26

This section records the existing residual. It does not mark MATH-1 PASS and it does not add a sweep.

The bound is `ceil(n/d) - floor(n/d)` for `n >= 0` and `d > 0`. Z3 5.1.0 reports unsat for a gap outside {0, 1}. Under exact ceil funding the cumulative candidate pays the one-shot floor and leaves that gap in the book. Runtime 0.018452s. Evidence: `evidence/research/prism/zero-supply-dust-2026-09-26.json`.

| Case | Existing behavior | Residual |
|---|---|---|
| Constructed at supply 0 | Python `CumulativeFloorSettlement` and `FixedPointSettlement` accept supply 0. All 24 precision-boundary zero-supply cells fund at ceil 0, reject a one-unit redemption, and leave balance 0. `sweepable_dust()` reads 0 and leaves the balance in place. The Solidity constructor reverts `ZeroSupply`. | 0, unwithdrawn |
| Supply reaches 0 after full redemption | Supply 2, payout `10^18-1`, decimals 18, exact ceil funding 2. Cumulative redemptions pay 0 then 1. Supply is 0 and `balance_raw` is 1. A later `make_redeemable` and `redeem(1)` leave that 1 in place. Payout 0 leaves 0. Funding 5, three above the ceil, leaves 4. That 4 is surplus outside the exact-ceil bound, and it also stays. The canonical per-call book still pays 0 and 0, and `sweepable_dust()` reads 2 without moving it. That read remains `CX-FP-SETTLEMENT-001`. | 0 or 1 at exact ceil funding; it sits |
| One-unit redemption at supply 0 | Python cumulative `redeem` raises `unknown holder` on an empty book and `invalid candidate redemption quantity` after depletion. Canonical `redeem(1)` raises `invalid settlement redemption quantity`. Solidity `redeem(1)` after depletion reverts `InvalidQuantity`. The balance stays. | unchanged |

`PrismSeries.archive` changes state and leaves `settlement_balance` where it is. A zero-supply exact series rejects `redeem_final(1)`. Redeeming supply 2 against payout 1 from balance 5 pays 2, and archive leaves 3.

`FixedPointSeries.sweep_dust` zeros component `backing_raw`. On supply 0 and backing 2 it returns 2 and leaves backing 0. That movement is component backing, not the settlement residual.

`CandidateCumulativeSettlement` has one `safeTransfer`. It sends the redeem payout when that payout is nonzero. Forge 1.8.3, solc 0.8.26, optimizer 200, via IR off: 4 passed, 0 failed. The empty constructor reverts `ZeroSupply`. The exact-ceil book ends with token balance 1. A further redeem reverts and the balance stays 1.

Sweep policy: `NOT_YET_VALIDATED`. Residual bound: `PROVEN_UNDER_ASSUMPTIONS`. Extraction witness: none. Canonical MATH-1 stays FAIL. The kernel stays `differential_research_kernel`.

## 12. Candidate settlement stateful invariants — 2026-09-26

This section does not mark MATH-1 PASS, does not change the payout, and does not add a sweep. Sweep policy stays `NOT_YET_VALIDATED`.

`CandidateCumulativeSettlementInvariantTest` targets three handlers: `fund` (mint the settlement token into the book), `makeRedeemable`, and `redeem` with quantity bounded by the caller's balance. Known revert paths return before the call. `fail_on_revert` is false. The book is supply 8, holder amounts 3 and 5, payout `10^18-1`, decimals 18.

| Invariant | Check |
|---|---|
| `invariant_redeemedSupplyNeverExceedsConstructed` | `redeemedUnits <= initialSupply` |
| `invariant_eachRedeemPaysCumulativeFloorDelta` | `paidRaw` equals `floor(redeemedUnits * payout / D)` |
| `invariant_balanceIncreasesOnlyThroughFund` | token balance equals `fundedTotal - paidRaw` |
| `invariant_fullRedemptionLeftoverMatchesFunding` | after the constructed supply is fully redeemed, the leftover equals funding minus total paid |
| `invariant_exactCeilLeftoverIsZeroOrOne` | when that funding equals the exact ceil and the supply is fully redeemed, the leftover is 0 or 1 |

A warmup of 32 runs and depth 16 passed on seeds 20260926 and 20260927: 512 calls, 0 reverts. The recorded campaign is 256 runs and depth 128 on the same seeds: 32768 calls, 0 reverts, 0 discards. Forge 1.8.3, solc 0.8.26, optimizer 200, via IR off. Both seeds passed. No counterexample. Evidence: `evidence/research/prism/candidate-settlement-invariant-2026-09-26.json`. The kernel stays `differential_research_kernel`. Canonical MATH-1 stays FAIL.

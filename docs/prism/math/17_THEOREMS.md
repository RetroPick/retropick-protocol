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
final zero-supply settlement-dust policy
fixed-point partial-resolution transform if required onchain
Z3/SymPy proof artifacts where useful
live Kuru LP/MM/fee-domain separation checks
Foundry differential + stateful invariant suite
```

If any of those exposes a counterexample, theorem/assumption status must be downgraded and the economic model revisited.

---

## 7. MATH-1 gate

Exact/accounting theorem set now includes:

```text
T-REPL-001
T-BS-001..004
T-ALLOC-001
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

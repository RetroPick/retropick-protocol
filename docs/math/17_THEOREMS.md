# 17 — Theorem, Counterexample, and Market-Hypothesis Registry

**Status:** CANONICAL MATH-1 CLAIM REGISTRY  
**Purpose:** distinguish deductive protocol properties from bounded evidence and empirical market claims.

Allowed statuses:

```text
PROVEN_UNDER_ASSUMPTIONS
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
SUPPORTED_BY_SIMULATION
SUPPORTED_BY_LIVE_EVIDENCE
NOT_YET_VALIDATED
COUNTEREXAMPLE_FOUND
```

A claim may have a mathematical status and a separate executable-coverage status. Exact algebra being proven does not mean the future fixed-point Solidity implementation is already proven.

---

## 1. Core theorem registry

| ID | Claim | Scientific status | Key assumptions | Proof / source | Python oracle / evidence | Production implication |
|---|---|---|---|---|---|---|
| `T-REPL-001` | For admitted basket `x`, terminal payoff is exactly `h=Gx` | `PROVEN_UNDER_ASSUMPTIONS` | A-P02 | `01_DEFINITIONS.md`; protocol math model | `replication.payoff()` | Series admission must commit immutable `G/x` semantics or equivalent hashes |
| `T-BS-001` | Valid exact-backed mint preserves `B_i >= Sx_i` and preserves margin `M_i` | `PROVEN_UNDER_ASSUMPTIONS` | A-P02, A-P03, A-P04 | `05_BACKING_SOLVENCY.md#2` | `PrismSeries.mint()`, `mint_with_exact_backing()`, bounded verifier | Backing-first mint; integer version still requires MATH-1D |
| `T-BS-002` | Valid in-kind redemption preserves backing and margin | `PROVEN_UNDER_ASSUMPTIONS` | A-P02, A-P03, A-P04 | `05_BACKING_SOLVENCY.md#3` | `redeem_in_kind()`, bounded verifier | Liability reduction and conservative release ordering |
| `T-BS-003` | Exact non-negative replication + component backing implies terminal solvency in every modeled world | `PROVEN_UNDER_ASSUMPTIONS` | A-P01, A-P02, A-P03 | `05_BACKING_SOLVENCY.md#4` | `terminal_solvency()`, `terminal_backing_value()`, terminal bounded verifier | Runtime component check is sufficient; no world enumeration in mint |
| `T-BS-004` | If `C_s >= SR`, correct final redemption preserves funding for remaining supply | `PROVEN_UNDER_ASSUMPTIONS` | A-P05, A-P06 | `05_BACKING_SOLVENCY.md#5` | `settlement_is_funded()`, `make_redeemable()`, `redeem_final()`, bounded verifier | `RESOLVED != REDEEMABLE`; funding gate is mandatory |
| `T-NATIVE-001` | Under canonical split/merge semantics, `YES_supply = NO_supply = CollateralLocked` is conserved | `PROVEN_UNDER_ASSUMPTIONS` mathematically; executable state model `NOT_YET_VALIDATED` | A-N01, A-N02, A-P04 | protocol invariants + definitions | static helpers only; stateful native model missing | Native complete-set contract requires stateful conservation tests |
| `T-NATIVE-002` | For valid binary terminal states, `YES(omega)+NO(omega)=1` | `PROVEN_UNDER_ASSUMPTIONS` | A-N03, A-P05 | definition of accepted binary payoff basis | representable through payoff fixtures | Resolution adapters must conform to accepted invalid/void policy |
| `T-LC-001` | Canonical PRISM lifecycle has no transition from terminal/settlement states back to issuance | `PROVEN_UNDER_ASSUMPTIONS` for declared transition graph | immutable lifecycle graph | protocol state machine | `lifecycle._ALLOWED`, `transition()` | Foundry stateful invariant must preserve acyclic/monotone state progression |
| `T-LC-002` | Final resolution cannot be committed twice through the canonical model transition path | `PROVEN_UNDER_ASSUMPTIONS` | canonical transition graph | protocol state machine | `PrismSeries.resolve()` only from `RESOLUTION_PENDING` | Final result immutable after resolution |
| `T-PARTIAL-001` | Given final resolved values and supplied marks for unresolved components, basket NAV decomposes linearly by resolved/unresolved sets | `PROVEN_UNDER_ASSUMPTIONS` | A-R02, A-M04 | protocol math model | `market_math.partial_resolution_nav()` | Valuation identity only; does not authorize backing transformation by itself |
| `T-QUOTE-001` | After final payout `R` is fixed, idealized PRISM/quote relative value is `R/P_Q` before costs/risk | `PROVEN_UNDER_ASSUMPTIONS` as algebraic relative-value identity | A-P05, A-M04 | protocol math model | `market_math.post_resolution_pair_value()` | Does not guarantee exchange price or liquidity |

---

## 2. Replication counterexamples

### CX-REPL-001 — Marginal binary claims do not generally span conjunction payoffs

Define:

```math
A=(0,0,1,1)
```

```math
B=(0,1,0,1)
```

and desired conjunction:

```math
h_{AND}=(0,0,0,1)
```

Any non-negative combination is:

```math
xA+yB=(0,y,x,x+y)
```

Matching coordinate 2 requires `y=0`. Matching coordinate 3 requires `x=0`. Then coordinate 4 is `0`, not `1`.

Therefore:

```math
\boxed{h_{AND}\notin\mathcal C}
```

for this component basis.

**Status:** `COUNTEREXAMPLE_FOUND`

**Oracle mapping:** `find_exact_nonnegative_replication()` returns no exact non-negative solution for this fixture; corresponding regression test must remain canonical.

**Protocol consequence:** Phase 1 must reject unsupported nonlinear desired payoffs rather than pretending weighted marginal claims replicate them.

---

## 3. Bounded verification claims

The following are not substitutes for universal algebraic proofs. They test the executable oracle across declared finite domains.

| ID | Property | Evidence function | Status rule |
|---|---|---|---|
| `E-BND-001` | Mint/redeem backing preservation over bounded supply, quantity and surplus grid | `verify_mint_redeem_grid()` | `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN` only after a run records its bounds and succeeds |
| `E-BND-002` | Terminal solvency across every terminal world for bounded supply/surplus grid | `verify_terminal_solvency_grid()` | same |
| `E-BND-003` | Settlement funding preservation across bounded supply/redemption grid | `verify_settlement_redemption_grid()` | same |

The algebraic theorem status remains independent of whether a particular bounded run has been executed recently.

---

## 4. Fixed-point theorem transfer status

Exact-rational theorems do **not** automatically imply the integer Solidity implementation is safe.

Current candidate policy:

```text
required backing -> ceil
release amount    -> floor
```

Current implementation support exists in `fixed_point.py`, but production-equivalent theorem transfer remains:

```text
NOT_YET_VALIDATED
```

until MATH-1D closes:

- token decimal normalization;
- ceil/floor rules for every operation;
- dust bound;
- repeated-cycle extraction search;
- Solidity-compatible fixtures;
- proof that integer post-state implies accepted solvency inequality.

Proposed future theorem IDs:

```text
T-FP-001 integer mint cannot underreserve backing
T-FP-002 integer redemption cannot overrelease backing
T-FP-003 final settlement rounding cannot overpay aggregate liability
T-FP-004 repeated mint/redeem rounding has no positive extraction above accepted bound
```

All remain `NOT_YET_VALIDATED` today.

---

## 5. Accounting claims not yet fully modeled

### T-ALLOC-001 — Global reservation uniqueness

Claim:

> the same reserved economic units cannot simultaneously secure two independent PRISM liabilities.

Scientific status:

```text
NOT_YET_VALIDATED
```

Reason: the current Python oracle is series-local and has no global reservation ledger.

This is a hard `CONTRACT-ARCH-1` requirement and must receive executable/stateful coverage before production.

### T-PARTIAL-002 — Payoff-equivalent stateful backing transformation

Claim:

> replacing a finalized component with settlement collateral preserves all remaining obligations when the replacement equals the component's canonical resolved value under accepted precision rules.

Scientific status:

```text
NOT_YET_VALIDATED
```

Reason: `partial_resolution_nav()` evaluates a mixed resolved/unresolved basket but the model does not yet mutate backing representations and prove before/after liability equivalence.

---

## 6. Market hypotheses: explicitly not protocol theorems

### H-MKT-001 — Arbitrage closes PRISM/NAV divergence quickly

Reference relations:

```math
C_{create}=\sum_i x_iAsk_i+F_{create}
```

```math
V_{redeem}=\sum_i x_iBid_i-F_{redeem}
```

A persistent market price outside executable create/redeem economics can create an arbitrage incentive.

It does **not** follow mathematically that participants will execute, that depth is adequate, or that convergence is fast.

**Status:** `NOT_YET_VALIDATED`

Required evidence: agent-based/orderbook simulation, then live Kuru measurements.

### H-MKT-002 — PRISM market makers are sustainably profitable

Depends on spreads, flow, inventory, hedging costs, resolution jumps, stale orders, gas and competition.

**Status:** `NOT_YET_VALIDATED`

Required evidence: market-maker simulation and live trading evidence.

### H-LIQ-001 — Kuru markets have adequate depth and acceptable spreads

Contract deployment alone does not establish liquidity.

**Status:** `NOT_YET_VALIDATED`

Required evidence: live market IDs, books, quoted depth, spreads, fills and persistence over time.

### H-ADOPT-001 — Users want to trade/own programmable outcome assets

Protocol correctness does not prove demand.

**Status:** `NOT_YET_VALIDATED`

Required evidence: user research, real trading sessions, creator demand, retention/volume metrics.

---

## 7. Claims that must never be upgraded by wording alone

The following transitions are prohibited without new evidence:

```text
NOT_YET_VALIDATED
-> PROVEN_UNDER_ASSUMPTIONS
```

merely because:

- a simulation looks plausible;
- a sponsor integration exists;
- a demo trade succeeds once;
- a price happened to converge;
- an LLM/research report asserts the behavior.

Likewise:

```text
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
```

must never be reported as proof over an unbounded domain unless a deductive argument exists.

---

## 8. MATH-1 theorem gate

Before `MATH-1` can close for the accounting kernel:

### Required exact theorems

```text
T-REPL-001
T-BS-001
T-BS-002
T-BS-003
T-BS-004
```

must remain internally consistent with:

```text
docs/protocol/
docs/math/
research/prism-model/
```

### Required implementation-equivalence work

```text
T-FP-001..004
```

must be resolved or bounded sufficiently for the intended Solidity semantics.

### Required known gaps to resolve or explicitly scope out

```text
T-ALLOC-001
T-PARTIAL-002
```

cannot silently be called proven.

### Market claims

`H-MKT-*`, `H-LIQ-*`, `H-ADOPT-*` remain separate from accounting safety and may stay empirical after production accounting is proven.

---

## 9. Traceability rule

Every future theorem or economic claim added to the repository must record:

```text
ID
statement
status
assumptions
proof/reference
oracle mapping
bounded/simulation/live evidence
implementation consequence
known counterexample/failure boundary
```

This registry is the canonical place to answer:

> What exactly do we know, why do we know it, and what remains merely hypothesized?

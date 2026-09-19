# PRISM Claim Registry

**Status:** CANONICAL PROTOCOL-LEVEL MATH-1 TRACKER

Every important claim must have a type and evidence status. Do not use stronger language than the status permits.

For detailed theorem dependencies, proof locations, Python-oracle mapping, counterexamples and empirical hypotheses, use:

```text
docs/prism/math/17_THEOREMS.md
```

`docs/prism/protocol/CLAIMS.md` is the concise protocol claim index. `docs/prism/math/17_THEOREMS.md` is the detailed proof/evidence registry. They must not contradict each other.

| ID | Claim | Type | Current status | Evidence / next gate |
|---|---|---|---|---|
| C-001 | `h=Gx` is the terminal payoff of an exact basket | formal/definition | `PROVEN_UNDER_ASSUMPTIONS` | `MATH_MODEL.md`, `docs/prism/math/17_THEOREMS.md` |
| C-002 | Valid exact-backed mint preserves component solvency | formal | `PROVEN_UNDER_ASSUMPTIONS` | `docs/prism/math/05_BACKING_SOLVENCY.md` |
| C-003 | Valid in-kind redemption preserves component solvency | formal | `PROVEN_UNDER_ASSUMPTIONS` | `docs/prism/math/05_BACKING_SOLVENCY.md` |
| C-004 | Exact non-negative component backing implies terminal solvency | formal | `PROVEN_UNDER_ASSUMPTIONS` | `docs/prism/math/05_BACKING_SOLVENCY.md` |
| C-005 | Final redemption preserves funding for remaining supply | formal | `PROVEN_UNDER_ASSUMPTIONS` | `docs/prism/math/05_BACKING_SOLVENCY.md` |
| C-006 | Arbitrary AND payoff is not always in the long-only span of marginal claims | formal counterexample | `COUNTEREXAMPLE_FOUND` | `docs/prism/math/17_THEOREMS.md`, canonical AND fixture |
| C-007 | `Fed=YES, BTC=NO` pays `1.00` for canonical `0.6 FED_YES + 0.4 BTC_NO` | exact fixture | `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN` | payoff vector fixture |
| C-008 | Same-chain BackingMirror is unnecessary for Phase-1 solvency accounting | architecture | `ACCEPTED` | ADR-003 |
| C-009 | Component-wise runtime checks are sufficient after exact admission under Phase-1 assumptions | formal/architecture | `PROVEN_UNDER_ASSUMPTIONS` | ADR-004 + `T-BS-003` |
| C-010 | Complete-set OI is not `YES_supply + NO_supply` in the simple fully collateralized model | accounting identity | `PROVEN_UNDER_ASSUMPTIONS` | native complete-set model/static helpers; stateful native oracle still incomplete |
| C-011 | Split-and-sell arbitrage uses executable YES/NO bids | market identity | `PROVEN_UNDER_ASSUMPTIONS` given quotes/costs | `market_math.py` |
| C-012 | Buy-and-merge arbitrage uses executable YES/NO asks | market identity | `PROVEN_UNDER_ASSUMPTIONS` given quotes/costs | `market_math.py` |
| C-013 | PRISM creation cost is component ask-weighted cost plus fees | executable valuation definition | `PROVEN_UNDER_ASSUMPTIONS` given executable asks | `market_math.py` |
| C-014 | PRISM in-kind liquidation value is component bid-weighted value minus fees | executable valuation definition | `PROVEN_UNDER_ASSUMPTIONS` given executable bids | `market_math.py` |
| C-015 | Permissionless create/redeem tends to bound persistent mispricing | market behavior | `NOT_YET_VALIDATED` | MATH-1F / live Kuru evidence |
| C-016 | PRISM price will always remain inside create/redeem reference band | market behavior | `REJECTED` as unconditional claim | latency/depth/capital can violate temporarily |
| C-017 | A resolved PRISM/volatile-ERC20 pair can continue moving because quote asset moves | relative-price identity | `PROVEN_UNDER_ASSUMPTIONS` | `R/P_Q` model |
| C-018 | A zero-payout resolved claim has zero protocol redemption value | protocol/economic | `PROVEN_UNDER_ASSUMPTIONS` | settlement definition |
| C-019 | Kuru deployment automatically creates useful liquidity | market behavior | `REJECTED` | liquidity must be seeded/quoted |
| C-020 | Market makers can sustainably quote through resolution jumps | market behavior | `NOT_YET_VALIDATED` | simulation/live evidence |
| C-021 | Users want to trade PRISM at meaningful scale | product/behavior | `NOT_YET_VALIDATED` | user/live demand evidence |
| C-022 | External wrapped prediction positions can be made production-safe | future architecture | `NOT_YET_VALIDATED` | separate cross-chain spec/bridge proof |
| C-023 | Attestation alone is equivalent to collateral custody | architecture | `REJECTED` | external backing requires actual lock/control |
| C-024 | Passkey onboarding is equivalent to legal identity/KYC | product/legal | `REJECTED` | requires independent identity/compliance layer |
| C-025 | Same reserved units cannot back two independent liabilities system-wide | accounting/global reservation | `NOT_YET_VALIDATED` in current single-series oracle | `docs/prism/math/16_INVARIANTS.md`, `T-ALLOC-001` |
| C-026 | Stateful partial-resolution backing replacement preserves all remaining liabilities | accounting/transformation | `NOT_YET_VALIDATED` | `docs/prism/math/16_INVARIANTS.md`, `T-PARTIAL-002` |
| C-027 | Candidate fixed-point rounding inherits exact-rational solvency theorems | implementation equivalence | `NOT_YET_VALIDATED` | MATH-1D, `T-FP-001..004` |

---

## Claim status meanings

### `PROVEN_UNDER_ASSUMPTIONS`
Deductive result from explicit assumptions.

### `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN`
Checked for every state/input in a declared finite domain.

### `SUPPORTED_BY_SIMULATION`
Observed in synthetic experiments only.

### `SUPPORTED_BY_LIVE_EVIDENCE`
Observed in actual deployed integrations/users/markets under documented conditions.

### `NOT_YET_VALIDATED`
Plausible/open, but evidence is insufficient.

### `COUNTEREXAMPLE_FOUND`
A universal claim is false; concrete counterexample exists.

### `REJECTED`
The architecture/research program explicitly does not accept the claim as stated.

---

## Update rule

A claim may move to a stronger status only when the corresponding evidence artifact exists. A successful demo does not automatically promote a market-behavior claim to a theorem.

Any theorem-status change must also update `docs/prism/math/17_THEOREMS.md` when the claim has a theorem/hypothesis entry.

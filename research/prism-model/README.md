# PRISM Exact Reference Model

This directory is the **semantic reference implementation** for RetroPick/PRISM MATH-1.

It separates protocol accounting from market behavior:

```text
ACCOUNTING / SOLVENCY KERNEL
  exact payoff + backing + lifecycle + settlement

GLOBAL / STATEFUL SAFETY
  native complete sets + cross-series reservations + partial resolution

FIXED-POINT TRANSFER
  integer backing + decimal normalization + settlement rounding

MARKET MATH
  complete-set parity + executable NAV relations + quote-pair identities
```

Market math must not be confused with protocol safety.

## Proof-layer relationship

```text
docs/prism/protocol/    economic semantics
      ↓
docs/prism/math/        definitions, assumptions, proofs, theorem/invariant registry
      ↓
research/prism-model/   executable semantic oracle
      ↓
contracts/        future implementation
```

Canonical math documents:
- `../../docs/prism/math/01_DEFINITIONS.md`
- `../../docs/prism/math/02_ASSUMPTIONS.md`
- `../../docs/prism/math/05_BACKING_SOLVENCY.md`
- `../../docs/prism/math/16_INVARIANTS.md`
- `../../docs/prism/math/17_THEOREMS.md`

## Files

- `model.py`: PRISM series state, exact backing, mint/redeem, partial-resolution transformation and final settlement.
- `lifecycle.py`: legal PRISM state transitions.
- `replication.py`: payoff matrices, exact payoff construction and small-system replication solver.
- `settlement.py`: exact terminal backing/settlement helpers.
- `reservation_ledger.py`: global reservation ledger preventing double allocation of physical backing across series.
- `native_market.py`: stateful fully collateralized binary complete-set split/merge/resolve/redeem model.
- `fixed_point.py`: primitive integer rounding helpers.
- `fixed_point_model.py`: WAD/per-token-decimal backing, conservative redemption, binary terminal-solvency and final-settlement model.
- `adversarial.py`: deterministic randomized stress runners for fixed-point and reservation invariants.
- `market_math.py`: complete-set bid/ask parity, PRISM create/redeem values, partial-resolution NAV and post-resolution quote ratio.
- `bounded_verification.py`: finite-domain exact mint/redeem/solvency/settlement checks.
- `scenarios.py`: deterministic human-readable examples.
- `tests/`: unit, counterexample, gap, randomized and regression tests.

## Canonical equations

Admission:

```math
h=Gx
```

Runtime exact backing:

```math
B_i\ge Sx_i
```

Global reservation:

```math
\sum_s Reserved_{s,a}\le PhysicalBalance_a
```

Final funding:

```math
SettlementBalance\ge Supply\times FinalPayout
```

Native active complete-set conservation:

```math
YES_{supply}=NO_{supply}=CollateralLocked
```

## Precision policy under executable validation

Phase-1 candidate integer semantics use:

```text
series scale: 1e18
supported component decimals: 0..18
backing requirement: ceil exact requirement into raw token units
redemption release: old conservative requirement - new conservative requirement
final settlement requirement: ceil aggregate liability
per-redemption cash payout: floor payout
residual dust: never sweep while supply/liability remains
```

The requirement-delta redemption rule is stronger than blindly applying `floor(Q*x)` per call: it directly guarantees the post-redemption backing requirement remains satisfied despite token-decimal granularity.

## Run

```bash
python -m unittest discover -s tests -v
python scenarios.py
python adversarial.py
```

A bounded or randomized run is evidence over its declared domain, not a universal proof.

## Scientific classification

```text
PROVEN_UNDER_ASSUMPTIONS
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
SUPPORTED_BY_SIMULATION
SUPPORTED_BY_LIVE_EVIDENCE
NOT_YET_VALIDATED
COUNTEREXAMPLE_FOUND
```

`docs/prism/math/17_THEOREMS.md` remains the canonical theorem/hypothesis registry.

## Current oracle coverage

Now modeled executable safety properties include:

```text
exact payoff h=Gx
exact/non-negative replication
component backing and back-first mint
in-kind redemption
terminal solvency
PRISM lifecycle monotonicity
final settlement funding/redemption
stateful native complete-set split/merge/resolve/redeem
global cross-series backing reservation uniqueness
stateful partial-resolution component -> settlement transformation
mixed component/cash redemption after partial resolution
6/18-decimal normalized fixed-point backing
fixed-point binary terminal solvency
fixed-point final-settlement funding preservation
deterministic randomized reservation/fixed-point stress runners
```

Still outside the executable proof boundary:

```text
live Kuru/LP/MM accounting-domain separation
production Solidity equivalence
formal solver proof artifacts (Z3/SymPy)
market depth, arbitrage speed, MM profitability and user demand
cross-chain wrapped outcomes
```

The accounting kernel must remain correct even if exchange liquidity or arbitrage participation is zero.

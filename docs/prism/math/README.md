# PRISM Mathematical Proof Layer

**Status:** CANONICAL MATH-1 PROOF LAYER  
**Scope:** RetroPick native complete-set accounting + PRISM Phase-1 exact-backed structured assets  
**Protocol semantics:** `../protocol/`  
**Executable oracle:** `../../research/prism-model/`

---

## 1. Purpose

`docs/prism/math/` explains **why** the canonical protocol semantics are mathematically valid under explicit assumptions.

The repository layers are intentionally separate:

```text
docs/prism/protocol/
  WHAT the protocol means
        |
        v
docs/prism/math/
  WHY the semantics are valid
        |
        v
research/prism-model/
  EXECUTABLE semantic oracle
        |
        v
contracts/
  future Solidity implementation
```

This folder does not redefine product semantics. If a proof requires changing protocol behavior, update the protocol specification through the accepted ADR/change-control process first.

---

## 2. Authority and conflict resolution

When artifacts disagree:

1. accepted ADRs define approved architecture changes;
2. `docs/prism/protocol/` defines canonical economic/protocol semantics;
3. `docs/prism/math/` defines derivations, theorem dependencies and proof classification for those semantics;
4. `research/prism-model/` must execute those semantics exactly;
5. future Solidity must match the accepted semantics under the approved fixed-point tolerance;
6. simulations/live market evidence may validate behavior but cannot repair an accounting contradiction.

A model/test mismatch with an accepted theorem is an investigation trigger, not permission to silently rewrite the theorem.

---

## 3. Scientific status language

Every substantive claim must use one of these statuses:

```text
PROVEN_UNDER_ASSUMPTIONS
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
SUPPORTED_BY_SIMULATION
SUPPORTED_BY_LIVE_EVIDENCE
NOT_YET_VALIDATED
COUNTEREXAMPLE_FOUND
```

Passing unit tests alone is not a universal proof.

A market simulation cannot promote a protocol safety property from false to true.

---

## 4. Canonical Phase-1 mathematical boundary

PRISM Phase 1 is an exact-backed, non-negative replication system.

Admission:

```math
h=Gx
```

or, for a target payoff:

```math
Gx=h^*,\qquad x\ge0
```

Runtime backing:

```math
B_i\ge Sx_i
```

Final settlement funding:

```math
SettlementBalance\ge Supply\times FinalPayout
```

The feasible long-only payoff set is:

```math
\mathcal C=\{Gx\mid x\ge0\}
```

Phase 1 does not claim that arbitrary nonlinear payoffs are representable.

---

## 5. Documents

- `01_DEFINITIONS.md` — one canonical meaning for every mathematical/accounting symbol.
- `02_ASSUMPTIONS.md` — normalized assumption register and theorem-dependency matrix.
- `05_BACKING_SOLVENCY.md` — formal backing, mint, redemption, terminal-solvency and settlement-funding derivations.
- `16_INVARIANTS.md` — engineering invariant registry with Python-oracle traceability and future Solidity targets.
- `17_THEOREMS.md` — theorem/counterexample/hypothesis registry with scientific status.

Numbering intentionally follows the larger MATH-1 deliverable plan; missing numbers are future math documents, not missing protocol requirements.

---

## 6. Reference-model contract

The exact Python model is the semantic oracle before Solidity exists.

Current core files:

```text
research/prism-model/
  model.py
  replication.py
  lifecycle.py
  settlement.py
  market_math.py
  bounded_verification.py
  fixed_point.py
  scenarios.py
  tests/
```

The accounting/solvency kernel must not depend on stochastic market simulation.

Market failure must not invalidate solvency:

```text
zero Kuru liquidity
arbitrageurs absent
market maker offline
large secondary-market mispricing
```

must not by themselves create unbacked protocol liabilities.

---

## 7. MATH-1 proof workflow

```text
DEFINITIONS
  -> ASSUMPTIONS
  -> PROOFS
  -> INVARIANT TRACEABILITY
  -> THEOREM REGISTRY
  -> BOUNDED / ADVERSARIAL VERIFICATION
  -> FIXED-POINT PROOF
  -> MATH-1 VERDICT
  -> CONTRACT-ARCH-1
```

Production Solidity remains blocked until the MATH-1 accounting gates close and `CONTRACT-ARCH-1` translates the accepted invariants into storage, interfaces, authorization, events and Foundry/differential tests.

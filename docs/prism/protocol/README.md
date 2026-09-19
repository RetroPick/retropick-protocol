# Canonical Protocol Documents

These files define RetroPick/PRISM financial semantics before Solidity.

## Read order

1. `PRISM_PROTOCOL_SPEC.md` — Phase-1 financial objects and boundaries.
2. `ASSUMPTIONS.md` — canonical protocol/accounting assumptions.
3. `MATH_MODEL.md` — protocol-level exact payoff/backing/settlement mathematics.
4. `CLAIMS.md` — claim type/status/evidence registry at protocol level.
5. `INVARIANTS.md` — properties implementation must never violate.
6. `STATE_MACHINE.md` — legal lifecycle states/transitions.
7. `FAILURE_MODES.md` — kill criteria and failure classification.
8. `PRECISION_MODEL.md` — fixed-point/rounding gate before Solidity.
9. `CONTRACT_REQUIREMENTS.md` — implementation obligations derived from the model.

## Dedicated proof layer

Detailed proof normalization and executable traceability live under `../math/`:

1. `../math/01_DEFINITIONS.md` — canonical notation.
2. `../math/02_ASSUMPTIONS.md` — theorem dependency matrix using the assumption IDs in this folder.
3. `../math/05_BACKING_SOLVENCY.md` — backing/mint/redeem/terminal/final-settlement proofs.
4. `../math/16_INVARIANTS.md` — invariant-to-Python-oracle traceability and known gaps.
5. `../math/17_THEOREMS.md` — theorem, counterexample and empirical-hypothesis registry.

Relationship:

```text
docs/prism/protocol/
  WHAT the accepted protocol means
        ↓
docs/prism/math/
  WHY those semantics hold mathematically
        ↓
research/prism-model/
  EXECUTABLE semantic oracle
```

The proof layer does not independently redefine protocol behavior. If a proof requires different economics, update the accepted protocol semantics through change control first.

Related architecture:
- `../04-architecture/SYSTEM_ARCHITECTURE.md`
- `../04-architecture/SMART_CONTRACTS.md`

Related execution control:
- `../05-hackathon/PHASE_GATES.md`
- `../06-execution/ROADMAP.md`

Historical-report reconciliation:
- `../00-context/REPORT_RECONCILIATION.md`

## Authority rule

Implementation must not silently contradict these files.

If code requires different economics:
1. stop implementation;
2. document the changed assumption;
3. write/supersede an ADR;
4. update the proof layer and reference model;
5. re-run the affected gate.

The implementation is downstream of the model, not a competing source of truth.

# Documentation System

The documentation tree separates context, research, product, protocol semantics, mathematical proofs, architecture, hackathon execution, validation, evidence and pitch.

## Authority layers

```text
docs/protocol/
  canonical financial/protocol semantics
      ↓
docs/math/
  canonical proof layer for those semantics
      ↓
research/prism-model/
  executable semantic oracle
      ↓
contracts/
  future production implementation
```

`docs/protocol/` answers **what the protocol means**.

`docs/math/` answers **why the accepted semantics are mathematically valid**, under which assumptions, and which claims remain empirical or unproven.

`docs/03-protocol/` contains broader product-protocol documentation and links to the canonical Phase-1 files.

Research does not become protocol truth until accepted through an ADR/spec update.

## Math proof entry points

Read:

1. `math/README.md`
2. `math/01_DEFINITIONS.md`
3. `math/02_ASSUMPTIONS.md`
4. `math/05_BACKING_SOLVENCY.md`
5. `math/16_INVARIANTS.md`
6. `math/17_THEOREMS.md`

The theorem registry deliberately distinguishes:

```text
PROVEN_UNDER_ASSUMPTIONS
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
SUPPORTED_BY_SIMULATION
SUPPORTED_BY_LIVE_EVIDENCE
NOT_YET_VALIDATED
COUNTEREXAMPLE_FOUND
```

A simulation or successful demo does not override a failed accounting theorem.

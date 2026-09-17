# Current Goal

**Goal ID:** METROPOLIS-P1-MATH-1  
**Status:** ACTIVE  
**Phase:** SPEC + MATH

## Objective

Freeze the PRISM replicated-asset protocol semantics and produce an executable exact-arithmetic reference model that can later serve as the oracle for Solidity differential testing.

## Mandatory outputs

- `docs/protocol/PRISM_PROTOCOL_SPEC.md`
- `docs/protocol/INVARIANTS.md`
- `docs/protocol/STATE_MACHINE.md`
- `docs/protocol/MATH_MODEL.md`
- `docs/protocol/FAILURE_MODES.md`
- `docs/protocol/CONTRACT_REQUIREMENTS.md`
- `research/prism-model/model.py`
- `research/prism-model/lifecycle.py`
- `research/prism-model/replication.py`
- `research/prism-model/settlement.py`
- `research/prism-model/scenarios.py`
- `research/prism-model/tests/`

## Acceptance

- exact payoff evaluation works;
- replication admission/rejection works for finite matrices;
- valid mint preserves component backing;
- valid in-kind redeem preserves component backing;
- terminal solvency is checked for every enumerated world;
- illegal lifecycle transitions fail;
- settlement cannot become redeemable without enough funded collateral;
- known non-replicable AND counterexample is tested;
- no production Solidity is added.

## Out of scope

- arbitrary StatePool/SLE;
- production external-market bridge;
- production Kuru integration;
- production oracle/CRE implementation;
- frontend implementation.

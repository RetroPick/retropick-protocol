# Working Decisions

Accepted ADRs under `decisions/` are authoritative. This file is the agent-readable summary.

## Prediction / PRISM locked decisions

- **D-001:** Protocol development is math-first. Production Prediction/PRISM Solidity remains blocked until its MATH-1 and CONTRACT-ARCH-1 gates.
- **D-002:** PRISM Metropolis MVP supports non-negative exact replication, not arbitrary nonlinear payoff creation.
- **D-003:** Canonical feasible payoff set is `C = {Gx | x >= 0}`.
- **D-004:** Exact basket mode may supply `x` directly and compute `h=Gx`; payoff mode solves exact `Gx=h, x>=0` or rejects.
- **D-005:** Component-wise backing `B_i >= S*x_i` is the primary runtime active-series invariant.
- **D-006:** Same-chain Monad backing is authoritative; no Phase-1 BackingMirror.
- **D-007:** Native prediction-market creation and PRISM-series creation are separate pipelines.
- **D-008:** Backing collateral, LP inventory, market-maker inventory, fees and settlement funds are separate accounting domains.
- **D-009:** `RESOLVED` and `REDEEMABLE` are distinct settlement states.

## Modern Launchpad locked decision

- **D-016:** RetroPick Launchpad V1 is the stable/reference generation. V2 is the active modern-launchpad development generation. Launchpad work follows the independent `LP-*` documentation, architecture, security and release gates.

## Escalation rule

If a task needs to contradict a locked decision, write a new ADR that explicitly supersedes the old decision and update all affected specifications and gates before implementation.

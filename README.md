# RetroPick Protocol

Protocol, market-structure, mathematical reference-model, and hackathon delivery repository for **RetroPick + PRISM** on Monad.

## Current phase

**Phase 1: SPEC + MATH**

Phase 1 freezes the financial semantics before production Solidity is written:

1. canonical protocol specification;
2. exact reference model;
3. lifecycle/state-machine definition;
4. solvency and conservation invariants;
5. replication feasibility model;
6. failure modes and kill criteria;
7. deterministic test vectors;
8. contract requirements derived from proven properties.

Production smart-contract implementation is intentionally scaffolded but gated on `MATH-1`.

## Product boundary

```text
Event
  -> RetroPick outcome assets
  -> Kuru spot market microstructure
  -> resolution/redemption

Outcome assets
  -> PRISM exact backed composition
  -> structured ERC-20 asset
  -> optional Kuru secondary market
```

RetroPick owns issuance, collateral semantics, payoff semantics, resolution rules and redemption. Kuru is an execution venue. Backing collateral is never protocol revenue or LP capital.

## Canonical entry points

- [`AGENTS.md`](AGENTS.md)
- [`.agent/CURRENT_GOAL.md`](.agent/CURRENT_GOAL.md)
- [`docs/protocol/PRISM_PROTOCOL_SPEC.md`](docs/protocol/PRISM_PROTOCOL_SPEC.md)
- [`docs/protocol/MATH_MODEL.md`](docs/protocol/MATH_MODEL.md)
- [`docs/protocol/INVARIANTS.md`](docs/protocol/INVARIANTS.md)
- [`docs/05-hackathon/RETROPICK_METROPOLIS_AGENT_DEVELOPMENT_WORKFLOW.md`](docs/05-hackathon/RETROPICK_METROPOLIS_AGENT_DEVELOPMENT_WORKFLOW.md)
- [`research/prism-model/README.md`](research/prism-model/README.md)

## Phase-1 quick start

```bash
cd research/prism-model
python -m unittest discover -s tests -v
python scenarios.py
```

The reference model uses Python's exact `Fraction` arithmetic so Phase 1 does not hide economic bugs behind floating-point rounding.

## Repository layers

```text
.agent/               agent control plane
docs/                 project truth and specifications
goals/                execution DAG
decisions/            architecture decision records
research/prism-model/ canonical economic reference model
apps/                  future product applications
packages/              future shared packages
contracts/             future Solidity implementation
scripts/               automation/deployment scaffolding
tests/                 future cross-layer/E2E tests
evidence/              reproducible evidence artifacts
```

## Non-goals in Phase 1

- no production Solidity;
- no claim that arbitrary nonlinear payoffs are replicable;
- no production-grade Polygon/Monad bridge;
- no fabricated sponsor evidence;
- no claim that simulation proves user adoption or liquidity.

## Gate

`MATH-1` must be `PASS` or an explicitly accepted `CONDITIONAL_PASS` before production contract implementation begins.

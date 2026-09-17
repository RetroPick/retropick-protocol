# AGENTS.md

This file is the mandatory repository entry point for coding/research agents.

## Mission

Build RetroPick's Monad prediction-asset protocol and PRISM structured-asset layer without allowing implementation convenience to override solvency, resolution, or backing semantics.

## Read before work

1. `.agent/CURRENT_GOAL.md`
2. `.agent/STATE.json`
3. `.agent/DECISIONS.md`
4. `docs/00-context/PROJECT.md`
5. `docs/protocol/PRISM_PROTOCOL_SPEC.md`
6. `docs/protocol/INVARIANTS.md`
7. `docs/05-hackathon/RETROPICK_METROPOLIS_AGENT_DEVELOPMENT_WORKFLOW.md`

For mathematical work also read:

- `docs/protocol/MATH_MODEL.md`
- `docs/protocol/STATE_MACHINE.md`
- `docs/protocol/FAILURE_MODES.md`
- `research/prism-model/README.md`

## Source-of-truth precedence

1. accepted ADRs under `decisions/`;
2. canonical files under `docs/protocol/`;
3. `.agent/DECISIONS.md`;
4. hackathon workflow;
5. research notes;
6. implementation.

Code must conform to the specification. Code does not silently redefine the specification.

## Phase 1 rule

Do **not** implement production Solidity during Phase 1.

Phase 1 closes only when the reference model, proofs/invariants, state machine, deterministic fixtures and contract requirements agree.

## Scientific rule

Classify claims as one of:

- `PROVEN_UNDER_ASSUMPTIONS`
- `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN`
- `SUPPORTED_BY_SIMULATION`
- `NOT_YET_VALIDATED`
- `COUNTEREXAMPLE_FOUND`

Never convert simulated market behavior into a formal proof.

## Locked protocol constraints

- PRISM V1 hackathon series are non-negative exactly backed replicated baskets.
- One PRISM share has immutable replication vector `x`.
- Active backing must satisfy `B_i >= S*x_i`.
- Mint is back-first, mint-second.
- In-kind redemption burns first and releases proportional backing.
- Exact replication is `h = Gx`.
- Feasible long-only payoff cone is `{Gx | x >= 0}`.
- Arbitrary AND/OR/custom payoffs are not assumed replicable.
- Backing collateral, LP inventory and protocol fees are separate accounting domains.
- A resolved series becomes a fixed-value redeemable claim; ERC-20 transferability may remain.
- Production Solidity is gated by MATH-1.

## Evidence rule

No goal is complete without:
- test command;
- result;
- relevant output/fixture;
- updated status;
- documented assumptions and residual risks.

## Handoff rule

Every specialist handoff must identify:
- goal ID;
- input specification;
- output files;
- invariants that may not change;
- open questions;
- evidence required.

# RetroPick Agent Router

This file is the repository-wide entry point. Keep it small. Product-specific detail lives in routed documents.

## Products

### Launchpad V2

Goal: fixed/capped ERC-20 launch -> bonding primary market -> safe graduation -> Kuru mature trading on Monad.

Read:
1. `docs/launchpad/README.md`
2. the owning canonical Launchpad spec
3. `development/launchpad/README.md`
4. the owning development lane
5. nearest local `AGENTS.md`

### Prediction + PRISM

Read:
1. `docs/prism/README.md`
2. `docs/prism/protocol/PRISM_PROTOCOL_SPEC.md`
3. `docs/prism/protocol/INVARIANTS.md`
4. `docs/prism/math/README.md`
5. PRISM phase-gate documents

Do not mix Launchpad bonding/graduation semantics with Prediction/PRISM collateral/backing/settlement semantics.

## Authority

1. accepted ADRs;
2. canonical product/protocol docs;
3. development implementation specs;
4. local AGENTS constraints;
5. task spec;
6. implementation.

Code does not silently redefine higher authority.

## Global engineering constraints

- normal user economic writes are wallet -> chain;
- backend and indexer are not economic authority;
- onchain integer values use bigint in TypeScript;
- mutable external integrations require current source/version verification;
- candidate technology choices are not binding until accepted;
- no agent may declare MAINNET_AUTHORIZED;
- no destructive scope expansion without an accepted task/ADR.

## Verification

No task is complete without exact commands/results, commit/ref, evidence path and downstream handoff where applicable.

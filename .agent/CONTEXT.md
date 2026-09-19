# Repository Context

RetroPick is a Monad-focused protocol repository with two product lanes.

## Launchpad V2

Purpose:
`fixed/capped ERC20 -> bonding primary market -> Kuru mature market`.

Current state:
- substantive V1/V2 Solidity exists;
- current V2 graduation is Uniswap-V4-oriented;
- Kuru is target architecture, not completed runtime;
- web/API/indexer/shared TS runtimes are not implemented;
- current committed Foundry tests are Doorway-focused, not Launchpad-core qualification.

Implementation control:
`development/launchpad/`.

## Prediction + PRISM

Math-first prediction and exact-backed structured-asset lane.

Current active gate:
PRISM MATH-1 remains open.

Canonical control:
`docs/prism/` + `research/prism-model/`.

## Shared infrastructure

Monad, wallets, Kuru, RPC/indexing and full-stack tooling may be shared, but financial semantics remain product-specific.

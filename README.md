# RetroPick Protocol

RetroPick is one programmable onchain **Launchpad platform** on Monad.

The repository currently contains an established Launchpad Core plus independently qualified financial modules:

~~~text
RetroPick Launchpad Platform
├── Launchpad Core        current production-engineering track
├── Prediction Markets    incubating financial module
└── PRISM                 incubating structured-markets module
~~~

The modules belong to one product platform. Their financial semantics, security invariants, and production qualification remain independent.

Start with:
- [Platform documentation](docs/platform/README.md)
- [Launchpad Core](docs/launchpad/README.md)
- [Prediction + PRISM](docs/prism/README.md)
- [Engineering agent router](AGENTS.md)

## Launchpad Core

Launchpad Core is the current production-oriented launch primitive:

~~~text
CREATE
-> fixed/capped ERC20
-> bonding primary market
-> demand/liquidity formation
-> safe graduation
-> Kuru mature market
~~~

Current repository reality remains explicit:
- substantive V1/V2 Solidity exists;
- current V2 graduation is still Uniswap-V4-oriented;
- Kuru is the target V2 mature venue, not yet a completed committed integration;
- web/API/indexer/shared TypeScript runtimes are not yet implemented;
- dedicated V2 core qualification remains required.

Start with:
- [docs/launchpad/README.md](docs/launchpad/README.md)
- [development/launchpad/README.md](development/launchpad/README.md)
- [contracts/docs/launchpad/README.md](contracts/docs/launchpad/README.md)

## Prediction and PRISM

Prediction and PRISM are **RetroPick Launchpad modules**, not separate startups or products.

They are intentionally isolated while their financial mechanisms are researched and qualified. PRISM currently remains governed by MATH-1 and CONTRACT-ARCH-1 before production Solidity can become authoritative.

Start with:
- [docs/prism/README.md](docs/prism/README.md)
- [docs/prism/00-context/EXECUTIVE_SUMMARY.md](docs/prism/00-context/EXECUTIVE_SUMMARY.md)
- [docs/prism/math/README.md](docs/prism/math/README.md)
- [research/prism-model/README.md](research/prism-model/README.md)
- [research/prism/README.md](research/prism/README.md)

## Platform rule

Shared product infrastructure should converge where safe: frontend, wallet integration, discovery, portfolio, indexing, APIs, SDK/types, observability, environment management and Kuru connectivity.

Financial semantics remain module-local.

Launchpad bonding/graduation rules do not redefine PRISM backing/settlement rules, and PRISM research cannot block or weaken the existing Launchpad Core.

A module joins the production platform only through explicit module admission and its own qualification gates.

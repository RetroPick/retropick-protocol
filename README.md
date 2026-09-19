# RetroPick Protocol

RetroPick contains two deliberately separate products on Monad:

```text
docs/
├── launchpad/   RetroPick Launchpad V2
└── prism/       Prediction + PRISM
```

Use [`docs/README.md`](docs/README.md) as the product router and [`AGENTS.md`](AGENTS.md) as the engineering-agent router.

## Launchpad V2

RetroPick Launchpad bootstraps fixed/capped ERC-20 assets through a bonding primary market and graduates successful launches into Kuru for mature secondary trading.

Start with:
- [`docs/launchpad/README.md`](docs/launchpad/README.md)
- [`development/launchpad/README.md`](development/launchpad/README.md)
- [`contracts/docs/launchpad/README.md`](contracts/docs/launchpad/README.md)

Current reality:
- substantial V1/V2 Solidity exists;
- current V2 graduation is still Uniswap-V4-oriented;
- Kuru is the target V2 mature venue, not yet a completed committed integration;
- web/API/indexer/shared TypeScript runtimes are not yet implemented;
- current committed Foundry tests are Doorway-focused, so the Launchpad core still needs dedicated V2 qualification.

## Prediction + PRISM

PRISM remains a separate math-first product lane.

Start with:
- [`docs/prism/README.md`](docs/prism/README.md)
- [`docs/prism/00-context/EXECUTIVE_SUMMARY.md`](docs/prism/00-context/EXECUTIVE_SUMMARY.md)
- [`docs/prism/protocol/PRISM_PROTOCOL_SPEC.md`](docs/prism/protocol/PRISM_PROTOCOL_SPEC.md)
- [`docs/prism/math/README.md`](docs/prism/math/README.md)
- [`research/prism-model/README.md`](research/prism-model/README.md)

PRISM production Solidity remains governed by its own MATH-1 and CONTRACT-ARCH-1 gates.

## Engineering control plane

Launchpad implementation is routed through:

```text
AGENTS.md
.kiro/steering/
.kiro/agents/
development/launchpad/
development/launchpad/control/
contracts/AGENTS.md
```

The control plane encodes requirements, component ownership, dependency edges, artifact handoffs and readiness gates so ordinary implementation tasks do not redesign the system.

## Boundary rule

Launchpad bonding/graduation semantics and PRISM backing/settlement semantics are independent. Shared chain, wallet, indexing or Kuru infrastructure does not make their financial models interchangeable.

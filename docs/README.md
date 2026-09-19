# RetroPick Documentation

RetroPick documentation is split by product.

```text
docs/
├── README.md
├── launchpad/
└── prism/
```

## Launchpad

`docs/launchpad/` is the canonical product, protocol, architecture, integration, validation, production and hackathon documentation for the Modern Launchpad:

```text
CREATE
-> fixed/capped ERC-20
-> bonding-curve primary market
-> graduation
-> Kuru mature trading
```

Start with:
- `launchpad/README.md`
- `launchpad/00-context/EXECUTIVE_SUMMARY.md`
- `../contracts/docs/launchpad/README.md`

## PRISM

`docs/prism/` is the canonical Prediction + PRISM product lane:

```text
native prediction market
-> YES / NO outcome ERC-20s
-> exact-backed PRISM structured asset
-> Kuru trading
-> resolution / settlement
```

Start with:
- `prism/README.md`
- `prism/00-context/EXECUTIVE_SUMMARY.md`
- `prism/protocol/PRISM_PROTOCOL_SPEC.md`
- `prism/math/README.md`
- `../contracts/docs/prism/README.md`

## Boundary rule

Launchpad and PRISM may share chain, wallet, indexing and exchange infrastructure, but they do not share financial semantics.

- Launchpad docs must not redefine PRISM backing, payoff, resolution or settlement.
- PRISM docs must not redefine Launchpad bonding-curve, quote-asset or graduation economics.
- Cross-product architectural decisions require explicit ADRs.

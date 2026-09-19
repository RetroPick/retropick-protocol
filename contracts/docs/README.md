# RetroPick Contract Documentation

Smart-contract documentation is split by product.

```text
contracts/docs/
├── README.md
├── launchpad/
└── prism/
```

## Launchpad

`launchpad/` documents the current RetroPick Launchpad contract generations, bonding-curve accounting, fees, quote assets, graduation and venue integration.

## PRISM

`prism/` documents the target Prediction + PRISM Solidity kernel derived from the accepted PRISM protocol and math gates.

PRISM production Solidity remains gated by the PRISM MATH-1 and CONTRACT-ARCH-1 process. Documentation in `prism/` is implementation specification, not evidence that contracts are already deployed.

## Rule

Contract documentation implements the corresponding product specification:

- Launchpad: `../../docs/launchpad/`
- PRISM: `../../docs/prism/`

Contract code cannot silently redefine either product's economics.

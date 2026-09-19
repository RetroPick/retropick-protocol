# RetroPick Launchpad Contracts

**Status:** active RetroPick launchpad contract workspace.

The Solidity package contains two RetroPick launchpad generations:

| Generation | Role | Development policy |
|---|---|---|
| V1 | stable/reference generation | security maintenance only |
| V2 | active modern-launchpad generation | all new launchpad features and integrations |

## Product lifecycle

```text
CREATE
-> fixed/capped ERC-20 issuance
-> bonding-curve primary trading
-> graduation readiness
-> secure graduation
-> mature secondary market
```

V1 currently includes Uniswap V4 graduation components. V2 is the active Monad development line and targets Kuru for mature secondary trading subject to the launchpad architecture gates.

## Build and test

```bash
forge fmt --check
forge build
forge build --sizes
forge test
forge test --fuzz-runs 10000
```

V2 requires its own unit, fuzz, invariant and integration coverage whenever it diverges from V1.

## Documentation

- `docs/launchpad/` — product, protocol, architecture, integration, validation and production documentation.
- `contracts/docs/launchpad/` — Modern Launchpad Solidity implementation documentation.
- `contracts/docs/prism/` — Prediction + PRISM target Solidity implementation documentation.
- `THIRD_PARTY_NOTICES.md` and `licenses/` — dependency license notices.

## Security status

No deployment is authorized solely because the contracts compile. Release qualification requires the launchpad security, integration, E2E and deployment gates described under `../docs/launchpad/08-validation/` and `../docs/launchpad/09-production/`.

Known Doorway limitations and contract trust boundaries are tracked in `docs/launchpad/SECURITY_MODEL.md`.


## PRISM contracts

Prediction + PRISM implementation specifications live under `docs/prism/`. PRISM production Solidity remains gated by its MATH-1 and CONTRACT-ARCH-1 process; the current Launchpad V1/V2 code must not be mistaken for the PRISM financial kernel.

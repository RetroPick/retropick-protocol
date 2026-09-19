# RetroPick Contracts

The Solidity workspace currently contains stable/reference Launchpad V1 and active Launchpad V2 code, plus experimental Doorway reference code. Prediction/PRISM production Solidity is not yet authorized by its separate gates.

## Launchpad versions

| Generation | Role |
|---|---|
| V1 | stable/reference, security maintenance |
| V2 | active Launchpad development line |

Current V2 primary mechanics include fixed-supply token deployment, bonding trading, quote economics, fees/buyback controls and a two-phase graduation design. The current committed graduation destination is still Uniswap-V4-oriented; Kuru is the target architecture and must not be described as already implemented.

## Current test warning

The committed unit/fuzz/invariant/integration tests are Doorway-focused. They do not qualify Factory/Token/Curve/Graduation P0 behavior.

## Documentation

- `../docs/launchpad/` — canonical Launchpad product/protocol truth.
- `../development/launchpad/contracts/` — target V2 implementation architecture.
- `docs/launchpad/` — current Solidity reference.
- `../docs/prism/` and `docs/prism/` — separate Prediction/PRISM specification/reference.
- `THIRD_PARTY_NOTICES.md` and `licenses/` — legal/dependency notices.

## Standard Foundry checks

```bash
forge fmt --check
forge build
forge build --sizes
forge test
forge test --fuzz-runs 10000
```

Actual release qualification requires the dedicated Launchpad V2 suites defined under `../development/launchpad/testing/` and security gates under `../development/launchpad/security/`.

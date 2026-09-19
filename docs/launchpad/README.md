# RetroPick Modern Launchpad Documentation

**Status:** CANONICAL LAUNCHPAD ROUTER  
**Owner:** RetroPick Engineering  
**Authority:** Routes launchpad work to the owning specification.

RetroPick Launchpad gives new ERC-20 assets a structured lifecycle from creation through bonding-based price discovery to mature secondary trading.

```text
CREATE
-> TOKEN ISSUANCE
-> BONDING CURVE
-> LIQUIDITY FORMATION
-> GRADUATION
-> KURU
-> CONTINUOUS TRADING
```

## Scope

P0 covers standard/meme ERC-20 launches, fixed/capped supply, approved quote assets, bonding-curve buy/sell, fees, graduation and the Kuru handoff on Monad.

Prediction and PRISM are separate protocol lanes and are not requirements for this launchpad.

## Authority

1. Accepted ADRs.
2. `03-protocol/` for launchpad economics and lifecycle.
3. `../../contracts/docs/launchpad/` for Solidity implementation requirements.
4. `04-architecture/` for full-stack boundaries.
5. `05-integrations/` for external systems.
6. `06-hackathon/` for Metropolis scope and cuts.
7. `08-validation/` for qualification.
8. `09-production/` for deployment and operations.
9. `01-research/` is evidence only.

## Development gates

`LP-DOCS-1 -> LP-SPEC-1 -> LP-MATH-1 -> LP-ARCH-1 -> LP-CONTRACT-1 -> LP-KURU-1 -> LP-DATA-1 -> LP-FULLSTACK-1 -> LP-SECURITY-1 -> LP-E2E-1 -> LP-DEPLOY-1 -> LP-SUBMISSION-1`.

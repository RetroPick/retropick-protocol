# Contract architecture

**Decision state:** PROPOSED in ADR-P03. The canonical PRISM protocol diagram still shows a separate CompleteSetVault. This document does not delete that diagram.

## Proposal

One `PredictionMarket` holds collateral and is the only minter and burner of two `OutcomeToken` contracts. The market is constructed with the collateral, resolver, dust sink, and resolution-spec hash. `activate()` is factory-only and moves DRAFT to OPEN.

| Piece | Storage that is financial | Not stored |
|---|---|---|
| OutcomeToken | supply, market, outcome index, decimals | payout, collateral balance, spec text |
| PredictionMarket | state, result, numerators, supplies, redeemed cursors, collateralLocked, spec hash, resolver | UI description |

Functions, access, and errors are the ones in `PredictionMarket.sol`. Checks-effects-interactions: burns and supply updates happen before `safeTransfer`. `nonReentrant` covers split, merge, redeem, burn, and archive. Split measures the collateral balance delta and reverts on a shortfall.

No upgrade path. No initializer. No beacon.

## Integration candidate map

If a later accepted ADR and a passing PRED-CONTRACT-1 authorize promotion, the files would move as:

| Research file | Candidate V2 path |
|---|---|
| `research/contract-kernels/src/prediction/OutcomeToken.sol` | `contracts/src/v2/prediction/OutcomeToken.sol` |
| `research/contract-kernels/src/prediction/PredictionMarket.sol` | `contracts/src/v2/prediction/PredictionMarket.sol` |

That move was not performed. `RetroPickLauncherTokenV2` stays the Launchpad token.

## PRISM

PRISM must not call a prediction-specific interface until that interface is frozen by an accepted ADR. The current proposal is that PRISM holds plain ERC-20 balances. `market()` is optional metadata for humans and indexers.

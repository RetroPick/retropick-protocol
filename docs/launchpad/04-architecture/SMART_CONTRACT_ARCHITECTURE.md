# Smart Contract Architecture

**Status:** DRAFT  
**Owner:** Smart Contracts  
**Authority:** Architecture mapping

## Purpose

Describe how RetroPick V2 composes creation, primary trading, fees and graduation.

## Requirements

- Map Factory -> Deployer -> LaunchToken + BondingCurve.
- Separate price/reserve logic from venue-specific graduation integration where V2 architecture allows it.
- Keep fee/buyback accounting isolated and observable.
- Represent graduation preflight, asset security, destination creation and terminal state explicitly.

## Non-goals

- No Prediction/PRISM contracts in this lane.

## Acceptance criteria

- Every contract responsibility maps to contracts/docs/launchpad/RESPONSIBILITY_MAP.md.

## Evidence required

- Contract graph and dependency/deployment order.

# RetroPick PRISM Contract Documentation

**Status:** TARGET IMPLEMENTATION SPECIFICATION  
**Production Solidity:** not authorized until the PRISM MATH-1 and CONTRACT-ARCH-1 gates permit it.

This directory is the implementation-facing contract documentation for native Prediction markets and PRISM.

## Canonical upstream semantics

Read first:
- `../../../docs/prism/protocol/PRISM_PROTOCOL_SPEC.md`
- `../../../docs/prism/protocol/CONTRACT_REQUIREMENTS.md`
- `../../../docs/prism/protocol/INVARIANTS.md`
- `../../../docs/prism/protocol/STATE_MACHINE.md`
- `../../../docs/prism/protocol/PRECISION_MODEL.md`
- `../../../docs/prism/math/README.md`
- `../../../docs/prism/04-architecture/SMART_CONTRACTS.md`

## Target kernels

Native prediction:
- `PredictionMarketFactory`
- `PredictionMarket`
- `OutcomeToken`
- `CompleteSetVault`
- resolution module / registry

PRISM:
- `PrismSeriesFactory`
- `PrismSeriesERC20`
- `PrismBackingVault`
- `PrismMintController`
- `PrismRedemptionRouter`
- `PrismSettlementEngine`

## Core implementation invariants

- complete-set conservation for native prediction markets;
- exact admitted replication `h = Gx`;
- component backing `B_i >= S*x_i`;
- back-first mint ordering;
- no double allocation of reserved backing units;
- resolution finality;
- `RESOLVED != REDEEMABLE`;
- funded final settlement before redemption;
- accounting separation between backing, LP inventory, MM inventory, fees and settlement funds.

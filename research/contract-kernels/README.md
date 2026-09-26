# Research contract kernels

Isolated Foundry harness. Nothing here is promoted into `contracts/src/v2/`.

## Prediction

`src/prediction/PredictionMarket.sol` is a prototype of the integer reference model:

- the market contract holds collateral;
- two full ERC-20 outcome tokens, decimals copied from collateral;
- cumulative floor for INVALID;
- `RESOLVED` and `REDEEMABLE` are separate;
- no admin mint.

Schema A is the implemented token shape. `PredictionMarket` still deploys two full `OutcomeToken` contracts. `OutcomeTokenGas.t.sol` measures an ERC-1167 alternative and does not wire it into the market. Beacons are not deployed.

## PRISM

`src/prism/CandidateCumulativeSettlement.sol` is a research kernel of the cumulative-floor candidate in `research/prism-model/cumulative_settlement.py`. It is labeled candidate. It is not MATH-1 PASS and it is not a v2 promotion. Canonical `FixedPointSettlement.redeem` is not in this harness and was not replaced. The full series in `docs/prism/04-architecture/PHASE1_CANDIDATE_SERIES.md` is still a proposal. ADR-R07 still stops a production settlement port.

## Run

```bash
cd research/contract-kernels
forge test
```

Foundry 1.8.3 and solc 0.8.26 were used for the recorded run. The kernel Foundry config sets invariant runs to 256 and depth to 500, matching the recorded stateful check.

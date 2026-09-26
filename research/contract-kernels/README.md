# Research contract kernels

Isolated Foundry harness. Nothing here is promoted into `contracts/src/v2/`.

## Prediction

`src/prediction/PredictionMarket.sol` is a prototype of the integer reference model:

- the market contract holds collateral;
- two full ERC-20 outcome tokens, decimals copied from collateral;
- cumulative floor for INVALID;
- `RESOLVED` and `REDEEMABLE` are separate;
- no admin mint.

Schema A is the implemented token shape. Clones and beacons are not deployed by this kernel.

## PRISM

No PRISM settlement contract is in this harness. The current per-call settlement floor has a holder-value counterexample (`CX-FP-SETTLEMENT-001`). Implementing that rule, or silently replacing it, is stopped until an ADR accepts a repair.

## Run

```bash
cd research/contract-kernels
forge test
```

Foundry 1.8.3 and solc 0.8.26 were used for the recorded run. The kernel Foundry config sets invariant runs to 256 and depth to 500, matching the recorded stateful check.

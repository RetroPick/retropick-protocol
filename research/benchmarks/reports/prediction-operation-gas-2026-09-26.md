# Prediction operation gas

One local Foundry run. This is not a percentile and not an admission measurement.

| Item | Value |
|---|---|
| Kernel SHA | `c0af8e584137fa35ef4d71b4d8a46d260798deb4` |
| Command | `forge test --match-contract PredictionOperationGasTest -vv` |
| Directory | `research/contract-kernels` |
| Foundry | 1.8.3 (`cae51ad458`, 2026-09-15) |
| solc | 0.8.26 |
| Optimizer | true, 200 runs |
| EVM | cancun |
| Meter | assembly `gas()` around `CALL` or `CREATE` |
| Raw log | `evidence/research/prediction/operation-gas-2026-09-26.txt` |

The whole test reported 6578687 gas. That figure includes deployment. The rows below are the explicit meter.

| Operation | Gas | Scenario |
|---|---|---|
| `PredictionMarket` deploy | 2438030 | Constructor. Includes two internal `OutcomeToken` creations. Both paths in this test returned the same number |
| `split` | 206722 | 100 units |
| `merge` | 37041 | 40 units after that split |
| `resolve` YES | 48909 | After `closeMint` and `beginResolution`. Those two calls are not in this row |
| redeem winner | 34979 | `redeemYes(60)` pays 60 |
| redeem INVALID | 37779 | `redeemYes(5)` after `split(5)` and INVALID pays 2 |

Collateral decimals are 18.

## Not run

Protocol factory deployment. The kernel has no factory contract. `MarketDeployer` is a test harness.

Standalone `OutcomeToken` CREATE was already measured at 534243 and was not rerun. Log: `evidence/research/prediction/outcome-token-gas-2026-09-26.txt`. The market-deploy row above is a different measurement because the tokens are created inside the market constructor.

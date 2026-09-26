# Test plan

## Reference model

```bash
cd research/prediction-model
python3 -m unittest discover -s tests -v
```

Covers split, merge, resolution, redeem, invalid dust, rounding counterexamples, lifecycle rejection, fee-on-transfer shortfall, reentrancy rejection, and a 208-state exhaustive search at `max_unit = 3`.

## Kernel

```bash
cd research/contract-kernels
forge test
```

Recorded with Foundry 1.8.3: 10 tests passed, including two fuzz tests at 256 runs and one invariant at 256 runs / 500 depth / 128000 calls / 0 reverts. Fixtures `prediction_split`, `prediction_merge`, `prediction_redeem_yes`, and `prediction_invalid_rounding` match the Solidity assertions.

`forge coverage` was not run. Slither was run and did not produce a complete IR. See `docs/prediction/10_SECURITY.md`.

## Not run

Kuru testnet deployment, mainnet fork, echidna, medusa, halmos, mythril.

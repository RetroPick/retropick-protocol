# Genuine v4 M6 infrastructure

Test-only local venue, never a production deployment script. No Kuru dependency, broadcast, mocked venue calls or venue code etching. A six-decimal quote token is modeled locally at the existing admitted address; this does not qualify live Circle USDC. Current canonical CE mode deliberately charges zero post-graduation hook fees; these baseline tests do not establish continuous community revenue.

Build genuine pinned PoolManager, PositionManager, PositionDescriptor and WETH through the existing `contracts/deployment-v4` profile; build Permit2 separately using its pinned upstream compiler 0.8.17. Protocol and test code use 0.8.26. Core `59d3ecf53afa9264a16bba0e38f4c5d2231f80bc`; periphery `9969eec44cfdf07e24b41de47f40276a58401976`; Permit2 `cc56ad0f3439c502c246fc5cfcc3db92bb8b7219`. The PoolManager entrypoint is BUSL-1.1, and PositionManager/Permit2 entrypoints are MIT. Their transitive compiler source closures also include AGPL-3.0-only Solmate/WETH; the complete license sets and source hashes are preserved in artifact metadata. This is not an all-MIT dependency closure. No upstream contract source is copied here. Production licensing/deployment is outside this test qualification.

`run_genuine.py` creates separate external build outputs and a derived temporary configuration granting read permission only for those artifact directories. It leaves global Foundry/remapping files unchanged. The default environment `FOUNDRY_FS_PERMISSIONS` did not override the configured permission list during an initial test attempt; using `--config-path` is required. The lost initial host run compiled the first draft successfully but failed setup on an artifact-read permission. That lost run establishes no PASS evidence. Fresh two-test qualification is recorded in [QUALIFICATION.md](QUALIFICATION.md).

The abstract fixture exposes virtual `_createHook`, `_createExecutor`, `_deployCore` and `_installModeledQuote` methods, plus a bounded permission-salt miner, for parent M6 tests. The swap harness is an independently authored test-only standard unlock/settle/take gateway with max-input/min-output constraints; it is not copied from upstream's UNLICENSED test router and is not a production wallet integration.

Run from the repository root:

```sh
python3 contracts/test/v2/research-experiment/m6-infra/run_genuine.py --artifacts /tmp/retropick-m6-genuine --run
```

The runner verifies six dependency Git revisions and clean tracked source before building, records genuine artifact compiler metadata and source hashes, and writes immutable timestamped attempts under `evidence/`. It rejects a zero-test exit even if Forge returns zero. To rerun without rebuilding the genuine artifacts, add `--skip-build` using the same external artifact directory. Foundry resolves relative paths against the custom config directory on the current version, so the derived config includes absolute source/library/remapping paths as well as the narrow artifact permissions.

Primary source identities: [PoolManager](https://github.com/Uniswap/v4-core/blob/59d3ecf53afa9264a16bba0e38f4c5d2231f80bc/src/PoolManager.sol), [PositionManager](https://github.com/Uniswap/v4-periphery/blob/9969eec44cfdf07e24b41de47f40276a58401976/src/PositionManager.sol), [Permit2](https://github.com/Uniswap/permit2/blob/cc56ad0f3439c502c246fc5cfcc3db92bb8b7219/src/Permit2.sol).

Reference retrieval used the existing pinned periphery source, indexed with XERJ prefix `reference-m6-uniswap-periphery-pinned`. `SafeCallback` verifies the PoolManager caller before an internal callback; `PositionManager` resolves payment through Permit2. The test gateway independently implements that standard callback authentication and exact settlement flow. The full-project XERJ prefix was ambiguous, so only this test directory and the relevant pinned upstream source were indexed with fresh isolated prefixes.

The fixture is an existing canonical V2 baseline. It does not import or exercise the separate deployed `legacy-v2` snapshot, and it neither changes nor promotes canonical source. See [QUALIFICATION.md](QUALIFICATION.md) for exact tested financial flow, measured sizes, trace evidence and extension boundaries.

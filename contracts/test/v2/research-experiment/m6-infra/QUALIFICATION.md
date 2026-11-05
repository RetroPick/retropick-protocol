# Genuine local Uniswap v4 baseline qualification

Status: **TESTED — local genuine venue baseline**, not fork, testnet deployment, Safe multisig, continuous venue revenue, audit or release qualification.

Source base: `7ddf4dae65e11acb489be7eceb30a4846adf18cc`; branch `research/v2-m6-permissionless-revenue-20261104`. The shared checkout also contained the independently owned Kuru extraction. Exact compiler source hashes/settings in the manifests distinguish the tested uncommitted source closure from the Git base. This fixture never edits financial source, deployed `legacy-v2`, release manifests, dependency revisions or global configuration.

## Executed commands and evidence

From repository root:

```sh
python3 contracts/test/v2/research-experiment/m6-infra/run_genuine.py --artifacts /tmp/retropick-m6-genuine --run
python3 contracts/test/v2/research-experiment/m6-infra/run_genuine.py --artifacts /tmp/retropick-m6-genuine --skip-build --run --trace
python3 contracts/test/v2/research-experiment/m6-infra/run_genuine.py --artifacts /tmp/retropick-m6-genuine --skip-build --run
python3 -m py_compile contracts/test/v2/research-experiment/m6-infra/run_genuine.py
```

From `contracts`:

```sh
forge fmt --check test/v2/research-experiment/m6-infra
```

The last runner command uses the hardened six-pin/clean-source check and records runner/config/remapping SHA256 values. It passed **2 tests, 0 failed, 0 skipped** in [20261105T083707015916Z](evidence/20261105T083707015916Z/manifest.json). The full successful transaction traces, actual venue runtime codehashes, pool IDs and receipt hashes are preserved in [20261105T074109426231Z](evidence/20261105T074109426231Z/03-genuine-v4-lifecycle.log); that assertion-identical version also passed **2/0/0**. Formatting and Python syntax checks passed. Forge version and exact underlying build/test commands appear in every manifest.

The genuine source builds and the initial zero-test selection failure are retained in [20261105T073222222180Z](evidence/20261105T073222222180Z/manifest.json). `forge test` returned zero while selecting no files because `--config-path` changed root resolution. This is explicitly `FAIL_NO_TESTS`; the runner now uses absolute paths/remappings and requires both tests to execute. The earlier valid two-test run is retained in [20261105T073602825215Z](evidence/20261105T073602825215Z/manifest.json). No result from the cleared host's `/tmp` is treated as evidence.

## Real financial journey and state assertions

Each test constructs genuine PoolManager, PositionManager, PositionDescriptor, WETH and Permit2 bytecode by ordinary `CREATE`, mines the correct `CREATE2` hook address (`address & 0x3fff == 0x2044`), and wires canonical V2 without Kuru. The only `vm.etch` installs the explicitly modeled six-decimal quote asset at the existing admitted address; no venue runtime is etched.

The tests launch a fixed-supply token, execute real curve buys and a sell, settle actual curve fees into the authenticated Router, reach the threshold, and call the authoritative Coordinator completion. They assert full consumed-asset/receipt reconciliation, actual PoolManager seed balances, fixed total supply, excess-token custody, actual pool identity, NFT ownership by Locker and nonzero LP liquidity. Actual PoolManager unlock/swap/settle/take callbacks execute both trade directions. LP liquidity and NFT ownership remain unchanged. A Treasury claims its own curve-fee credit, its EOA proposer schedules a spend, execution occurs at the fixed 72-hour readiness boundary, and the final recipient receives the exact amount. Treasury `claimed = spent + held`, zero deficit, Router `funded = paid + liability` and duplicate-graduation rejection are checked.

| Measurement | Native MON units | Six-decimal modeled quote units |
| --- | ---: | ---: |
| Curve-funded community Router income | 12,302,424,809,564,164 | 12,302 |
| Treasury credit claimed and spent after 72h | 4,920,969,923,825,667 | 4,923 |
| Quote physically seeded in PoolManager | 1,000,000,000,000,000,003 | 1,000,002 |
| Token units physically seeded in PoolManager | 250,000,000,000,000,000,365 | 250,000,249,999,742,635,118 |
| Protected liquidity before/after swaps | 15,811,388,300,841,896,695 | 15,811,412,017,914 |
| Whole test-function gas | 15,003,360 | 16,012,704 |

Gas includes token/community deployment, trading, graduation, swaps, checks/logging and governance. It is not per-swap cost or a production gas forecast. These are deterministic tests; no fuzz or stateful invariant campaign is claimed here.

## Exact dependency and compiler closure

| Source | Git revision | Entrypoint license |
| --- | --- | --- |
| v4 periphery | `9969eec44cfdf07e24b41de47f40276a58401976` | PositionManager MIT |
| periphery's v4 core | `59d3ecf53afa9264a16bba0e38f4c5d2231f80bc` | PoolManager BUSL-1.1 |
| periphery's Permit2 | `cc56ad0f3439c502c246fc5cfcc3db92bb8b7219` | Permit2 MIT |
| core OpenZeppelin | `dbb6104ce834628e473d2173bbc9d47f81a9eec3` | MIT |
| core Solmate | `4b47a19038b798b4a33d9749d25e570443520647` | Mixed; selected WETH AGPL-3.0-only |
| Permit2 Solmate | `8d910d876f51c3b2585c9109409d601f600e68e1` | Mixed; selected source includes AGPL-3.0-only |

All six tracked worktrees were clean. Compiler metadata preserves the source Keccak hashes, source URLs and per-source licenses. PoolManager and PositionManager source closures contain **BUSL-1.1, MIT and AGPL-3.0-only**; Permit2 contains **MIT and AGPL-3.0-only**. The genuine WETH artifact is AGPL-3.0-only. No third-party source is copied into this fixture and no production licensing conclusion is implied.

PoolManager, PositionManager, PositionDescriptor and WETH: Solidity `0.8.26+commit.8a97fa7a`, Cancun, viaIR, optimizer200, metadata bytecode hash `none`, using existing `contracts/deployment-v4` settings. Permit2: its own pinned Solidity `0.8.17+commit.8df45f5f`, London, viaIR, optimizer1,000,000, metadata hash `none`. Protocol/test code: current V2 profile Solidity0.8.26, Cancun, viaIR, optimizer200 and simulated chain10143. Dependency interfaces used by canonical V2 are recorded separately in the protocol artifact metadata; interoperability proof is limited to the calls exercised here.

| Artifact | Runtime bytes | Creation bytes excluding arguments |
| --- | ---: | ---: |
| Genuine PoolManager | 17,110 | 17,295 |
| Genuine PositionManager | 19,733 | 21,107 |
| Genuine PositionDescriptor | 24,240 | 24,444 |
| Genuine WETH | 2,833 | 3,950 |
| Genuine Permit2 | 9,152 | 9,345 |
| Current V2 Factory | 24,486 | 26,001 |
| Current CommunityFeeRouter | 6,487 | 7,514 |
| Current V4 Executor | 16,036 | 20,524 |
| Current Hook | 15,505 | 16,618 |
| Current Treasury | 4,606 | 7,486 |
| Current Timelock | 5,842 | 7,072 |

Genuine construction additionally checks initcode including arguments <=49,152 and deployed runtime <=24,576. Factory has only 90 runtime bytes of EIP-170 margin. The test harness itself has runtime49,084/creation51,220 and uses the repository's raised **test-only** size allowance; it is not deployable production code.

## Extension handoff

`GenuineV4EnvironmentFixtureV2` exposes virtual `_createHook`, `_createExecutor`, `_deployCore` and `_installModeledQuote`. A qualified experimental hook can retain the same external legacy ABI while using a separately mined initialization hash/salt. A derived fixture may override `_createExecutor` for the corresponding independently deployed worker. `_deployCore` can be overridden for additional module wiring without enlarging Factory code. The independent test-only swap gateway enforces PoolManager callback authentication, max-input/min-output and exact ERC20 settlement; it is not a production wallet router.

The runner selects `M6GenuineV4CommunityBaselineTest` deliberately. New revenue test contracts require an explicit source-scoped test command using the generated config, artifact-root environment variables and their own contract selector. A new hook or executor requires new evidence; reusing this baseline PASS does not qualify their fee paths. Keep old binding/receipt/claim assertions as regression properties.

## Remaining gates

Current community launches explicitly disable post-graduation hook fees. Swaps leave Router beneficiary credits unchanged; recognized venue revenue is **zero**, so these tests establish no continuous community fee stream. The Treasury spend consumes curve-generated fees only. LP principal is never harvested as revenue. Creator/contributor credits are preserved but only the Treasury claim is executed here; independent multi-beneficiary adversity belongs to the existing financial suite.

No real Monad RPC, fork block, live deployment, production Circle asset, Safe signatures or external audit is qualified. Chain10143 is simulated. No venue broadcast or production state mutation occurs. Live/fork qualification and new authenticated venue revenue remain separate release blockers.

The required historical `baseline.py --check` was also executed before this test-only commit: **exit1**, retained in [precommit checks](evidence/20261105T084204688369Z-precommit/checks.json) and its full raw log. That original research checker compares all canonical CE additions and independently owned Kuru extraction against `28a4744`; it cannot certify the current owner-authorized canonical campaign. This fixture does not reinterpret that failure as a global protected-path PASS. Its staged paths are confined to this test directory, while deployed/legacy-source protection remains a separate owning-campaign gate. The precommit check observed current branch HEAD `c41fa72d94a98e8c42f36e9d38cad683f5ebdd9c`; financial source hashes used for the genuine runs remain the exact compiler metadata in their earlier manifests.

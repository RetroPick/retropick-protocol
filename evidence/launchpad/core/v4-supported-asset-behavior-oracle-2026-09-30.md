# Current V4 Factory positive-path behavioral oracle

**Classification:** executable regression for current Core behavior with a stateful synthetic V4 seam. This is **not** a real V4 PoolManager/PositionManager integration result and does not clear `CORE_BASELINE_P0_QUALIFIED`.

**Source baseline:** `668e521` on `codex/kuru-freeze-smart-contract-spec`. **Network domain:** chain ID 10143; Circle test uses a pinned Monad Testnet fork at block `66752717`, with no broadcast. **Toolchain:** Forge 1.8.3 (`cae51ad458f6abb64852b7709eb784352429825d`), solc 0.8.26, optimizer 200, viaIR enabled by the current local Foundry configuration. The pre-existing uncommitted `contracts/foundry.toml` edit was not changed or committed.

## Reproduction

From `contracts/`, with the existing `.env.local` loaded into the command environment:

```bash
set -a; source .env.local; set +a
forge test --match-path test/v2/integration/RetroPickV4GraduationBehavior.t.sol --summary
forge test --match-path test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol --summary
forge fmt --check test/v2/integration/RetroPickV4GraduationBehavior.t.sol
```

Observed: **2 passed, 0 failed, 0 skipped** for `testNativeCurrentV4FailureRetryCustodyAndReplay` and `testCircleCurrentV4FailureRetryCustodyAndReplay`. The Circle test uses the real canonical chain-10143 Circle token at `0x534b2f3A21130d7a60830c2Df862319e593943A3`, not the Kuru-listed compatibility token.

The pre-existing Factory qualification suite also passed **17/17**, with no skips, against the same working tree. The new file passed `forge fmt --check`.

## What the regression proves

Both supported quote classes run the real current Factory → Deployer → LauncherToken → BondingCurve → FeeEscrow → GraduationExecutor → Locker path. The threshold-crossing buy leaves the Curve graduated and the Factory in `Swept` with physical quote and launch tokens equal to its secured record. Escrow physical quote covers its recorded liability. The test forces the stateful synthetic PositionManager to revert during mint, after the Factory has entered the phase-2 call: the pool initialization, transferred assets and excess-token lock all roll back, while the previously committed `Swept` record and secured assets remain unchanged. Retrying the *same* launch completes without changing its economic inputs. A second completion rejects before another position or asset movement.

On success, the test checks the pool and position seam received the same `PoolKey`, the position token ID is owned by the permanent V4 locker, the locker registered that ID, `T−B` excess launch tokens are physically held and recorded there, the seed base and full quote amount reached the synthetic PositionManager, and the Factory cleared its secured balances. The fixed token supply reconciles purchased tokens, seeded tokens and locked excess.

The seam is intentionally stateful: its synthetic Permit2 records allowances and transfers real ERC20 balances; its synthetic PositionManager decodes the actual `modifyLiquidities` action payload, pulls the approved ERC20 maxima, receives native quote, and exposes position ownership. This makes the test a useful **pre-extraction Factory behavior oracle**. It does not validate real V4 tick/liquidity calculations, singleton accounting, hook callbacks, actual Permit2 behavior, or a live V4 venue. The real V4 success/retry path and broader stateful Core campaign remain required before `CORE_BASELINE_P0_QUALIFIED = PASS`.

**No production source changed.** This increment does not accept ADR-009/020 or authorize Factory extraction or a Kuru executor.

---
id: LP-SC-AUDIT
type: normative_implementation
status: ready
owner: launchpad-solidity
product: launchpad
version: v2
---

# Current State Audit

## CURRENT

| Component | Current responsibility | Target disposition |
|---|---|---|
| RetroPickLaunchFactoryV2 | launch config, deployment orchestration, quote approval/economics, fee snapshot, graduation state; currently imports V4 PoolManager/PositionManager/Permit2/hook/locker/executor | MODIFY |
| RetroPickLaunchDeployerV2 | deploys curve/token pair and wires launch | KEEP/HARDEN |
| RetroPickLauncherTokenV2 | fixed-supply ERC20 with metadata/socials, supply minted to curve | KEEP |
| RetroPickBondingCurveV2 | primary buy/sell, reserve/fee accounting, graduation readiness | KEEP/HARDEN |
| RetroPickBondingCurveMathV2 | constant-product quote math | KEEP/FREEZE WITH TESTS |
| RetroPickBuybackVaultV2 | buyback/lock accounting | KEEP IF P0 economics retain it |
| RetroPickGraduationGuardV2 | preflight validation for current destination seeding | MODIFY/REPLACE venue-specific checks |
| RetroPickGraduationExecutorV2 | current V4 pool creation/position flow | REPLACE FOR P0 KURU |
| RetroPickLaunchLockerV2 | V4 position locking | DEFER once Kuru path proven |
| RetroPickMemeHookV2 | V4 hook-specific fee behavior | DEFER once Kuru path proven |
| RetroPickGraduationMathV2 | V4 sqrtPriceX96 seed math | DEFER from Kuru P0 path |
| RetroPickDoorwayV2 | experimental cross-chain migration reference | OUT_OF_SCOPE_P0 |

## Test reality

Committed tests currently target Doorway. This means no current Launchpad V2 release claim can rely on the existing unit/fuzz/invariant/integration directories.

## TARGET

Core token/bonding/fee behavior remains deterministic and independently qualified. Graduation is split into an internal asset-securement state transition plus a retryable Kuru destination step.

## DELTA

Add core V2 tests before refactoring graduation. Then isolate V4-only dependencies from the P0 execution path.

## MIGRATION ORDER

1. Write Factory/Token/Curve/fee baseline tests.
2. Add stateful reserve/fee/graduation invariants.
3. Verify Kuru official contracts/SDK.
4. Accept Kuru parameter policy ADR.
5. implement Kuru graduation controller/executor.
6. differential-test unchanged bonding behavior.
7. prove failure/retry safety.
8. remove/deactivate obsolete V4 runtime dependencies only after the Kuru path is complete.

---
id: LP-CODE-MAP
type: generated_current_state
product: launchpad
version: v2
status: active
source: contracts/src/v2
---

# Current Contract Map

| Source | Current responsibility | P0 disposition |
|---|---|---|
| RetroPickLaunchFactoryV2 | launch configs, quote policy/economics, fee snapshots, deployment orchestration, graduation record/state; currently V4-coupled | MODIFY |
| RetroPickLaunchDeployerV2 | deploy token/curve pair | KEEP/HARDEN |
| RetroPickLauncherTokenV2 | fixed-supply ERC20 + metadata/socials | KEEP |
| RetroPickBondingCurveV2 | buy/sell, reserves, fees, graduation readiness/sweep | KEEP/HARDEN |
| RetroPickBondingCurveMathV2 | constant-product arithmetic | KEEP/FREEZE |
| RetroPickBuybackVaultV2 | buyback lock/vesting | KEEP if retained by P0 economics |
| RetroPickGraduationGuardV2 | validates current graduation seed | MODIFY |
| RetroPickGraduationExecutorV2 | V4 full-range liquidity mint/settlement | REPLACE for Kuru P0 |
| RetroPickLaunchLockerV2 | V4 position/token locking | DEFER from Kuru P0 path |
| RetroPickMemeHookV2 | V4 hook fee/fee-sweep behavior | DEFER from Kuru P0 path |
| RetroPickGraduationMathV2 | V4 sqrtPriceX96 seeding math | DEFER from Kuru P0 path |
| RetroPickDoorwayV2 | experimental Monad/Solana migration reference | OUT_OF_SCOPE_P0 |

## Current test map

Committed unit/fuzz/invariant/integration tests target Doorway. There is no committed core Launchpad V2 test suite qualifying Factory/Token/Curve/fees/graduation.

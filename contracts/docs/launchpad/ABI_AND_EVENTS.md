---
id: LP-CODE-ABI
type: generated_current_state
product: launchpad
version: v2
status: active
source: contracts/src/v2
---

# ABI and Events

This file is a human index. Compiled Foundry artifacts are the canonical generated ABI.

## Factory public/external surface

Current source exposes:
`launchConfigCount`, `getLaunchConfig`, `getLaunchedToken`, `getLaunchFeePolicy`,
configuration setters for launch/quote/fee/snipe settings,
`previewLaunchEconomics`, `launchToken`, `launchTokenFor`,
creator-recipient/buyback controls,
`graduate`, `forceSweptGraduation`, `createGraduatedPool`,
`rescueCurveFees`, and `rescueSweptGraduation`.

Factory lifecycle/config events include:
`TokenLaunched`, `LaunchSwept`, `LaunchForceSwept`, `PoolGraduated`,
launch-config/fee/quote updates, creator-recipient changes,
`BuybackEnabledUpdated`, `GraduationTokensPermanentlyLocked`, and `LaunchGraduationRescued`.

## Curve surface

Current source exposes:
`initialize`, reserve getters, `readyToGraduate`, `buy`, `sell`,
`sweepFees`, `graduate`, `rescueFees`, creator/buyback setters and snipe-tax exemption query.

Curve events include:
`CurveBuy`, `CurveSell`, `FeesSwept`, `FeesRescued`,
`BuybackLocked`, `CurveCompleted`, `Initialized`,
creator/buyback updates and `AutoGraduationFailed`.

## Generation rule

After every contract change, generate ABI/type artifacts from the exact Foundry build rather than hand-editing downstream copies.

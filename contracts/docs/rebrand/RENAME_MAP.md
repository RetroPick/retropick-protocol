# Rename Map

Complete record of all identifier and file renames performed during the rebrand.

## File Renames

| Original | Target |
|----------|--------|
| `PonsV2LaunchFactory.sol` | `RetroPickV2LaunchFactory.sol` |
| `PonsV2LaunchDeployer.sol` | `RetroPickV2LaunchDeployer.sol` |
| `PonsV2BondingCurve.sol` | `RetroPickV2BondingCurve.sol` |
| `PonsV2LauncherToken.sol` | `RetroPickV2LauncherToken.sol` |
| `PonsV2GraduationGuard.sol` | `RetroPickV2GraduationGuard.sol` |
| `PonsV2GraduationExecutor.sol` | `RetroPickV2GraduationExecutor.sol` |
| `PonsV2LaunchLocker.sol` | `RetroPickV2LaunchLocker.sol` |
| `PonsV2BuybackVault.sol` | `RetroPickV2BuybackVault.sol` |
| `hooks/PonsV2MemeHook.sol` | `hooks/RetroPickV2MemeHook.sol` |
| `interfaces/ILaunchpadV2.sol` | `interfaces/IRetroPickV2Launchpad.sol` |
| `interfaces/ILaunchpadV2Graduation.sol` | `interfaces/IRetroPickV2Graduation.sol` |
| `libraries/PonsV2BondingCurveMath.sol` | `libraries/RetroPickV2BondingCurveMath.sol` |
| `libraries/PonsV2GraduationMath.sol` | `libraries/RetroPickV2GraduationMath.sol` |

## Contract/Interface/Library Identifier Renames

| Original | Target |
|----------|--------|
| `PonsV2LaunchFactory` | `RetroPickV2LaunchFactory` |
| `PonsV2LaunchDeployer` | `RetroPickV2LaunchDeployer` |
| `PonsV2BondingCurve` | `RetroPickV2BondingCurve` |
| `PonsV2LauncherToken` | `RetroPickV2LauncherToken` |
| `PonsV2GraduationGuard` | `RetroPickV2GraduationGuard` |
| `PonsV2GraduationExecutor` | `RetroPickV2GraduationExecutor` |
| `PonsV2LaunchLocker` | `RetroPickV2LaunchLocker` |
| `PonsV2BuybackVault` | `RetroPickV2BuybackVault` |
| `PonsV2MemeHook` | `RetroPickV2MemeHook` |
| `PonsV2BondingCurveMath` | `RetroPickV2BondingCurveMath` |
| `PonsV2GraduationMath` | `RetroPickV2GraduationMath` |
| `IPonsV2FeeEscrow` | `IRetroPickV2FeeEscrow` |
| `IPonsV2FeePolicy` | `IRetroPickV2FeePolicy` |
| `IPonsV2LaunchFactory` | `IRetroPickV2LaunchFactory` |
| `IPonsV2BondingCurve` | `IRetroPickV2BondingCurve` |
| `IPonsV2LaunchFactoryGraduation` | `IRetroPickV2LaunchFactoryGraduation` |

## Import Path Updates

All internal imports updated to reflect new file names:
- `"./PonsV2*.sol"` → `"./RetroPickV2*.sol"`
- `"./hooks/PonsV2MemeHook.sol"` → `"./hooks/RetroPickV2MemeHook.sol"`
- `"./libraries/PonsV2*.sol"` → `"./libraries/RetroPickV2*.sol"`
- `"./interfaces/ILaunchpadV2*.sol"` → `"./interfaces/IRetroPickV2*.sol"`

## Comment and NatSpec Updates

| Pattern | Replacement |
|---------|-------------|
| `pons v2` | `RetroPick V2` |
| `Pons v2` | `RetroPick V2` |
| `PonsV2FeeEscrow` | `RetroPickV2FeeEscrow` |
| `PonsV2LaunchAndBuy` | `RetroPickV2LaunchAndBuy` |

## Preserved Identifiers

**NOT renamed** (generic protocol terms, not branding):
- `FeePolicySnapshot` (struct)
- `IERC721ReceiverLike` (interface) 
- `GraduationPhase` (enum and values)
- `LaunchDeployment` (struct)
- All function names (`launchToken`, `graduate`, `createGraduatedPool`, etc.)
- All parameter names (`pairToken`, `graduationThreshold`, `phantomQuote`, etc.)
- All event names and error names
- All public state variable names

## Verification

**Branding scan result:** 0 "pons" references remaining in first-party source  
**Files changed:** 13 files renamed and content updated  
**Import integrity:** All imports resolve correctly  
**Behavioral preservation:** No logic, arithmetic, or control flow modified
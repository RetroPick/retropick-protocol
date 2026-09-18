# File Classification Matrix

All 153 files in the copied payload classified for retention or deletion.

## KEEP_AND_REBRAND (13 files)
**First-party V2 Solidity source to be renamed and rebranded**

| File | Target |
|------|--------|
| `contractsV2/src/v2/PonsV2LaunchFactory.sol` | `src/v2/RetroPickV2LaunchFactory.sol` |
| `contractsV2/src/v2/PonsV2LaunchDeployer.sol` | `src/v2/RetroPickV2LaunchDeployer.sol` |
| `contractsV2/src/v2/PonsV2BondingCurve.sol` | `src/v2/RetroPickV2BondingCurve.sol` |
| `contractsV2/src/v2/PonsV2LauncherToken.sol` | `src/v2/RetroPickV2LauncherToken.sol` |
| `contractsV2/src/v2/PonsV2GraduationGuard.sol` | `src/v2/RetroPickV2GraduationGuard.sol` |
| `contractsV2/src/v2/PonsV2GraduationExecutor.sol` | `src/v2/RetroPickV2GraduationExecutor.sol` |
| `contractsV2/src/v2/PonsV2LaunchLocker.sol` | `src/v2/RetroPickV2LaunchLocker.sol` |
| `contractsV2/src/v2/PonsV2BuybackVault.sol` | `src/v2/RetroPickV2BuybackVault.sol` |
| `contractsV2/src/v2/hooks/PonsV2MemeHook.sol` | `src/v2/hooks/RetroPickV2MemeHook.sol` |
| `contractsV2/src/v2/interfaces/ILaunchpadV2.sol` | `src/v2/interfaces/IRetroPickV2Launchpad.sol` |
| `contractsV2/src/v2/interfaces/ILaunchpadV2Graduation.sol` | `src/v2/interfaces/IRetroPickV2Graduation.sol` |
| `contractsV2/src/v2/libraries/PonsV2BondingCurveMath.sol` | `src/v2/libraries/RetroPickV2BondingCurveMath.sol` |
| `contractsV2/src/v2/libraries/PonsV2GraduationMath.sol` | `src/v2/libraries/RetroPickV2GraduationMath.sol` |

## KEEP_THIRD_PARTY (71 files)
**Vendored dependencies - retain with original SPDX headers and content**

- OpenZeppelin Contracts: 20 files (MIT)
- Uniswap V4 Core: 34 files (mostly MIT, some BUSL-1.1)
- Uniswap V4 Periphery + Permit2: 16 files (MIT)  
- v4-hooks-public BaseHook: 1 file (MIT)

## DELETE_V1 (26 files)
**Complete V1 implementation - not needed for V2 rebrand**

All files under `contractsV1/src/` and `contractsV1/lib/` including:
- V1 contracts: `PonsLaunchFactory.sol`, `PonsLauncherToken.sol`
- V1 interfaces and libraries
- V1 OpenZeppelin dependency copy (separate from V2)

## DELETE_DEMO (3 files) 
**Testing/reference material not part of production kernel**

- `contractsV2/src/v2/testing/PonsDoorway.sol`
- `contractsV2/src/v2/testing/doorway.md` 
- `contractsV2/src/v2/testing/doorway.jpg`

## DELETE_GENERATED (2 files)
**Old deployment artifacts describing V1, not V2**

- `abi.json` - V1 factory ABI
- `contract-meta.json` - V1 compiler metadata

## DELETE_MEDIA (1 file)
**Pons product branding**

- `media/logo.png`

## DELETE_PRODUCT_DOCS (1 file)
**Pons marketing material**

- `README.md` - Upstream project documentation

## DELETE_UNUSED_DEPENDENCY (5 files)
**Non-code junk in dependency trees**

V2 dependencies:
- `contractsV2/lib/v4-core/src/interfaces/callback/oz.jpg`
- `contractsV2/lib/v4-core/src/interfaces/callback/ozz.md`

V1 dependencies (deleted with V1):
- `contractsV1/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/sweet/toto.jpg`
- `contractsV1/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/sweet/toto.md`
- `contractsV1/lib/openzeppelin-contracts/contracts/utils/introspection/truth.md`

## DELETE_NESTED_GIT (34 files)
**Pons repository metadata to be removed**

All files under `contracts/pons-labs/.git/`

## KEEP_LEGAL_ONLY (0 files)
**No LICENSE files exist in the payload - must be reconstructed**

## Summary

- **Retained:** 84 files (13 first-party + 71 dependencies)
- **Deleted:** 69 files (26 V1 + 3 demo + 2 generated + 1 media + 1 docs + 2 junk + 34 git)
- **Total:** 153 files verified

All files accounted for. No file will disappear without explicit classification.
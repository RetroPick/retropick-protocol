# RetroPick V2 Launchpad Contracts

**Status:** `experimental / behavior-preserving baseline`

A vendor-derived baseline of V2 fair-launch launchpad contracts, rebranded from the Pons V2 implementation to establish a RetroPick-owned starting point for future protocol development.

## ⚠️ Important Limitations

- **NOT the canonical RetroPick Prediction or PRISM implementation**
- **Does NOT bypass MATH-1 or CONTRACT-ARCH-1 phase gates**
- **Does NOT authorize production deployment**
- **NOT audited, battle-tested, or production-ready**

This baseline exists solely to provide a behavior-preserving, fully rebranded V2 fair-launch foundation within `contracts/` while preserving original economics and state machine behavior.

## Architecture

RetroPick V2 provides a bonding curve launch mechanism that graduates into Uniswap V4:

```
Creator → Factory → Deployer → [Token + BondingCurve]
    ↓
Primary trading on constant-product curve
    ↓
Graduation threshold crossed → Graduate → CreateGraduatedPool
    ↓
Full-range Uniswap V4 position + MemeHook + permanent lock
```

## Core Contracts

| Contract | Purpose |
|----------|---------|
| `RetroPickV2LaunchFactory` | Main entry point, orchestrates launches and graduation |
| `RetroPickV2LaunchDeployer` | Deploys token + curve pairs (EIP-170 size optimization) |
| `RetroPickV2BondingCurve` | Constant-product trading, quote-denominated fees |
| `RetroPickV2LauncherToken` | Fixed-supply ERC-20, entire supply minted to curve |
| `RetroPickV2GraduationGuard` | Stateless V4 preflight validation |
| `RetroPickV2GraduationExecutor` | Heavy graduation operations |
| `RetroPickV2LaunchLocker` | Permanent position NFT custody (no withdrawal) |
| `RetroPickV2BuybackVault` | Five-year linear vest for bought-back supply |
| `RetroPickV2MemeHook` | Singleton V4 hook for graduated pools |

## Key Features

- **Bonding curve launch:** Full supply mints to constant-product curve
- **Quote-denominated fees:** Protocol/creator/buyback split from first trade
- **Two-phase graduation:** Safe threshold crossing + retryable pool creation
- **Permanent liquidity lock:** No withdrawal path from graduated position
- **Anti-snipe protection:** Price impact + reserved allocation limits
- **Creator revenue:** Optional tax + fee share in quote currency
- **Buyback vesting:** Linear 5-year vest, not burn

## Dependencies

- Solidity `^0.8.26` with `evm_version = "cancun"`
- OpenZeppelin Contracts (MIT)
- Uniswap V4 Core + Periphery (MIT + BUSL-1.1)
- Permit2 interfaces (MIT)
- v4-hooks-public BaseHook (MIT)

See `docs/rebrand/DEPENDENCIES.md` for complete dependency analysis and `licenses/` for required license texts.

## Behavior Preservation

This implementation preserves the original V2 economics exactly:
- ✓ Same bonding curve mathematics
- ✓ Same fee calculations and bounds  
- ✓ Same graduation state machine
- ✓ Same access control semantics
- ✓ Same CREATE2 deterministic deployment (different addresses due to renamed init code)

See `docs/rebrand/BEHAVIOR_PARITY.md` for verification methodology.

## Legal Status

- **BUSL-1.1 dependencies:** `Pool.sol` and `Position.sol` require separate legal review for deployment rights
- **Third-party licenses:** See `THIRD_PARTY_NOTICES.md` and `licenses/`
- **Deployment rights:** Not established by this rebrand

## Migration Evidence

Complete rebrand documentation:
- `docs/rebrand/BASELINE.md` - Original source snapshot
- `docs/rebrand/FILE_CLASSIFICATION.md` - Retention/deletion decisions  
- `docs/rebrand/RENAME_MAP.md` - All identifier changes
- `docs/rebrand/DEPENDENCIES.md` - Dependency analysis and pinning
- `docs/rebrand/MIGRATION_REPORT.md` - Complete migration record

## Relationship to RetroPick Protocol

This V2 launchpad baseline is **separate** from the canonical RetroPick protocol:
- RetroPick native markets use complete-set collateralization: `1 collateral → 1 YES + 1 NO`
- PRISM uses exact component backing: `B_i ≥ S*x_i`
- This V2 baseline uses fixed-supply bonding curves

Future integration between systems is a separate architectural decision.

---

**Generated:** 2026-09-18 from Pons Labs V2 @ `162310fb...`  
**Rebrand:** Pure identity transformation, no logic changes  
**Status:** Vendor-derived experimental baseline only
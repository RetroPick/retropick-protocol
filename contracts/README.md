# RetroPick V1 Launchpad Contracts

**Status:** `experimental baseline`

RetroPick V1 provides a fair-launch launchpad system with bonding curves that graduate into permanent Uniswap V4 liquidity.

## ⚠️ Important Limitations

- **NOT the canonical RetroPick Prediction or PRISM implementation**
- **Does NOT bypass MATH-1 or CONTRACT-ARCH-1 phase gates**
- **Does NOT authorize production deployment**
- **NOT audited, battle-tested, or production-ready**

This baseline serves as an experimental foundation for launchpad development within the RetroPick protocol ecosystem.

## Architecture

RetroPick V1 provides a bonding curve launch mechanism that graduates into Uniswap V4:

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
| `RetroPickLaunchFactoryV1` | Main entry point, orchestrates launches and graduation |
| `RetroPickLaunchDeployerV1` | Deploys token + curve pairs (EIP-170 size optimization) |
| `RetroPickBondingCurveV1` | Constant-product trading, quote-denominated fees |
| `RetroPickLauncherTokenV1` | Fixed-supply ERC-20, entire supply minted to curve |
| `RetroPickGraduationGuardV1` | Stateless V4 preflight validation |
| `RetroPickGraduationExecutorV1` | Heavy graduation operations |
| `RetroPickLaunchLockerV1` | Permanent position NFT custody (no withdrawal) |
| `RetroPickBuybackVaultV1` | Five-year linear vest for bought-back supply |
| `RetroPickMemeHookV1` | Singleton V4 hook for graduated pools |

## Key Features

- **Bonding curve launch:** Full supply mints to constant-product curve
- **Quote-denominated fees:** Protocol/creator/buyback split from first trade
- **Two-phase graduation:** Safe threshold crossing + retryable pool creation
- **Permanent liquidity lock:** No withdrawal path from graduated position
- **Anti-snipe protection:** Price impact + reserved allocation limits
- **Creator revenue:** Optional tax + fee share in quote currency
- **Buyback vesting:** Linear 5-year vest, not burn

## Build & Test

```bash
forge build
forge test
forge test --fuzz-runs 10000
```

## Dependencies

- Solidity `^0.8.26` with `evm_version = "cancun"`
- OpenZeppelin Contracts (MIT)
- Uniswap V4 Core + Periphery (MIT + BUSL-1.1)
- Permit2 interfaces (MIT)
- v4-hooks-public BaseHook (MIT)

See `THIRD_PARTY_NOTICES.md` for complete dependency attribution and `licenses/` for required license texts.

## Security & Legal Status

- **BUSL-1.1 dependencies:** Some V4 core libraries require legal review for deployment rights
- **Third-party licenses:** See `THIRD_PARTY_NOTICES.md` and `licenses/`
- **Security status:** Experimental baseline - requires full security review before production use

## Relationship to RetroPick Protocol

This V1 launchpad is **separate** from the canonical RetroPick protocol systems:

- **RetroPick native markets:** Complete-set collateralization (`1 collateral → 1 YES + 1 NO`)
- **PRISM structured products:** Exact component backing (`B_i ≥ S*x_i`)
- **V1 launchpad:** Fixed-supply bonding curves

Future integration between systems requires separate architectural decisions.

## Documentation

- **Migration audit:** `docs/rebrand/` - Complete extraction and verification documentation
- **Legal compliance:** `THIRD_PARTY_NOTICES.md` - Required attribution for vendored dependencies  
- **Upstream provenance:** `docs/rebrand/UPSTREAM_PROVENANCE.md` - Source derivation information

---

**Status:** Experimental RetroPick V1 baseline for future protocol development
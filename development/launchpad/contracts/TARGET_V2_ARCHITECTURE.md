---
id: LP-SC-ARCH
type: normative_implementation
status: ready
owner: launchpad-solidity
product: launchpad
version: v2
---

# Target V2 Architecture

```text
RetroPickLaunchFactoryV2
   ├─ RetroPickLaunchDeployerV2
   │    ├─ RetroPickLaunchTokenV2
   │    └─ RetroPickBondingCurveV2
   ├─ fee/buyback components
   └─ graduation controller
         ├─ secure curve assets
         ├─ record GRADUATING state
         └─ Kuru-specific executor
                └─ verify destination market
```

## Architecture rules

- P0 uses a concrete Kuru integration, not a generic market-adapter framework.
- Factory remains the launch record/config authority.
- BondingCurve owns primary market arithmetic and reserve accounting.
- Destination-market failure cannot reverse asset security or lose balances.
- A market is not GRADUATED until the destination identifier/address is verified usable.
- Same-quote graduation is the default architecture.

# M6 architecture increment

Current: Curve-only community Router/Treasury; V4 community hook fees0; real v4 executor and permanent LP lock exist; new PR46 tests did not pass CI. Target: fresh versioned in-kind Router/Treasury with actual v4 afterSwap funding; no changes to Factory/Curve/Locker/deployed identities.

Trade -> Curve(pre-separated C) or genuine v4Hook(gross F+T) -> per-launch RevenueRouter -> protocol escrow(P for venue only) + independent per-asset community credit(C) -> AssetTreasury own-credit pull -> unchanged qualified Timelock -> per-asset spending. LP NFT and excess token principal stay permanently held by the original Locker.

New APIs: fundVenue(poolId,asset,epoch,sequence,F,T), explicit asset credit/accounting/claim and Treasury per-asset held/claimed/spent views. Preserve Curve-facing Router methods and quote aliases. Allowed assets are quote and launch token only. Zero conversion, zero LPfee, fixed existing fee snapshots.

Fresh construction: V4 environment/hook/executor wired once -> existing Factory records token/Curve -> authenticated versioned Builder -> separate revenue helper creates Controller/Router -> asset-treasury helper creates Timelock/Vault -> original Registry receives actual Vault beneficiary -> bind Router -> unchanged Factory seals Curve. No insecure public initializer, no shared counterfactual reservation, no arbitrary target/calldata and no delegatecall plugin. Unqualified experimental modules are not deployable products.

This versioned family is to be proved experimentally before owner-accepted canonical promotion. Existing factories/builders, legacy current source and historic packets remain immutable and usable. See FEE_SOURCE_SPEC for equations, authentication, callback and policy semantics.

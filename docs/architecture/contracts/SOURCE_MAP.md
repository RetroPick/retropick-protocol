# Launchpad Source Map

**Source scope:** `contracts/src/v1` and `contracts/src/v2`, pinned to `d8971ffee042314def2dfd48a413737e3d84ac22`. Each V2 row has the corresponding V2 identifier/path and normalized behavior is identical; the V2 hook has only a pre-existing trailing whitespace difference at line 19.

## First-party contracts (each version)

| V1 / V2 source | Entrypoints and ownership | Callers / callees | Principal storage and assets | Diagram refs |
|---|---|---|---|---|
| `RetroPickLaunchFactoryV{n}.sol` | `launchToken*`, `graduate`, `createGraduatedPool`, recovery/admin; Ownable2Step; permissionless seed | Creator/forwarder → deployer, curve, hook, guard, executor, locker, PoolManager, PositionManager | launch configs, launched-token record, phase, swept quote/tokens, fee policy; holds swept reserves transiently | 01–06 |
| `RetroPickLaunchDeployerV{n}.sol` | `deployLaunch`; factory-only | Factory → new Curve + Token | immutable factory; no custody | 01–03 |
| `RetroPickBondingCurveV{n}.sol` | `buy`, `sell`, `sweepFees`, `graduate`; factory gates init/admin | Traders → Curve; Curve → Factory, escrow, buyback vault | launch token, quote, tracked quote/tokens, fee/tax/buyback balances, reserved tokens; custody before sweep | 01–04 |
| `RetroPickLauncherTokenV{n}.sol` | ERC-20/Burnable constructor and metadata views | Deployer mints supply to curve; Curve/locker/position paths transfer | immutable metadata, deployer, factory, curve; launch-token supply | 01–04 |
| `RetroPickGraduationGuardV{n}.sol` | `assertSeedable*`, pure/view preflight | Factory → Guard | no mutable custody; validates V4 price/liquidity bounds | 01–03, 05 |
| `RetroPickGraduationExecutorV{n}.sol` | `mintFullRangePosition`; factory-only | Factory → executor → Permit2 + PositionManager | immutable position manager/permit2/factory; temporary seed balances | 01–04 |
| `RetroPickLaunchLockerV{n}.sol` | `lockPosition`, `lockTokenSupply`; factory-only | Factory/executor result → Locker | locked V4 NFT ID and permanently removed launch-token supply | 01–04 |
| `RetroPickBuybackVaultV{n}.sol` | `lock`, `release`, creator-recipient update; owner wires factory | Curve/Hook → vault → fee escrow | per-token vest, locked tokens; five-year vesting basis | 01–04, 06 |
| `hooks/RetroPickMemeHookV{n}.sol` | V4 hook callbacks, register pool, sweep/rescue pool fees; owner/factory | PoolManager → Hook; Factory → Hook; Hook → escrow, vault, PoolManager | pool info/keys, pending quote/memecoin fees/tax/buyback; post-graduation fee custody | 01–04, 06 |
| `RetroPickDoorwayV{n}.sol` | request/attest/execute/cancel; owner/guardian/relayer | External callers/relayer/guardian → Doorway | migrations, nonces, support lists, accounting counters; no ERC-20 custody action | 07 |

## Interfaces and libraries (each version)

| V1 / V2 source | Public surface / role | Consumers | Diagram refs |
|---|---|---|---|
| `interfaces/IRetroPickLaunchpadV{n}.sol` | fee escrow ABI, fee policy snapshot, launch factory/curve records | Factory, Curve, Vault, Hook, external ABI-only escrow | 01, 03, 04 |
| `interfaces/IRetroPickGraduationV{n}.sol` | factory `graduate` interface | Curve automatic graduation path | 02, 03, 05 |
| `interfaces/IRetroPickDoorwayV{n}.sol` | Doorway directions/statuses, migration/attestation and registry/vault/staking interfaces | Doorway and tests | 07 |
| `libraries/RetroPickBondingCurveMathV{n}.sol` | constant-product amount-in/out arithmetic | Curve; Factory quotability check | 02–04 |
| `libraries/RetroPickGraduationMathV{n}.sol` | token/quote amount ratio → V4 sqrt price | Factory; GraduationGuard | 02–04 |

## External dependencies and trust edges

| Dependency | Source-backed use | Not asserted |
|---|---|---|
| OpenZeppelin | ERC-20, ownership, reentrancy, safe token transfer, math | an audited deployment/configuration outcome |
| Uniswap V4 `IPoolManager`, `IPositionManager`, hook types | initialize pool, register/sweep hook, mint full-range LP | Kuru integration or CLOB behavior |
| Permit2 | executor approvals for V4 position mint | independent reserve custody |
| `IRetroPickFeeEscrowV{n}` | native/token credit calls and claims ABI | an escrow implementation, code, or deployed address |
| ERC-20 quote asset / native ETH | curve and graduation quote leg | exact transfer semantics for arbitrary ERC-20s; source adds checks on critical paths |
| Solana relayer/guardian (Doorway) | record/attest/execute reference migration state | bridge settlement, token adapter, remote finality |

The exact links from files to diagram elements are carried by source markers in each `01-architecture` JSON/HTML. The remainder of the diagram collection is deliberately source-path-linked from its architecture index rather than repeating a non-source-backed URL claim.

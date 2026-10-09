# Source verification — 9 October 2026

Exact-source artifacts from the preserved deployed workspace were used. Every submitted source file was checked against its compiler metadata keccak256. Compiler: Solidity `0.8.26+commit.8a97fa7a`, optimizer 200, viaIR, Cancun; original remappings/settings retained. Deployed source SHA: `f0363249f4b74e58dde37d1241742ca5a92bcfe3`. Current frontend/reproducibility commits were not substituted.

All seven priority contracts have completed Sourcify verification with exact runtime matches. Individual JSON reports preserve job responses. Sourcify also returned external Etherscan verification jobs; those are separate from the confirmed Sourcify matches.

| Contract | Runtime match | Source verification |
| --- | --- | --- |
| KuruLiquidityLockV2 | exact_match | [Verified source](https://repo.sourcify.dev/10143/0x72ced84b20Bb8467c5547e3EbF85E62321B6a425) |
| RetroPickLaunchFactoryV2 | exact_match | [Verified source](https://repo.sourcify.dev/10143/0xa7f18b9eceb0A9852b08408854A45D00fc682454) |
| RetroPickLauncherTokenV2 | exact_match | [Verified source](https://repo.sourcify.dev/10143/0x43e7e9b1b7d9A143573307b13D14B51580c18f15) |
| RetroPickBondingCurveV2 | exact_match | [Verified source](https://repo.sourcify.dev/10143/0x454A3A449d4e65CA5203d331905d167BA218E276) |
| KuruGraduationExecutorV2 | exact_match | [Verified source](https://repo.sourcify.dev/10143/0xa2590ab344BAD0452c53958821A2B74f87871983) |
| GraduationCoordinatorV2 | exact_match | [Verified source](https://repo.sourcify.dev/10143/0xaD62309242EA65BB07C833669EC6a4ED23AF738F) |
| RetroPickQuoteAssetRegistryV2 | exact_match | [Verified source](https://repo.sourcify.dev/10143/0xd1211276869ec55CAF302E22371D2005B23B9B40) |

Source verification proves source/bytecode correspondence. It does not establish an audit, production safety or economic qualification.

API workflow: https://docs.sourcify.dev/docs/api/ (v2; the old v1 API is retired).

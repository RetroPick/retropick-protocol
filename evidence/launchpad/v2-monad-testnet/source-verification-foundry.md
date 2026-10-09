# V2 source verification — Foundry + Sourcify (BlockVision Monad)

Completed 2026-10-09. Scope: all 18 RetroPick-owned deployed instances of the V2
Monad Testnet release (chain `10143`, deployment block `69509526`, deployed source
`f0363249f4b74e58dde37d1241742ca5a92bcfe3`). Machine record:
`source-verification-foundry.json` (same directory).

Result: **18/18 runtime `exact_match` on both Sourcify stores** — the mandated
BlockVision Monad endpoint (`https://sourcify-api-monad.blockvision.org/`) and the
public Sourcify repository server (`https://sourcify.dev/server/`, published at
`https://repo.sourcify.dev/10143/<address>`). 15/18 also carry `exact_match`
creation-code matches; the three internally-created contracts (KuruLiquidityLockV2
demo, RetroPickMemeHookV2, RetroPickGraduationGuardV2/ExecutorDonationLockV2 at the
store level) show no stored creation match — their creation transactions are
internal calls, not EOA deploys.

This establishes source/bytecode correspondence only. It is not an audit, not a
production-safety claim, and not an economic qualification.

## Method

1. Built from the preserved deployed worktree
   (`codex/v2-monad-testnet-e2e` @ `a8a81f5`, parent = deployed source `f036324`).
   `forge build` green; artifacts pinned to `0.8.26+commit.8a97fa7a`, optimizer
   enabled/200 runs, `viaIR`, `cancun`, ipfs metadata hash — identical to the
   deployment manifest.
2. Local runtime-bytecode identity: `cast code` vs artifact `deployedBytecode` for
   all 18 contracts — **18/18 MATCH** with artifact `immutableReferences` masked
   (immutables are zeroed placeholders in artifacts, creation-filled on-chain).
3. Constructor arguments extracted authoritatively from broadcast
   `run-latest.json` creation-transaction inputs (creation-code prefix stripped;
   remainder = ABI-encoded args). Never guessed. Internal creations (hook via
   `hookDeployer.deploy(salt, poolManager, escrow, owner)`, guard and donation
   locks inside executor constructors) resolved from deploy-script source and the
   artifact/runtime match.
4. Verification submissions: `forge verify-contract --show-standard-json-input`
   produced the compiler standard-json; the Sourcify v2 API
   (`POST /v2/verify/{chainId}/{address}` with `stdJsonInput`,
   `compilerVersion`, `contractIdentifier`, `creationTransactionHash`) submitted it
   to both servers. Job status polled via `GET /v2/verify/{verificationId}`;
   publication confirmed via `GET /v2/contract/{chainId}/{address}`.

### Why the extra settings step was required

A plain `forge verify-contract --verifier sourcify --verifier-url
'https://sourcify-api-monad.blockvision.org/'` submission **works** (job
`60b4b206-bc17-49ad-83b4-4db7e0665f8f` for RetroPickFeeEscrowV2) but yields only a
partial `match`: forge's standard-json uses the clean repo remappings, while the
historical deployment build embedded **absolute-path remappings** auto-detected
from the nested `v4-deployment-periphery` project (recorded in the bundle
manifest's `compilerSettings`). Because Solidity's metadata hash covers the
settings, reproducing the deployed metadata requires replaying the original
`settings.remappings` and the minimal `settings.metadata = {"bytecodeHash":
"ipfs"}`. With those patched into the same forge-generated standard-json, every
contract reaches `exact_match`. No compiler setting was changed for any deployed
contract and no unrelated verifier was substituted.

## Verified contracts

| Contract | Role(s) | Address | Sourcify (BlockVision / public) |
| --- | --- | --- | --- |
| RetroPickLaunchFactoryV2 | factory | 0xa7f18b9eceb0A9852b08408854A45D00fc682454 | exact_match / exact_match |
| GraduationCoordinatorV2 | coordinator | 0xaD62309242EA65BB07C833669EC6a4ED23AF738F | exact_match / exact_match |
| KuruGraduationExecutorV2 | kuruExecutor | 0xa2590ab344BAD0452c53958821A2B74f87871983 | exact_match / exact_match |
| RetroPickQuoteAssetRegistryV2 | quoteRegistry | 0xd1211276869ec55CAF302E22371D2005B23B9B40 | exact_match / exact_match |
| RetroPickLauncherTokenV2 | demo.token | 0x43e7e9b1b7d9A143573307b13D14B51580c18f15 | exact_match / exact_match |
| RetroPickBondingCurveV2 | demo.curve | 0x454A3A449d4e65CA5203d331905d167BA218E276 | exact_match / exact_match |
| KuruLiquidityLockV2 | demo.lpLock | 0x72ced84b20Bb8467c5547e3EbF85E62321B6a425 | exact_match / exact_match |
| RetroPickHookDeployerV2 | hookDeployer | 0x09fC0edEEBf13C171eE5739eac6B9C7f3400C9B8 | exact_match / exact_match |
| RetroPickMemeHookV2 | hook (CREATE2) | 0x6d70125c61aD8f1a6d85eA4C37c94680b42f2044 | exact_match / exact_match |
| RetroPickBuybackVaultV2 | buybackVault | 0x2D746643E0BA37F127b38A4C04866a123895BE09 | exact_match / exact_match |
| RetroPickLaunchLockerV2 | locker | 0x7bb3aA1e48490F810e3F1eEC1Dda52D1F4d76A19 | exact_match / exact_match |
| RetroPickFeeEscrowV2 | feeEscrow | 0xb0312b0412c3BAa11895A6c4FeeC7CD9A01c2D96 | exact_match / exact_match |
| KuruEnvironmentV2 | kuruEnvironment | 0xAD59b3ff498d76DbC68351DaD4391D250b1E1Ba1 | exact_match / exact_match |
| UniswapV4GraduationExecutorV2 | v4Executor | 0xCB4670e7D2146A9Ca4541C383844b281Cf53Edb1 | exact_match / exact_match |
| RetroPickLaunchDeployerV2 | launchDeployer | 0x14080b43f3d45B47AEefF3bC1b0bee0cf0cCF5d8 | exact_match / exact_match |
| RetroPickGraduationGuardV2 | v4Guard | 0x1f1cbe81f6f0abd8165cdf691700f64ec36339a8 | exact_match / exact_match |
| ExecutorDonationLockV2 | kuruDonationLock | 0xbcd997c476be3ca0a1608804c9ad55c7ebd5271c | exact_match / exact_match |
| ExecutorDonationLockV2 | v4DonationLock | 0xf2aacba1ca0b6683023f437900314419d4aeca3b | exact_match / exact_match |

## Explicitly not submitted

Third-party contracts are not RetroPick-owned source and were not published as
such: WETH, Permit2, PoolManager, PositionDescriptor, PositionManager (Uniswap v4
deployment periphery artifacts), the Kuru environment (Router, MarginAccount,
OrderBook, KuruAMMVault) and Circle test USDC. Their ABIs and provenance are
labeled `UPSTREAM_*` / `EXTERNAL_INTERFACE_ONLY` in `apps/abi/manifest.json`.

## Blockers and caveats

- Sourcify's Etherscan (Monadscan) external-verification push hit the public
  server's daily submission limit ("Daily limit of 500 source code submissions
  reached"), so the Monadscan UI mirror may lag for the newly submitted
  contracts. Monadscan pages are additionally Cloudflare-gated for automated
  browsers in this environment; explorer publication was therefore confirmed via
  the Sourcify v2 contract APIs of both stores rather than the Monadscan UI.
- BlockVision's direct API rejects default tool User-Agents (Cloudflare 1010);
  submissions require a browser-like UA. `forge`'s own client passes unchanged.
- Creation-match gaps for internally-created contracts are a Sourcify
  store-coverage artifact, not a bytecode discrepancy — local creation-input
  prefix checks and runtime identity all matched (see machine record).

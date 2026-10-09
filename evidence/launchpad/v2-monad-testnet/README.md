# RetroPick V2 Monad Testnet E2E evidence

Completed 2026-10-09. Scope: TESTNET / HACKATHON, `TESTNET_POLICY_V1`.

Deployed source SHA: `f0363249f4b74e58dde37d1241742ca5a92bcfe3`. Delivery branch: `codex/v2-monad-testnet-e2e`.

Release gates: **145 passed, 0 failed, 0 skipped**. Fresh production fork block: **69507986**. Factory artifact and actual onchain runtime: **23,423 bytes**, below the 23,500-byte target. All newly deployed candidate/shared dependencies are below EIP-170. The pre-existing external Kuru OrderBook implementation is 35,548 bytes and is not deployed by this release.

The full V4 and Kuru MON/Circle fork paths passed. The suite includes exact Python/Solidity completion arithmetic, mutation liveness, authority, failed secure, external execution/verification/deposit/LP faults, replay, immutable launch policy, multiple-ledger conservation, forced donations and protected custody. Local invariant runs used 64 runs and 64 depth. Fork inputs are mandatory; missing RPC fails rather than passing a skipped fork.

Unsigned deployment simulation passed before keystore access. Current official Kuru testnet addresses, public Router getters, runtime code hashes and offchain proxy implementation slots were rechecked before broadcast. Signers came from the authorized external keystores; secret contents were not emitted.

First deployment block: **69509526**. Deployment: **32 confirmed successful transactions**. MON smoke: **PASS / GRADUATED**, 4 confirmed transactions. Two-actor order/fill/cancel: **PASS**, 7 confirmed transactions.

Canonical Circle live smoke: **BLOCKED_FUNDING**. Both authorized actors had zero canonical Circle test USDC. No KURU_TEST_USDC substitution was made. This is the only remaining live-smoke blocker; the MON testnet E2E objective is achieved.

## Deployed addresses

| Component | Address |
| --- | --- |
| buybackVault | `0x2D746643E0BA37F127b38A4C04866a123895BE09` |
| coordinator | `0xaD62309242EA65BB07C833669EC6a4ED23AF738F` |
| factory | `0xa7f18b9eceb0A9852b08408854A45D00fc682454` |
| feeEscrow | `0xb0312b0412c3BAa11895A6c4FeeC7CD9A01c2D96` |
| hook | `0x6d70125c61aD8f1a6d85eA4C37c94680b42f2044` |
| hookDeployer | `0x09fC0edEEBf13C171eE5739eac6B9C7f3400C9B8` |
| kuruEnvironment | `0xAD59b3ff498d76DbC68351DaD4391D250b1E1Ba1` |
| kuruExecutor | `0xa2590ab344BAD0452c53958821A2B74f87871983` |
| launchDeployer | `0x14080b43f3d45B47AEefF3bC1b0bee0cf0cCF5d8` |
| locker | `0x7bb3aA1e48490F810e3F1eEC1Dda52D1F4d76A19` |
| owner | `0xB505cBaab3ACdF287af1366b9B1229404757913b` |
| permit2 | `0x10301c3690501cF1a7c27300de4779E695DEDaE1` |
| poolManager | `0xD18dE14a0DB8adc66fd9c1CB9B960dea02c5D3c9` |
| positionDescriptor | `0xB0769a3517f31b324cb5C0f7ca337F2239796532` |
| positionManager | `0x3eb4cB7B07EbeDe7A2A508e4cf0D9e575dC449a9` |
| quoteRegistry | `0xd1211276869ec55CAF302E22371D2005B23B9B40` |
| v4Executor | `0xCB4670e7D2146A9Ca4541C383844b281Cf53Edb1` |
| wrappedNative | `0xff437B117Ec17a79a3b24Da4B5047dca4da9D0a2` |
| kuruDonationLock | `0xbcd997c476be3ca0a1608804c9ad55c7ebd5271c` |
| v4DonationLock | `0xf2aacba1ca0b6683023f437900314419d4aeca3b` |
| v4Guard | `0x1f1cbe81f6f0abd8165cdf691700f64ec36339a8` |

## External Kuru identities

| Component | Address |
| --- | --- |
| router | `0x7EFbE105Ca7415dE98F96622173458ac1c054630` |
| marginAccount | `0xd029C2D98ff85D8F64799017fE00a59B1159CE02` |
| orderBookImplementation | `0x72caE0a99C19B574e8a6De558F43fc1D019c9374` |
| vaultImplementation | `0x4d54e0d60CaB0cec0100cdA8e00897bC933C5Bb6` |

Official addresses: https://docs.kuru.io/contracts/Contract-addresses. Pinned Kuru source: https://github.com/Kuru-Labs/Kuru-contracts-dex-public/tree/2060bb2736080c175d80d568bfdb6226bb5abd04. V4 deployment periphery pin: `9969eec44cfdf07e24b41de47f40276a58401976`; nested core `59d3ecf53afa9264a16bba0e38f4c5d2231f80bc`; Permit2 `cc56ad0f3439c502c246fc5cfcc3db92bb8b7219`.

## MON launch and custody

| Component | Address |
| --- | --- |
| token | `0x43e7e9b1b7d9A143573307b13D14B51580c18f15` |
| curve | `0x454A3A449d4e65CA5203d331905d167BA218E276` |
| market | `0x1F5dE72616a7fe645Cf45aC66dfce8Ac7452C57F` |
| vault | `0xc88DED06eB0081430Ff02d124C22b532e122CbE7` |
| lpLock | `0x72ced84b20Bb8467c5547e3EbF85E62321B6a425` |

Secured/consumed quote: `1000000000000000002` raw MON. Secured/consumed launch tokens: `500000000000000000000` raw units. Protected LP shares: `15811388300841895683`. Protected excess: `249999999999999999751` raw token units. Vault MarginAccount credited base: `250000000000000000249`; credited quote: `1000000000000000002`. Both vault totalAssets values match these credits. No assertion that quote is physically held in the vault is used.

Independent post-broadcast RPC reads verified Coordinator GRADUATED, nonzero destination/receipt, conservation, closed Curve, exact permanent lock balances/bindings, Router market registration, executor and Coordinator allowances zero, no executor residual, Coordinator physical quote and liability zero, registry MON/Circle version 1 with venue mask 3, and both worker Coordinator bindings. Duplicate completion reverted with `WrongPhase()` in a read-only call. No duplicate live transaction was sent.

## Market usability smoke

Actor A deposited one launch token; actor B deposited 0.01 MON. Order `1` sold 0.1 token at raw price `398019`. Actor B received `99700000000000000` raw tokens after the 30 bps taker fee. Actor A placed order `2` and cancelled it; the base refund was verified. Confirmed OrderCreated, Trade and OrdersCanceled events are in the manifest. Final best bid/ask (1e18 price scale): `3960396039603960` / `4000000000000000`. Protected LP/excess balances remained unchanged. Trading residuals stay credited to the respective actors in MarginAccount. This is a usability smoke, not a market-quality claim.

## Transaction hashes

| Campaign | Block | Function | Hash |
| --- | --- | --- | --- |
| deployment | 69509526 | RetroPickQuoteAssetRegistryV2 | `0x1f9a01d22c123280386b92143de80381567d69553f0edcac62ed2c245bb9ec0e` |
| deployment | 69509529 | RetroPickFeeEscrowV2 | `0xc929564b8e35fc9b5c4ac26d3057e25da5e4006f2e81d8bb41ba05c7f147221d` |
| deployment | 69509537 | CREATE | `0x064193421f852573d04b789f6ca55bcc2e62b5d1c4bb2aa4719dcf805508a78f` |
| deployment | 69509539 | CREATE | `0x1272cdd1c743ac1a09553337fe3437465ce49ed7b295376c13e4bc7290d3aa9d` |
| deployment | 69509542 | CREATE | `0xa009325164f5641ecbf736e247c99010a9354226aa8a9fd32e97d4fa80e1fa36` |
| deployment | 69509544 | CREATE | `0xb4f9c44631d96ee851310c618358f1e3f57e3499ca95f5cfff14daec192bd99d` |
| deployment | 69509547 | CREATE | `0xb699b50c779760067e93ae0cd2c9a7a9c1cee79490e1468e2e5916b2f12a3f81` |
| deployment | 69509556 | RetroPickHookDeployerV2 | `0x961a307c17abb69bf5a69e8064fa0b791aa449b37aa79be5107d529f411e8ace` |
| deployment | 69509563 | deploy(bytes32,address,address,address) | `0x05c304e8a4e4a52de63ed6563a15de29d267c733b81ebb0d048d46bca5f7892f` |
| deployment | 69509570 | RetroPickBuybackVaultV2 | `0x16038bce5135a771f0e8b8df823af3c8a9c925874a6d93123d234c60f19fe518` |
| deployment | 69509576 | RetroPickLaunchLockerV2 | `0xcdd7cea5041f3e88ebe010900d4cee8b46187372cbb3ae9ccabb055467658677` |
| deployment | 69509582 | KuruEnvironmentV2 | `0x21af852c483d24cdc9523c60ca2280626afd1f11b16a3371a3d8f26cd7bc8897` |
| deployment | 69509589 | GraduationCoordinatorV2 | `0xbcb20ccb0929c76871643a40cee2c28930e754790411164377666089bfae3103` |
| deployment | 69509592 | KuruGraduationExecutorV2 | `0x26fec38358cf4494339d57928884a519244b1aedc62d94fc2b5ad53aff526e7e` |
| deployment | 69509600 | UniswapV4GraduationExecutorV2 | `0x27702abe416b7a062c9a7a13ff62e4d59fc7a8b7cbf49a183c58ffa0c6426f72` |
| deployment | 69509603 | configure(address,(bool,uint8,uint8,uint32,uint256,uint256,uint256,bytes32,bytes32)) | `0x8b81d682bfbe9fd8617f830e5ffdf533209c46d85f96f30b4e58d31d9edc8e7e` |
| deployment | 69509612 | configure(address,(bool,uint8,uint8,uint32,uint256,uint256,uint256,bytes32,bytes32)) | `0x076e1910d1a1d63540e747ce30a2819f4e001ab0e706431678e1083503af6d44` |
| deployment | 69509621 | RetroPickLaunchFactoryV2 | `0xe527db201adcf2bc6192e80806c37caae12214474e5bdf1b88cb4604e9d93b72` |
| deployment | 69509627 | RetroPickLaunchDeployerV2 | `0xc9776e4246cd0b1123d40ca810dc8b585d686f054608fb92107386f06464142b` |
| deployment | 69509633 | bindFactory(address) | `0x547af165a19504d79bdc27e78293dc80be37a7e0fd6b7827a5791b5446075303` |
| deployment | 69509638 | setLaunchDeployer(address) | `0xaf97c7bddb0aaa2b8a84208fabc7e44504db55c3ebb5d05711d541b522d0071e` |
| deployment | 69509641 | configureVenueExecutor(uint8,address) | `0xd2f109d233273f68e00f5ae02b912646072e9967828ee31fae9857d072455f0d` |
| deployment | 69509643 | configureVenueExecutor(uint8,address) | `0x32bbb1b6ea896228c69243d71bf65fa73945ef525729fb53ee2e059b21eb8ba2` |
| deployment | 69509646 | setFactory(address) | `0xd4e37c054c8891082e29040fcce2ec22b361a719008dac3f5c49e2406cd71d0d` |
| deployment | 69509652 | setBuybackVault(address) | `0x028f7bca7b0cf6d25edb94a69ee245cbcce7ce584ebe3c540d5ef64136b461ed` |
| deployment | 69509658 | setGraduationExecutor(address) | `0xf90f20dbf07bbf5ee9d619140dd23611449449217e6073954612715dc7790be4` |
| deployment | 69509661 | setFactory(address) | `0x5b57222af5af0493407a0afe4dbf5cbc0a557bcabba2f203ab469279ec913f33` |
| deployment | 69509669 | setFactory(address) | `0xbc81b72fd90c7dec2c6afbdaed3c9acb8c3879153f37d61bc4d38d228b1b2214` |
| deployment | 69509672 | setGraduationExecutor(address) | `0x6d628c47a1a1e58cc893ba6bc00e333bd57a87e009d60c5d9b51f4d9964a3ccb` |
| deployment | 69509674 | addLaunchConfig((uint256,uint256,uint256,uint256,uint24,int24,bool)) | `0x5107fc516d6335a66831f9e722397a02294f71106550b4928f85341349114672` |
| deployment | 69509677 | setSnipeTaxStartBps(uint256) | `0x35b0fab7e17f98d400c14263abf6af970dc134da06caec44521c5896e7b560c8` |
| deployment | 69509679 | setLaunchEnabled(bool) | `0x3bc149832c304dbca7105716b762ce4bb439a4f2acb96103d9fec181ca276381` |
| MON | 69510104 | launchToken((string,string,string,string,(string,string,string,string,string),address,uint16,bool,bytes32,bytes32),uint256,address,uint8) | `0x5cc1d0469ee7b811139055a81f2ba85a49a3de5b8ea54e158426693a556271f3` |
| MON | 69510112 | buy(uint256,uint256,address) | `0x41627a9090bd0fbdac03126457de8b3bc60a29486c70efffd18f71997596a926` |
| MON | 69510115 | buy(uint256,uint256,address) | `0x422096188305dfbca449b3eaf9ff4ad9da179e895e25853cee7aa30d9b98f184` |
| MON | 69510121 | complete(address) | `0x70d0cb480e7824ca9af62eaa5cb8d246a352efc6f2ba3585119c8bc64fa63fde` |
| trading | 69510700 | approve(address,uint256) | `0xde9d50172b99428d0129259b4d9f33e831b491772938e0a0ddb0fbc042a9fd72` |
| trading | 69510708 | deposit(address,address,uint256) | `0xa831416ca168cbc2d7d3103c56bdb2fb56befb1d09f3b4bf926b2609f00b8202` |
| trading | 69510711 | addSellOrder(uint32,uint96,bool) | `0xabd44f6922c652f0043658bf86f7d72e5cc550d4755a001cfd8d1c519ae515b7` |
| trading | 69510714 | deposit(address,address,uint256) | `0xdcf9aaac4b28a7103322c875771ed25f6f4d3dc0874c779882c28aa6d0a6048a` |
| trading | 69510717 | addBuyOrder(uint32,uint96,bool) | `0x93e056ca41c8f55022c2030f4ecaade5775187fc443e8b98f7ddac7a65855415` |
| trading | 69510725 | addSellOrder(uint32,uint96,bool) | `0xc49a70eff3f496fcdaa720ab03bc0fe122573141a421d2efbc16d51d88b8f6e7` |
| trading | 69510729 | batchCancelOrders(uint40[]) | `0x471faeb38c8598fc7207cb97c18a550db989e6d43bf0ce23b3539ea7920ac920` |

## Artifacts and handoff

- [Confirmed manifest](../../../deployments/monad-testnet/v2.json): addresses, source SHA, blocks, all 43 successful transaction hashes, Kuru environment, quote policy versions, exact amounts, events and independent verification.
- [Release gates](release-gates.json), [test log](forge-test.log), [size log](forge-sizes.log), [deployment simulation](deployment-simulation.log), [deployment broadcast](deployment-broadcast.log).
- [MON simulation](mon-smoke-simulation.log), [MON broadcast](mon-smoke-broadcast.log), [trade simulation](trade-simulation.log), [trade broadcast](trade-broadcast.log).
- [Release instructions](../../../contracts/script/README_V2_MONAD_TESTNET.md).

Large integer manifest values use decimal strings to preserve exactness for JavaScript clients. A post-broadcast evidence-reader assertion initially compared a Foundry decimal string to a Python integer; the reader was fixed and the already-confirmed MON receipts recovered without another launch. No Solidity contract changed after deployment.

Factory is launch/config authority; Coordinator packet/ledger/events are lifecycle authority. Existing Factory graduation fields are derived compatibility views. Integrators should use `Factory.launchToken(params, configId, quoteAsset, venue)` and `Coordinator.complete(token)`. Venue and policy snapshots cannot be changed by retry callers. Registry enables only MON and canonical Circle today; future owner onboarding remains an explicit qualification/configuration flow, without Factory redeployment. Frontend categories do not confer onchain authority.

Original unrelated local modifications remain in the original checkout. Delivery used a separate worktree. Main was not merged; no readiness statuses or accepted research ADRs were promoted.

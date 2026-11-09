# RetroPick

**The market creation layer for Monad.**

RetroPick is an onchain launchpad with bonding-curve issuance, graduation and venue integrations. This monorepo contains distinct lifecycle layers: maintained application code, active V2 contracts, a **frozen Monad Testnet V2 demonstration**, research prototypes and reproducible release evidence. The historical Kuru deployment demonstrates a specific release; it must not be treated as proof of all current V2/V3 designs or unrestricted mainnet readiness.

## Current code and architecture

| Area | Maintained entry point | Status |
| --- | --- | --- |
| Product frontend | [`apps/retro-ui`](apps/retro-ui/) | Canonical Vite + React app |
| Contract SDK and ABI | [`packages/launchpad-sdk`](packages/launchpad-sdk/) · [`apps/abi`](apps/abi/) | Typed wallet boundary; ABI catalog is derived |
| Read models / services | [Indexer](apps/indexer/) · [Media](apps/media-service/) · [Referrals](apps/referral-service/) | Offchain support; no custodial economic writes |
| Active Launchpad V2 Solidity | [`contracts/src/v2`](contracts/src/v2/) | Financial changes require isolated qualification |
| Frozen V2 testnet source | [`contracts/legacy-v2`](contracts/legacy-v2/) | Immutable deployment provenance |
| Historical frontend | [`apps/web`](apps/web/) | **Read-only / zero-write** |
| Visual design donor | [`apps/example-ui-ux`](apps/example-ui-ux/) | Reference, not deployed product authority |
| PRISM / V3 research | [PRISM](docs/prism/) · [research](research/) | Separate qualification, not automatically production |

Start with [documentation navigation](docs/README.md), [contributor guide](CONTRIBUTING.md), [contracts guide](contracts/README.md), and the [rehabilitation audit](docs/maintenance/README.md). For safe changes, see [cleanup decisions](docs/maintenance/CLEANUP_DECISIONS.md) and [test status](docs/maintenance/VALIDATION_REPORT.md).

## Maintainer entry points

For local setup, code ownership, verification and safe changes, read [CONTRIBUTING.md](CONTRIBUTING.md), [apps ownership](apps/README.md), and the [2026-11-09 repository audit](docs/maintenance/REPOSITORY_AUDIT.md). The earlier [hygiene audit](docs/engineering/REPOSITORY_HYGIENE_AUDIT.md) remains historical context. The canonical frontend is `apps/retro-ui`, not the read-only historical `apps/web`. Root `pnpm dev`, `pnpm build`, and `pnpm check` operate on the maintained workspace paths; historical Next.js commands are explicitly named `*:legacy-web`.

## Run the web app

Node 24+ is recommended for full-workspace development (root minimum >=22.13); use pnpm 11.25.0:

```sh
pnpm install --frozen-lockfile
cp apps/retro-ui/.env.example apps/retro-ui/.env.local
pnpm dev  # canonical apps/retro-ui
pnpm check:app  # UI typecheck/tests/build
pnpm check:services  # SDK + indexer + media + referral (Node 24+)
```

The canonical frontend is `apps/retro-ui`. Configure its documented live data mode and public read infrastructure; never put credentials or signing keys in a browser environment. Wallets sign normal economic writes directly to chain. `apps/web` is legacy and excluded from this submission's demo and implementation work.

```sh
pnpm --filter @retropick/retro-ui typecheck
pnpm --filter @retropick/retro-ui build
```

Contracts require Foundry, recursive submodules, the separately built v4/Permit2 dependencies and a funded RPC endpoint for mandatory fork tests. See [contract setup](contracts/README.md) and [release evidence](evidence/launchpad/v2-monad-testnet/README.md). Never commit signing keys.

## Historical Monad Testnet demo and provenance

The following descriptions, deployment addresses and transaction receipts document the **frozen V2 Monad Testnet candidate**. They are historical proof, not current liquidity, security-audit or production claims.

## Smart contracts for hackathon judges

Review the [frozen Legacy V2 smart contracts](contracts/legacy-v2/src/v2/) for the deployed Monad Testnet submission, including its Kuru integration. The [archive guide](contracts/legacy-v2/README.md) and [source manifest](contracts/legacy-v2/MANIFEST.json) identify the recorded deployed revision: `f0363249f4b74e58dde37d1241742ca5a92bcfe3`.

[Factory](contracts/legacy-v2/src/v2/RetroPickLaunchFactoryV2.sol) · [Bonding curve](contracts/legacy-v2/src/v2/RetroPickBondingCurveV2.sol) · [Coordinator](contracts/legacy-v2/src/v2/GraduationCoordinatorV2.sol) · [Kuru executor](contracts/legacy-v2/src/v2/KuruGraduationExecutorV2.sol) · [Permanent liquidity lock](contracts/legacy-v2/src/v2/KuruLiquidityLockV2.sol)

Ongoing V2 development in `contracts/src/v2/` is separate from this frozen judging snapshot. The live deployment addresses and historical proof transactions below remain unchanged.

## Recorded Monad Testnet capabilities

The canonical deployed candidate demonstrates:

- ✅ Token issuance and bonding-curve buy/sell
- ✅ Safe graduation and real Kuru market creation
- ✅ Permanent custody for graduation LP shares and excess tokens
- ✅ Permissionless completion/retry
- ✅ Live testnet limit order, fill and cancel

[Open the canonical live frontend](https://retropick.xyz/launchpad). Historical team functional-test receipts demonstrate launch, curve trading, Kuru graduation and two-wallet order/fill/cancel; they are not organic volume or present orderbook depth. Fresh desktop/mobile checks and the current video status are recorded in the [submission readiness report](docs/metropolis/submission-20261014/READINESS_REPORT.md). The founder-recorded pitch remains founder-owned. Canonical Circle-USDC live smoke: **BLOCKED_FUNDING**.

[Judge overview](HACKATHON.md) · [Evidence map](docs/hackathon/EVIDENCE_MAP.md) · [Full deployment manifest](deployments/monad-testnet/v2.json) · [Metropolis requirements](docs/hackathon/METROPOLIS_REQUIREMENTS.md)

## Why Monad?

RetroPick produces two active phases: rapid bonding-curve transactions and post-graduation orderbook trading. Low-cost execution, fast settlement and responsive market state matter when many primary markets and secondary orderbooks operate simultaneously. This connects asset primitives, market infrastructure and settlement to Metropolis's Onchain Finance & Trading track.

## Kuru's role in the recorded demo

RetroPick specializes in issuance, creator distribution, primary discovery and graduation safety. Kuru supplies the secondary orderbook, limit orders and market-making workflows. Our demo created an actual Kuru market, seeded its vault and executed an order, fill and cancel. Depth, spreads and execution quality remain market-dependent; neither integration nor permanent custody guarantees trading outcomes.

## Deployed proof

| Component | Monad Testnet address |
| --- | --- |
| Factory | [0xa7f18b9eceb0A9852b08408854A45D00fc682454](https://testnet.monadexplorer.com/address/0xa7f18b9eceb0A9852b08408854A45D00fc682454) |
| Coordinator | [0xaD62309242EA65BB07C833669EC6a4ED23AF738F](https://testnet.monadexplorer.com/address/0xaD62309242EA65BB07C833669EC6a4ED23AF738F) |
| Demo token | [0x43e7e9b1b7d9A143573307b13D14B51580c18f15](https://testnet.monadexplorer.com/address/0x43e7e9b1b7d9A143573307b13D14B51580c18f15) |
| Bonding curve | [0x454A3A449d4e65CA5203d331905d167BA218E276](https://testnet.monadexplorer.com/address/0x454A3A449d4e65CA5203d331905d167BA218E276) |
| Kuru market | [0x1F5dE72616a7fe645Cf45aC66dfce8Ac7452C57F](https://testnet.monadexplorer.com/address/0x1F5dE72616a7fe645Cf45aC66dfce8Ac7452C57F) |
| Kuru vault | [0xc88DED06eB0081430Ff02d124C22b532e122CbE7](https://testnet.monadexplorer.com/address/0xc88DED06eB0081430Ff02d124C22b532e122CbE7) |
| Permanent LP/excess lock | [0x72ced84b20Bb8467c5547e3EbF85E62321B6a425](https://testnet.monadexplorer.com/address/0x72ced84b20Bb8467c5547e3EbF85E62321B6a425) |

Six concise proof transactions: [launch](https://testnet.monadexplorer.com/tx/0x5cc1d0469ee7b811139055a81f2ba85a49a3de5b8ea54e158426693a556271f3), [bonding buy](https://testnet.monadexplorer.com/tx/0x41627a9090bd0fbdac03126457de8b3bc60a29486c70efffd18f71997596a926), [graduation](https://testnet.monadexplorer.com/tx/0x70d0cb480e7824ca9af62eaa5cb8d246a352efc6f2ba3585119c8bc64fa63fde), [order](https://testnet.monadexplorer.com/tx/0xabd44f6922c652f0043658bf86f7d72e5cc550d4755a001cfd8d1c519ae515b7), [fill](https://testnet.monadexplorer.com/tx/0x93e056ca41c8f55022c2030f4ecaade5775187fc443e8b98f7ddac7a65855415), [cancel](https://testnet.monadexplorer.com/tx/0x471faeb38c8598fc7207cb97c18a550db989e6d43bf0ce23b3539ea7920ac920). These are functional testnet transactions, not organic adoption.

[Verified contract sources — seven exact runtime matches](evidence/hackathon/metropolis/SOURCE_VERIFICATION.md).

## Engineering depth

Factory → single-ledger Coordinator → venue executor keeps lifecycle authority separate from venue work. Architectural extraction reduced Factory runtime from approximately 24,565 to **23,423 bytes**. Exact integer terminal-quote constraints preserve completion liveness across valid trade histories; graduation LP/excess assets enter a permanent bound lock. Native/Circle Uniswap v4 compatibility remains in the release campaign.

Historical predeployment campaign: **145 passed / 0 failed / 0 skipped**, fresh qualification fork **69,507,986**. [Release artifacts](evidence/launchpad/v2-monad-testnet/README.md). Deployed bytecode source: `f0363249f4b74e58dde37d1241742ca5a92bcfe3`; main integration baseline: `84861f50494a79772cf6f97a5e710bcc24973d5e`. Current repository release verification is recorded separately; source SHA is not a live readiness claim.

## Hackathon scope and attribution

Pre-existing foundations include V1/shared Solidity dependencies and the visual frontend prototype. V2 delivery introduced Coordinator extraction, policy snapshots, completion liveness, Kuru graduation/protected custody, V4 migration and deployment/smoke tooling. This submission release connects the live frontend and judge evidence. Build-window claims must be assessed from public commit history; this repository is not entirely new hackathon code.

AI-assisted tools were used for engineering, testing and documentation; maintainers remain responsible for review and claims. Third-party notices: [contracts](contracts/THIRD_PARTY_NOTICES.md), dependency licenses and frontend package/vendor notices. Original project source uses the [MIT license](LICENSE); [third-party licenses](THIRD_PARTY_NOTICES.md) remain applicable.

[Submission copy](docs/hackathon/SUBMISSION_COPY.md) · [Demo](docs/hackathon/DEMO_SCRIPT.md) · [Pitch](docs/hackathon/PITCH_SCRIPT.md) · [Q&A](docs/hackathon/JUDGE_QA.md) · [Partnership plan](docs/hackathon/MONAD_PARTNERSHIP.md) · [Growth](docs/hackathon/GROWTH_PLAN.md)

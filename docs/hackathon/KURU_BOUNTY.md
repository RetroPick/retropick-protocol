# Kuru bounty case

Primary target: [Bring New Assets and Markets to Kuru](https://hackathon.monad.xyz/tracks/bring-new-assets-and-markets-to-kuru), $5,000 single award. Secondary conditional target: [Build the Next Consumer Trading App on Kuru](https://hackathon.monad.xyz/tracks/build-the-next-consumer-trading-app-on-kuru), $5,000 single award. Verified 9 October 2026; [requirements](METROPOLIS_REQUIREMENTS.md).

RetroPick is upstream market-origination infrastructure: creator/community ERC20 issuance → bonding price discovery → Kuru market creation → first vault deposit → permanently protected graduation assets → orderbook trading. It does not add a speculative new asset class to satisfy a bounty.

| Requirement | Feature / source | Address / transaction evidence | Demo scene / status |
| --- | --- | --- | --- |
| Beyond trading UI | Factory → Coordinator → executor; `contracts/src/v2/RetroPickLaunchFactoryV2.sol`, `GraduationCoordinatorV2.sol` | Factory `0xa7f18b9eceb0A9852b08408854A45D00fc682454`; [launch](https://testnet.monadexplorer.com/tx/0x5cc1d0469ee7b811139055a81f2ba85a49a3de5b8ea54e158426693a556271f3) | Create token; issuance PASS |
| Issuance and settlement | `RetroPickLauncherTokenV2.sol`, `RetroPickBondingCurveV2.sol` | Token `0x43e7e9b1b7d9A143573307b13D14B51580c18f15`; curve `0x454A3A449d4e65CA5203d331905d167BA218E276` | Bonding buy; exact onchain settlement PASS; no issuer redemption promise |
| Initial market formation | `KuruGraduationExecutorV2.sol`, `KuruParameterPolicyV2.sol` | [completion](https://testnet.monadexplorer.com/tx/0x70d0cb480e7824ca9af62eaa5cb8d246a352efc6f2ba3585119c8bc64fa63fde); market `0x1F5dE72616a7fe645Cf45aC66dfce8Ac7452C57F` | Graduation; actual Kuru market PASS |
| Liquidity strategy | First vault deposit, `KuruLiquidityLockV2.sol` | Vault `0xc88DED06eB0081430Ff02d124C22b532e122CbE7`; lock `0x72ced84b20Bb8467c5547e3EbF85E62321B6a425`; manifest custody measurements | Launch Proof; permanent initial custody PASS; sustained depth not guaranteed |
| Real execution | Kuru OrderBook / MarginAccount, `TradeV2KuruTestnet.s.sol` | [order](https://testnet.monadexplorer.com/tx/0xabd44f6922c652f0043658bf86f7d72e5cc550d4755a001cfd8d1c519ae515b7), [fill](https://testnet.monadexplorer.com/tx/0x93e056ca41c8f55022c2030f4ecaade5775187fc443e8b98f7ddac7a65855415), [cancel](https://testnet.monadexplorer.com/tx/0x471faeb38c8598fc7207cb97c18a550db989e6d43bf0ce23b3539ea7920ac920) | Two-wallet testnet order/fill/cancel PASS; not organic volume |
| Customer / demand | Creators/communities; early traders and liquidity participants | [Founder-reported demand register](DEMAND_EVIDENCE.md), [X](https://x.com/RetroPickMarket) | 30+ signups / ~300K engagements reported; analytics pending; no confirmed pilots |
| Legal / operations | Testnet only; token rights and promotion require issuer-specific review before expansion | [Partnership roadmap](MONAD_PARTNERSHIP.md) | No blanket compliance claim; no unsupported RWA integration |
| Continuation | Qualified assets, SDK/API, creator onboarding, market-quality measurement | [Growth plan](GROWTH_PLAN.md) | Future plan; not deployed functionality |
| Consumer application | Existing UI adapted to live MON/Kuru flow, `apps/web/features/live/` | [Fresh public-frontend wallet campaign](../../evidence/hackathon/metropolis/frontend-e2e-trading.json) | MON launch/graduation/order/fill/cancel PASS; demand and retention remain unproven |

## Why Kuru benefits

Every successfully graduated RetroPick market creates a Kuru destination with initial liquidity. More qualified creator launches could bring more markets, traders and orderbook activity. This is a proposed ecosystem flywheel, not current adoption or volume. Kuru handles mature execution; RetroPick supplies asset origination and primary discovery.

## Qualification risks to disclose

The primary bounty asks for a new class of markets and evidence of demand. Creator/community token infrastructure is our actual scope; judges may consider asset novelty insufficient. Founder reports show early audience interest, not verified commercial commitments. Do not claim interviews, partnerships, market-maker agreements, revenue or real-user volume. The secondary bounty requires a stable working consumer app and an acquisition/retention case; historical contract smoke alone is insufficient.

Complete technical proof: [deployment manifest](../../deployments/monad-testnet/v2.json), [release evidence](../../evidence/launchpad/v2-monad-testnet/README.md), [judge evidence map](EVIDENCE_MAP.md).

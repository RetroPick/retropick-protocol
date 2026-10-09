# Judge evidence map

Historical source and release identifiers are distinct. Main integration baseline: `84861f50494a79772cf6f97a5e710bcc24973d5e`. Deployed bytecode source: `f0363249f4b74e58dde37d1241742ca5a92bcfe3`. Preserved delivery branch: `codex/v2-monad-testnet-e2e`, HEAD `a8a81f544311301cde1788fafdb275f21c2ff639`.

| Claim | Authoritative proof | Limits |
| --- | --- | --- |
| Deployed Monad Testnet V2 | [Manifest](../../deployments/monad-testnet/v2.json), all addresses and 43 transactions | Testnet only |
| Issuance | [Launch](https://testnet.monadexplorer.com/tx/0x5cc1d0469ee7b811139055a81f2ba85a49a3de5b8ea54e158426693a556271f3), Factory event | Not creator adoption |
| Bonding buy | [Buy](https://testnet.monadexplorer.com/tx/0x41627a9090bd0fbdac03126457de8b3bc60a29486c70efffd18f71997596a926) | Functional test trade |
| Single secure ledger | [Final buy / secure](https://testnet.monadexplorer.com/tx/0x422096188305dfbca449b3eaf9ff4ad9da179e895e25853cee7aa30d9b98f184), Coordinator ledger | GRADUATING then atomic completion |
| Real Kuru graduation | [Completion](https://testnet.monadexplorer.com/tx/0x70d0cb480e7824ca9af62eaa5cb8d246a352efc6f2ba3585119c8bc64fa63fde), receipt and market/vault getters | Historical environment snapshot; mutable Kuru must be rechecked |
| Permanent protected custody | [Lock](https://testnet.monadexplorer.com/address/0x72ced84b20Bb8467c5547e3EbF85E62321B6a425), `KuruLiquidityLockV2.sol`, manifest LP/excess balances | Protects graduation assets; not every liquidity source |
| Real order | [Order transaction](https://testnet.monadexplorer.com/tx/0xabd44f6922c652f0043658bf86f7d72e5cc550d4755a001cfd8d1c519ae515b7), OrderCreated | Two-actor smoke |
| Real fill | [Fill transaction](https://testnet.monadexplorer.com/tx/0x93e056ca41c8f55022c2030f4ecaade5775187fc443e8b98f7ddac7a65855415), Trade | No organic-volume claim |
| Real cancel | [Cancel](https://testnet.monadexplorer.com/tx/0x471faeb38c8598fc7207cb97c18a550db989e6d43bf0ce23b3539ea7920ac920), OrdersCanceled | Actual order state/event evidence |
| Factory 23,423 runtime bytes | [Size artifact](../../evidence/launchpad/v2-monad-testnet/forge-sizes.log), [release gate](../../evidence/launchpad/v2-monad-testnet/release-gates.json) | Historical candidate; current release needs its own build |
| 145 / 0 / 0 tests | [Full test log](../../evidence/launchpad/v2-monad-testnet/forge-test.log), release gate, historical fork 69,507,986 | Not an audit; current campaign recorded separately |
| Completion liveness | `RetroPickBondingCurveV2.sol`, Python differential vectors and V2 tests | Exact integer constraint within qualified testnet policy |
| V4 compatibility | V2 native/Circle success/failure/retry tests and full release campaign | Not a live V4 adoption claim |
| Circle live | Manifest: BLOCKED_FUNDING | Do not substitute KURU_TEST_USDC or claim PASS |
| Demand | [Evidence register](DEMAND_EVIDENCE.md) | Founder-reported figures pending validation; no commitments |

Canonical contracts: [Factory](https://testnet.monadexplorer.com/address/0xa7f18b9eceb0A9852b08408854A45D00fc682454), [Coordinator](https://testnet.monadexplorer.com/address/0xaD62309242EA65BB07C833669EC6a4ED23AF738F), [token](https://testnet.monadexplorer.com/address/0x43e7e9b1b7d9A143573307b13D14B51580c18f15), [curve](https://testnet.monadexplorer.com/address/0x454A3A449d4e65CA5203d331905d167BA218E276), [market](https://testnet.monadexplorer.com/address/0x1F5dE72616a7fe645Cf45aC66dfce8Ac7452C57F), [vault](https://testnet.monadexplorer.com/address/0xc88DED06eB0081430Ff02d124C22b532e122CbE7).

Fresh release/browser/source-verification evidence is recorded under `evidence/hackathon/metropolis/`. A source file or screenshot alone does not prove a live wallet transaction succeeded.

Source verification: [seven exact runtime matches](../../evidence/hackathon/metropolis/SOURCE_VERIFICATION.md). Fresh current campaign: [145/0/0, fork 69,560,382 and strict sizes](../../evidence/hackathon/metropolis/qualification.json). [Public frontend](https://retropick-metropolis.vercel.app) reads the canonical ledger/custody/orderbook; [fresh wallet E2E](../../evidence/hackathon/metropolis/frontend-e2e-launch.json) and [two-actor trading](../../evidence/hackathon/metropolis/frontend-e2e-trading.json) pass. [Watch real transaction footage · 2:48](https://retropick-metropolis.vercel.app/launchpad/demo).

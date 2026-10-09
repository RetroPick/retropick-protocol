# Launchpad V2 Monad testnet release

This branch implements the user-authorized hackathon candidate. Its economics are
`TESTNET_POLICY_V1`, not a production economic policy. Only native MON and canonical
chain-10143 Circle test USDC (`0x534b2f3A21130d7a60830c2Df862319e593943A3`) are configured.
The Kuru compatibility asset `0x3bA3d39AFcf8bb994f7964B3e0171Ea2Ba361570` is `KURU_TEST_USDC`.

Factory creates/configures launches. Coordinator is the sole mutable graduation
ledger and custody authority. `graduate(token)` secures once; permissionless
`Coordinator.complete(token)` executes the immutable venue atomically. Failed
completion preserves GRADUATING and assets; successful replay fails before movement.
Factory's legacy `getLaunchedToken` graduation fields are derived compatibility
views. Integrators should index Coordinator's packet, ledger and graduation events.

Curve applies an exact, venue-independent immediate-completion quote ceiling to
reserve mutations. Quote entries and worker selection are snapshotted per launch;
prospective registry/worker changes do not alter existing launches. Kuru LP and
excess tokens are permanently locked. V4 NFT positions and excess tokens remain
protected in the Locker; quote dust is credited through FeeEscrow. Unsolicited worker
assets go into separate permanent donation custody and never enter another launch.

Build the pinned full V4 dependencies before running the release gates:

```sh
git submodule update --init --recursive contracts/lib/v4-deployment-periphery
cd contracts
forge build --root deployment-v4 --sizes --skip test --skip script
(cd lib/v4-deployment-periphery/lib/permit2 && forge build --sizes --skip test --skip script)
python3 script/release_v2_monad.py gates --env-file /absolute/path/to/authorized.env
python3 script/release_v2_monad.py deploy --env-file /absolute/path/to/authorized.env
python3 script/release_v2_monad.py smoke --env-file /absolute/path/to/authorized.env
python3 script/release_v2_monad.py circle --env-file /absolute/path/to/authorized.env
python3 script/release_v2_monad.py trade --env-file /absolute/path/to/authorized.env
python3 script/release_v2_monad.py record --env-file /absolute/path/to/authorized.env
```

Commit source before `gates`; broadcast rejects a changed source SHA. The external
environment supplies RPC, actor addresses, keystore paths and password-file paths.
No key/password is embedded in scripts, manifests or logs. The keystore is opened
only after tests (zero skips), fresh forks, strict runtime sizes and unsigned
deployment simulation pass. Current public Kuru getters/code identities and offchain
proxy implementation slots must still match. Runtime contracts never read private
EIP-1967 slots. Gas caps use 120 gwei with a 3 gwei priority fee against the current
100 gwei testnet base fee; insufficient funding or a changed environment fails closed.

Unsigned/intermediate JSON in `contracts/` is not deployment evidence. Confirmed
receipt status, addresses, blocks, transaction hashes and source SHA are merged into
`deployments/monad-testnet/v2.json`. Logs and gate snapshots live under
`evidence/launchpad/v2-monad-testnet/`. Circle live smoke requires canonical funding;
an unfunded path is recorded as `BLOCKED_FUNDING`, even when its fork passes.
The optional two-actor trading script deposits one launch token from actor A and
0.01 MON from actor B, fills a 0.1 token maker ask inside the AMM spread, then
places and cancels a second ask. It simulates before signing and checks margin
credits, cancellation refunds, protected custody and final best bid/ask. Residual
trading deposits remain credited to their actors in the Kuru MarginAccount.

The minimum launch profile is 1,000 tokens, phantom quote and threshold one quote
unit, ceiling 50 quote units, 100 bps curve fee, zero creator tax and no buyback.
Kuru parameters are protocol-derived, not creator-supplied. This candidate does
not establish production, audit or mainnet readiness, and does not promote the
older research/status readiness gates.

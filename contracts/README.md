# RetroPick V2 contracts — Monad Testnet candidate

The deployed hackathon candidate supports native MON / canonical chain-10143 Circle-USDC policies, immutable venue snapshots, bonding trading, one Graduation Coordinator ledger, venue-specific Kuru and Uniswap v4 execution, and permanently protected Kuru graduation assets.

Native MON → Kuru and two-actor order/fill/cancel: **PASS** in the recorded live campaign. Canonical Circle-USDC live smoke: **BLOCKED_FUNDING**. Local/fork Circle qualification is separate. This is unaudited testnet code; staging/mainnet gates remain blocked.

[Deployment manifest](../deployments/monad-testnet/v2.json) · [Historical release](../evidence/launchpad/v2-monad-testnet/README.md) · [Judge evidence](../docs/hackathon/EVIDENCE_MAP.md).

## Architecture and release identity

Factory → LaunchDeployer → Token/Curve; Factory → Coordinator → Kuru/V4 executor. The Coordinator is lifecycle and ledger authority; executors perform venue work. Historical Factory runtime: 23,423 bytes, below EIP-170 and the 23.5KB extraction target.

Deployed source: `f0363249f4b74e58dde37d1241742ca5a92bcfe3`. Repository release commits can differ because of frontend/docs/reproducibility fixes. Explorer source verification must use exact deployed source/settings, not assume a current checkout is the same bytecode.

## Reproduce

Install Foundry and initialize dependencies from repository root:

```sh
git submodule update --init --recursive
cd contracts
forge build --root deployment-v4 --sizes --skip test --skip script
(cd lib/v4-deployment-periphery/lib/permit2 && forge build --sizes --skip test --skip script)
python3 test/v2/tools/generate_completion_vectors.py --check
forge fmt --check
FOUNDRY_CODE_SIZE_LIMIT=1048576 forge build --sizes
MONAD_TESTNET_RPC_URL=https://testnet-rpc.monad.xyz MONAD_V2_FORK_BLOCK=<fresh-qualified-block> FOUNDRY_CODE_SIZE_LIMIT=1048576 forge test
forge build --sizes --skip test --skip script
```

Use a reliable provider; mandatory fork qualification cannot be reported PASS when RPC is missing. The large size limit is for deployment-embedding test/script harnesses. Deployable runtime gates remain strictly EIP-170 (24,576 bytes), with Factory ≤23,500.

`script/release_v2_monad.py` uses authorized external environment/keystores and never prints private keys. Its original artifacts are historical release evidence; record new qualification separately under `evidence/hackathon/metropolis/`. Never overwrite historical source identities or Circle funding status.

V1 and Doorway are reference code; they do not independently qualify V2. Dedicated `test/v2/` unit, differential, invariant, integration and fork suites provide the V2 campaign. Prediction/PRISM retain independent gates.

See [third-party notices](THIRD_PARTY_NOTICES.md). No audit or unrestricted mainnet authorization is implied.

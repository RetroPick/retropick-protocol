# Environments

**Status:** DRAFT  
**Owner:** Release + Integrations

| Environment | Purpose | Requirements |
|---|---|---|
| Local | deterministic development/test | Anvil/local dependencies, seeded actors |
| Monad staging/test environment | integration and demo qualification | verified current chain/RPC/deployments, funded deployer/demo wallets |
| Production/mainnet target | real release | explicit security/legal/operations authorization |

For each environment record chain ID, RPC provider, explorer, deployer/owner roles, contract version/addresses, quote assets, Kuru configuration, indexer/API/frontend endpoints and feature flags.

Values that can change are configuration, not copied across prose docs.

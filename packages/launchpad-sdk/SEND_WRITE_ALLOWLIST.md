# Same-chain Send extension

This campaign's requested Send operation adds two narrowly scoped wallet writes to the existing security-reviewed user write boundary. It does not change the approval-spender or protocol-write allowlist.

- Native MON: connected wallet sends exact user-reviewed value to a nonzero EVM recipient on Monad Testnet 10143. Fresh preparation validates balance, estimated network gas and recipient; the execution pipeline rechecks connected account/network and simulates the receiver before signing.
- ERC20 `transfer(address,uint256)`: a verified RetroPick launched token or currently admitted quote asset, exact user-reviewed amount and recipient, `msg.value = 0`, no approval. Fresh preparation verifies protocol asset membership, wallet balance, simulated true return and MON for gas. Execution repeats transfer simulation and verifies true return before signing.

Only `prepareTransfer` creates this transfer descriptor. The UI presents the selected asset, exact recipient, amount and explicit Monad Testnet network before asking the wallet to sign. User custody remains in the wallet. No transferFrom, arbitrary calldata, bridge, exchange deposit guarantee or bank/card flow is added.

For protocol writes, the existing exact-value matrix, per-launch curve/MarginAccount approval restrictions, margin-funded Kuru policy and banned admin/upgrade/LP/forwarder surfaces continue to apply. A transfer simulation is never cached across changed account, input or chain state.

Validation: `test/productization.test.ts` covers rejected zero recipient, insufficient MON for gas, false-return tokens, and existing write-boundary regressions. Live receipt qualification is recorded in campaign evidence rather than inferred from these tests.

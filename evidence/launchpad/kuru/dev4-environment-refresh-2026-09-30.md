# Kuru DEV-4 environment refresh — 2026-09-30

**Classification:** read-only source/RPC identity check, not a complete environment or market-availability proof. Git baseline `ef53422c8a5b96baf28e718bb9211733f08e2372`; Monad Testnet chain ID `10143`; RPC state pinned at block **66,853,809**. No transaction was sent.

Official public GitHub `main` still reports Kuru contracts commit `2060bb2736080c175d80d568bfdb6226bb5abd04` and SDK commit `636509c2eafd63479d3f399703354e0d09f51e18` via `gh api`. The [official Kuru testnet address page](https://docs.kuru.io/contracts/Contract-addresses) still lists Router `0x7EFbE105Ca7415dE98F96622173458ac1c054630`, MarginAccount `0xd029C2D98ff85D8F64799017fE00a59B1159CE02` and its **separate** test-token `USDC` address `0x3bA3d39AFcf8bb994f7964B3e0171Ea2Ba361570`. That token is not RetroPick's canonical Circle test-USDC identity.

Block-pinned RPC getters and code:

| Check | Result |
| --- | --- |
| Router `marginAccountAddress()` | `0xd029C2D98ff85D8F64799017fE00a59B1159CE02` |
| Router `orderBookImplementation()` | `0x72caE0a99C19B574e8a6De558F43fc1D019c9374` |
| Router `kuruAmmVaultImplementation()` | `0x4d54e0d60CaB0cec0100cdA8e00897bC933C5Bb6` |
| Router runtime `keccak256(code)` | `0xae572ec3ca9b5f49c0364ca34edc5880b6b2837e47802e64e6b681bf2e74aa5c` |
| OrderBook implementation runtime hash | `0x24c5974f233021f00d607bfa191d430f79565663fb90805ebcfca52de7333500` |
| Vault implementation runtime hash | `0xde0b16a79cf8f711403e89093c1e82ce0e7813949dd0f5041b41da324fdd3dc3` |
| Canonical Circle test-USDC address | `0x534b2f3A21130d7a60830c2Df862319e593943A3`; `decimals() = 6`, runtime hash `0x96215e6049ed615cdc22fea7701e85458a8e51a2df3e7d45e8f9fa1d521b5a78` |

The offchain `eth_getStorageAt` read of the EIP-1967 implementation slot at this block yielded Router implementation `0xAAa0f0C4d49d09EF33Ae758d88AFab810ECBE1Ed`. The **same standard slot on Circle's token proxy was zero**, despite the prior fork trace showing a delegatecall implementation. Do not infer Circle is non-upgradeable from a zero EIP-1967 slot; its proxy layout/issuer authority needs separate qualification. Most importantly, no production Solidity can `SLOAD` either external slot. Runtime executor checks are limited to accessible Router identity/getters/code and independently verified market/vault/asset state. Re-read this manifest before any later fork or live operation; a future external upgrade invalidates this snapshot.

Reproduction: after exporting the existing `.env.local` in the `contracts` process environment, use `cast call`, `cast code --block 66853809`, `cast storage --block 66853809` and `cast keccak` for the addresses/getters above. `cast codehash` was unavailable on this RPC (`Method not found`), so the runtime bytes were fetched with `eth_getCode` through `cast code` and hashed locally. No secret contents were displayed.

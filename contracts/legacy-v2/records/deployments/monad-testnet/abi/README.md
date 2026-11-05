# Monad Testnet deployed ABI bundle

ABI arrays are exported verbatim from full compiler artifacts, including constructors, overloaded functions, events, errors, receive and fallback entries when present. No bytecode or signer data is included.

- [manifest.json](manifest.json): deployed address → ABI, provenance, SHA-256, compiler settings, coverage and dynamic discovery templates.
- [function-event-map.json](function-event-map.json): every function signature/selector, event topic/indexed inputs and error selector.
- [FUNCTIONS.md](FUNCTIONS.md): readable inventory.

RetroPick source: `f0363249f4b74e58dde37d1241742ca5a92bcfe3`. All contract addresses in the release manifest are mapped. Owner is an EOA; native MON is not an ERC20.

Kuru source: `2060bb2736080c175d80d568bfdb6226bb5abd04`. The official SDK ABI omits `OrderBook.getL2Book(uint32,uint32)`, so full ABIs are compiled from the qualified contract source instead. Compilation uses Solidity 0.8.30, Prague, via IR, optimizer 1000; OpenZeppelin `fcbae5394ae8ad52d8e580a3477db99814b9d565` and Solady `acd959aa4bd04720d640bf4e6a5c71037510cc4b`. These are interface exports, not a claim of reproduced Kuru deployed bytecode or immutable external implementations. Kuru proxy addresses use the implementation's callable ABI. Runtime checks remain mandatory.

**Circle USDC is explicitly interface-only:** its qualified ERC20/metadata functions are supplied in `ERC20MetadataInterface.json`; its complete external proxy/implementation ABI has not been independently established. This is not KURU_TEST_USDC.

Regenerate from the preserved deployed worktree and pinned Kuru repositories:

```sh
python3 scripts/launchpad/export_deployed_abis.py \
  --deployed-worktree /path/to/deployed-worktree \
  --kuru-sdk /path/to/pinned-kuru-sdk \
  --kuru-contracts /path/to/pinned-kuru-contracts
node packages/launchpad-sdk/scripts/catalog-abis.mjs
python3 -m unittest scripts/launchpad/test_abi_export.py
```

Kuru compile artifacts must exist under `abi-out/<Contract>.sol/<Contract>.json`. The exporter records dependency/source commits and checks local RetroPick source against the deployed commit. Shared SDK const exports and indexer events derive from this bundle. The inventory does not authorize admin/custody calls or automatically expose every write as a frontend action.

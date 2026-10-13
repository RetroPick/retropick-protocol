---
name: retropick-agent-wallet
description: Inspect RetroPick launch lifecycle and Kuru market reads through the MetaMask Agent Wallet CLI. Use for configured market discovery, market inspection, or explainable book risk on Monad Testnet.
metadata:
  cli-version: 6.2.1
  chain-id: "10143"
  status: read-only
---

# RetroPick market reads

Use the installed MetaMask Agent Wallet `mm` CLI plugin to inspect the configured RetroPick launch on Monad Testnet. This skill accompanies a real oclif plugin; a skill file alone does not install commands.

## Check the host

Run `mm --version` and `mm doctor`. This distribution was prepared against CLI 6.2.1, with `minCliVersion: ^6.2.0`. Record the installed version rather than assuming compatibility with later major releases.

The current commands inherit the host's authentication and initialization requirements. If the host reports unauthenticated or uninitialized, return that blocker to the operator. Login, wallet provisioning, keys, passwords, and MFA remain under the operator's control. Plugin installation is separate from wallet authorization.

## Install the reviewed read-only distribution

The scoped `metropolis-metamask-readonly-20261014` Git branch packages only three commands: `retropick markets`, `retropick market inspect`, and `retropick market risk`. Each declares empty `capabilities` and `dataAccess`; the distribution contains no order execution commands.

Check `package.json` and `oclif.manifest.json` before installation. Use the host's supported plugin installation flow and review its consent screen. Git and local-directory sources require the host's explicit development opt-in; the CLI should refuse when that opt-in is absent. Keep that refusal intact. See the [official installation guide](https://docs.metamask.io/agent-wallet/plugins/install-a-plugin/).

```bash
mm plugins install 'https://github.com/RetroPick/retropick-protocol#metropolis-metamask-readonly-20261014'
mm plugins inspect @retropick/mm-plugin-readonly
```

Where the CLI's Git resolver fails, an operator can clone that exact branch, install its locked dependencies, and use the documented local-development link flow:

```bash
git clone --branch metropolis-metamask-readonly-20261014 --single-branch https://github.com/RetroPick/retropick-protocol retropick-mm-readonly
cd retropick-mm-readonly
npm ci --ignore-scripts
mm plugins link "$PWD"
```

Installation is complete only when the host lists the plugin and resolves the three command IDs. An install failure or an auth error is evidence of that state, not a successful integration demo.

## Read the configured market

```bash
mm retropick markets
mm retropick market inspect 0x43e7e9b1b7d9A143573307b13D14B51580c18f15
mm retropick market risk 0x1F5dE72616a7fe645Cf45aC66dfce8Ac7452C57F
```

`markets` reads the Coordinator ledger and graduation receipt for the source's configured token allowlist. It currently lists one evidenced token; it does not discover every RetroPick launch. Preserve the returned phase and market address. Phase 2 is the graduated case recognized by this implementation.

`market inspect` reads that token's ledger, the mapped Kuru market's `bestBidAsk`, and the head block. Unknown tokens are refused. Preserve integer values as decimal strings. The output fields are named `bestBidX18` and `bestAskX18` by the current implementation; independently verify deployed market precision before converting them into human prices. A returned bid or ask is not a guarantee of executable liquidity.

`market risk` explains the returned bid/ask factors. It does not fetch trade history: its `lastTradeBlock` input is currently null. Its message `no observed trades yet` means this command lacks a historical observation, not that the market has never traded. Report unknown history as unknown.

For each successful read, record the command, CLI version, UTC time, token/market, returned block when present, and actual output. Complete the task with verified observations and explicit unavailable data. Historical team transactions and an empty present book are separate facts.

## Canonical source limitations

The canonical integration lives at `integrations/metamask-agent-retropick` in the main RetroPick repository. This distribution preserves the three selected command implementations from source SHA `8f5f022fb53e763a3ebb2b9c54abfb1cccf00d61`; `SOURCE-PROVENANCE.json` records the copied source hashes. It changes packaging, not financial behavior.

The full canonical integration also declares these commands, which are intentionally excluded from this read-only distribution:

| Command | Current behavior |
| --- | --- |
| `retropick order quote <market> <buy\|sell> <priceX18> <sizeBaseRaw>` | Read-only policy proposal. Its `getMarketParams` ABI has 12 outputs, while the deployed canonical market tuple has 11; live precision/quote compatibility remains unverified. It supplies zero available margin and must not be described as an executable funded quote. |
| `retropick wallet exposure <market>` | Reads the first BYOK wallet's Kuru margin when that wallet exists. An empty returned address with zero strings means no wallet observation, not a verified zero balance. |
| `retropick order place …` | **Write execution NOT IMPLEMENTED.** Always returns `placed: false`; provisioning alone cannot make this build submit an order. |
| `retropick order cancel <market> <orderId> <owner>` | **Write execution NOT IMPLEMENTED.** Always returns `cancelled: false`. The supplied owner comparison is not an onchain order ownership lookup. |

The pure policy tests cover allowlists, amount caps, alignment, age/lag bounds, margin checks, and supplied signer identity. They do not prove live book freshness, supported wallet submission, MFA completion, or successful onchain trading. A future write path needs independently reviewed deployed ABI/units, actual order ownership, the supported MetaMask executor, operator approval, and confirmed receipts.

Use this skill for reads only. Economic actions remain unavailable in this build; no private-key export, signing, approval grant, transaction broadcast, or MFA bypass is part of the workflow.

## References

- [MetaMask plugin architecture and manifest](https://docs.metamask.io/agent-wallet/plugins/build-a-plugin/)
- [Canonical RetroPick integration](https://github.com/RetroPick/retropick-protocol/tree/main/integrations/metamask-agent-retropick)
- [Live RetroPick product](https://retropick.xyz)

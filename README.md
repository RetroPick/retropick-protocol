# RetroPick MetaMask read-only plugin distribution

This standalone distribution exposes three public-chain RetroPick oclif commands through MetaMask Agent Wallet 6.2.1: configured markets, market inspection, and explainable book risk. It requests no wallet capabilities or data access. Supported per-command configuration makes these public reads available without login or wallet initialization; host plugin consent and beta gates remain active.

The selected TypeScript implementations derive from `RetroPick/retropick-protocol` source SHA `8f5f022fb53e763a3ebb2b9c54abfb1cccf00d61`, with explicit public-read auth/init configuration. Prebuilt command bundles are included. `SOURCE-PROVENANCE.json` records source paths, hashes, and corrections; dependency versions are locked.

Read [the agent skill](skills/retropick-agent-wallet/SKILL.md) for command usage, installation, and current limitations. The full canonical plugin's order quote ABI remains unverified, and place/cancel submission is not implemented. This read-only distribution excludes those commands and the wallet exposure command.

Three actual installed CLI reads passed at 2026-10-13T23:16:54Z–23:17:07Z with the host still unauthenticated and uninitialized. The market's named Coordinator tuple decoded to phase 2 and the expected Kuru market. The inspection returned head block 70809470; risk reported a quoted spread of 99 bps, unknown staleness, and unqueried history. Best quotes may include vault/AMM prices and do not establish resting order depth. The local-link test used the same installed host SDK peer to avoid the CLI 6.2.1 duplicate-SDK development-link issue.

This branch is a standalone distribution, not an application merge candidate. No npm publication, wallet setup, signing, or transaction is part of its public read workflow. Installation and successful public reads do not prove qualifying wallet trading.

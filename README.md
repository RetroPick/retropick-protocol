# RetroPick MetaMask read-only plugin distribution

This standalone distribution exposes three existing RetroPick oclif commands through MetaMask Agent Wallet 6.2.1: configured markets, market inspection, and explainable book risk. It requests no wallet capabilities or data access. Authentication and initialization requirements remain inherited from the host CLI.

The selected TypeScript implementations, context, and policy were copied unchanged from `RetroPick/retropick-protocol` source SHA `8f5f022fb53e763a3ebb2b9c54abfb1cccf00d61`. Prebuilt command bundles are included. `SOURCE-PROVENANCE.json` records source paths and hashes; dependency versions are locked.

Read [the agent skill](skills/retropick-agent-wallet/SKILL.md) for command usage, installation, and current limitations. The full canonical plugin's order quote ABI remains unverified, and place/cancel submission is not implemented. This read-only distribution excludes those commands and the wallet exposure command.

This branch is a standalone distribution, not an application merge candidate. No npm publication, wallet setup, signing, or transaction is needed to inspect its source. Real CLI execution may require operator login and initialization. Installation and an authentication error do not prove qualifying wallet trading.

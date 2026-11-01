# Venue Registry V3 — research proof (NOT deployable launchpad)

**Status: UNQUALIFIED / RESEARCH ONLY.** Canonical V2 source, chain 10143 deployment and production/hackathon release claims remain unchanged.

This directory tests one narrow architectural property: a Factory that depends on a small **registry interface** can accept a NEW venue AFTER the Factory is deployed, without changing its factory runtime bytecode.

The `VenueRegistryV3.sol` prototype:
- is an onchain, chain-local admission directory, not an execution router or custody vault;
- registers `bytes32 venueId + uint32 version` under owner control;
- pins the adapter address, runtime code hash, policy hash and settlement category;
- forbids overwriting an existing version;
- supports irreversible disablement **for new admission only**;
- preserves inactive historical records for audits;
- checks the registry deployment chain ID to avoid accidental reuse on another network.

The test file `test/v3-research-experiment/VenueRegistryV3.t.sol` contains a deliberately small Factory *harness*, not a full launchpad. It verifies that late venue registration does not change Factory address, runtime code size or runtime code hash, and existing launch snapshots remain unchanged across new versions or deactivation.

## Not proven

This proof does NOT execute bonding-curve purchases, secure reserves, create a Kuru/Uniswap pool, initialize HIP-1/HIP-2 native markets, verify custody, or satisfy V2/V3 differential tests. It is not audited, not mainnet-ready and not authorization to replace V2 or deploy with real user funds.

In particular: V2's Kuru/V4 executors are ALREADY separately deployed. The next production-shaped work is **removing V4-specific constructor/runtime dependencies from a parallel V3 Factory**, replacing its fixed `GraduationVenue` enum / two-bit quote policy, and qualifying a venue-neutral coordinator + receipt model.

## Verify (on a machine with Foundry, solc 0.8.26 and initialized submodules)

```sh
cd contracts
forge fmt --check
forge test --match-path test/v3-research-experiment/VenueRegistryV3.t.sol -vvv
forge build --sizes --skip test --skip script
```

Record actual output and artifact hashes. No Forge compiler or Foundry execution evidence is included in this research commit.

Read `decisions/ADR-024-modular-venue-registry-and-chain-aware-graduation.md` and `.agents/skills/retropick-venue-adapter-engineering/SKILL.md` before expanding beyond this proof.

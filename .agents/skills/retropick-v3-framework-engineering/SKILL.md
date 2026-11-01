---
name: retropick-v3-framework-engineering
description: Research, refactor, qualify and deploy the chain-aware, venue-neutral RetroPick Launchpad V3 smart-contract framework without inlining external DEX integrations. Use when building FactoryV3, quote/venue registries, graduation custody, chain profiles, community economics or HyperEVM/HyperCore routes.
---

# V3 Framework Engineering — agent instructions

## Authority and status

Read in order:
1. `contracts/AGENTS.md`
2. `docs/architecture/launchpad/V3_ENGINEERING_LANDSCAPE.md`
3. `decisions/ADR-024-modular-venue-registry-and-chain-aware-graduation.md` (**PROPOSED**)
4. `.agents/skills/retropick-venue-adapter-engineering/SKILL.md`
5. `contracts/src/v2/RetroPickLaunchFactoryV2.sol`, `GraduationCoordinatorV2.sol`, `RetroPickQuoteAssetRegistryV2.sol`, `interfaces/IGraduationExecutorV2.sol`, `KuruGraduationExecutorV2.sol`, `UniswapV4GraduationExecutorV2.sol`
6. `development/launchpad/contracts/DEV4_GRADUATION_EXTRACTION_TECHNICAL_PACKET.md` and `docs/launchpad/INVARIANTS.md`

Everything in `contracts/src/v3-research-experiment/` is **unqualified**. This research framework does not issue real launch tokens, execute real V2 curves, deploy Uniswap/Kuru liquidity or activate HIP-1/HIP-2. **DO NOT** point production apps/wallets to these contracts.

## Architect's invariant

Adding venue N+1 to an existing EVM chain should require:
- a qualified, independently deployed adapter,
- a governance action to register immutable `venueId+adapterVersion`,
- a chain/venue/quote capability update to the manifest and SDK/indexer,
- relevant tests and staged rollout,

**not** changing the Factory runtime bytecode or migrating existing launch commitments.

Adding chain N+1 requires its own verified Factory, Coordinator, Registry, Quote Policy, venue modules and addresses. Do not imply cross-chain liquidity sharing without an accepted bridge/canonical supply design.

## Ownership / allowed changes

Research changes: `contracts/src/v3-research-experiment/**`, `contracts/test/v3-research-experiment/**`, `docs/architecture/launchpad/**`, new versioned deployment profiles and new evidence records.

Canonical `contracts/src/v2/**`, production manifests, V1, prediction and PRISM are READ-ONLY unless the user separately authorizes a scoped, accepted ADR and safety review. Do not silently merge PRs.

## Required engineering process

### A. Baseline
- Pin branch SHA, Foundry/solc/optimizer/via_ir settings, hashes of dependencies and exact V2 deployable artifacts.
- Re-run historical Foundry build-size commands before claiming a new size number.
- Classify existing V2 Kuru and Uniswap executors as **already separate**; identify mandatory V4 Factory constructor and wiring as remaining coupling.
- Record every current user-facing ABI/event/fee behavior that could change.

### B. Contract interface design
- Stable `bytes32 venueId` and positive version, no fixed enum branch for venues.
- Chain-local quote rule per venue/version/quote asset, with onchain decimal and behavior checks.
- Domain-separated immutable launch commitment containing creator, token, quote, sourceChainId, factory, venue/version/adapter/address/codehash, venue/quote/economics/community/config hashes, settlement class.
- Separate `IAtomicVenueExecutorV3` and `IAsyncSettlementVerifierV3`; no universal fake LP receipt.
- Use `LaunchCommitmentHubV3` only as a structural research kernel. A real V3 Factory must verify creator authorization, token identity, fixed-supply/deployer model, curve configuration, snipe policy, fees and bonding preconditions.

### C. Atomic escrow
- Correct one-time secure transition after the real primary curve stops trading.
- Sole ledger + exact token and quote balance deltas + per-asset liability reserve.
- No mixing assets from unrelated launches, broad approvals, arbitrary calls or delegatecall.
- Qualified adapter is pinned and authenticated; adapter may spend no more than allocated allowance.
- One transaction for destination create/seed/verify, retryable failure, replay rejection.
- Current research proof supports **ERC20 + full seed only**; production requires explicitly qualified native quote, partial seed, residual policy, authentic market/vault/LP receiver proof and duration/timeout review.
- External adapter proxy codehash alone does not freeze the implementation behind an upgradeable proxy; requalification/monitoring policy required.

### D. Multichain + HyperCore
- Chain profiles: actual chain ID, verified RPC, quote asset addresses, wrapped-native policy, native asset gas, available venues, implementation hashes, deployment order, explorer receipt, indexer finality.
- HyperEVM chain IDs from official docs: mainnet 999, testnet 998. HyperCore is not an EVM pool.
- HIP-1/2 require native spotDeploy registerToken2 -> userGenesis -> genesis -> registerSpot -> (optional) registerHyperliquidity, official funding and precision rules, proof and reconciliation. Do not call this an atomic Solidity `execute()`.
- Cross-chain routes add bridge security/finality/supply duplication risks; not a free 'switch chain' feature.
- Never infer current venue address or API capability. Verify sources at implementation time.

### E. Testing & approvals
1. `forge fmt --check` and `forge build --sizes --skip test --skip script`.
2. Research tests `forge test --match-path 'test/v3-research-experiment/*.t.sol' -vvv`; include N+1 after deployment, immutability, owner/chain/quote rules, unauthorized secure, failed completion/retry, duplicate completion, bad receipt, multi-launch backing and async rejection.
3. Real V2 launch/curve/Kuru/V4 differential unit/fuzz/invariant and fork tests once actual V3 is wired.
4. Target-chain integration and explorer verification with addresses and observable postconditions.
5. Compare runtime size and initcode by deployed artifact, not line count. Default EIP-170/EIP-3860 limits only where the chain adopts them. Distinguish mock/test harness code size limit from actual deployable limits.
6. Static analysis and third-party security review before any mainnet assets.
7. Explicit GO/NO-GO per chain/venue/quote pair; absent RPC, fork, oracle or funding = BLOCKED, never PASS.

## Handoff artifacts

Provide versioned ABI/event bundle, source and build hashes, deployment manifest, upgrade/pause/runbook, SDK capability map, indexer event and native status schema, full error taxonomy, threat model, measured bytecode size, test command/outputs, and incident recovery rules.

## Never do

- Build an enormous `if/else` venue switch in Factory.
- Add required Uniswap/Kuru concrete imports to Factory.
- Replace V2 deployments, promote V3 research to production or change launch economics without accepted policy.
- Overwrite old launch commitments when registry config changes.
- Permit arbitrary user-defined executable adapters or unrestricted manager approvals.
- Treat a returned receipt or backend signature as sufficient independent market proof.
- Use a fake LP position for native HIP-2.
- Claim 'no rug pulls' or 'no sniping' as a cryptographic guarantee.
- Add revenue/auto-buyback/community succession without rights, timing, accounting and governance proofs.

## Agent report format

```text
BASE COMMIT / TASK / GOAL
AS-IS V2 FINDINGS WITH SOURCE PATHS
ACCEPTED vs PROPOSED POLICY
ARCHITECTURE / CONTRACT TOPOLOGY
CHAIN+VENUE CAPABILITY MATRIX
SOURCE CHANGES
INVARIANT MAP AND THREAT MODEL
TEST AND COMPILER EVIDENCE (exact, or NOT RUN)
FACTORY RUNTIME+INITCODE BEFORE/AFTER (measured, or NOT RUN)
DEPLOYMENTS, ABIs, SDK+INDEXER CONSUMERS
REGRESSION, FORK AND ASYNC RECOVERY STATUS
REMAINING BLOCKERS
TESTNET GO/NO-GO / MAINNET GO/NO-GO
```

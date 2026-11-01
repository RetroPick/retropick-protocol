# ADR-024: Venue-neutral launch core and versioned chain-local venue registry

**Status:** PROPOSED — research-only, NOT accepted for release  
**Date:** 2026-11-01  
**Scope:** RetroPick Launchpad V3 architecture research; canonical V2 remains unchanged  
**Baseline:** `main` at `665dbff3054f627e3ebc4e5573334a062fa7ecad`  
**Related:** ADR-008, ADR-019, ADR-021, ADR-022, ADR-023, LP-I-001..012

## Decision proposed

Build one venue-neutral launch-core implementation per EVM network, with independently deployed and qualified venue modules. Adding a venue MUST NOT alter the core Factory's runtime bytecode or require upgrading an existing launch. A chain-specific deployment manifest controls which venue versions are actually admitted on each chain. Use a separate asynchronous settlement family for native HyperCore or cross-chain destinations.

This is **not** a proposal to deploy one global factory across chains, to load venue bytecode with delegatecall, to make every external pool permissionless, or to claim that installing a registry upgrades the deployed V2 Factory.

## Evidence: what V2 already does

- `contracts/src/v2/GraduationCoordinatorV2.sol` already keeps `mapping(GraduationVenue => address) public executors`, an authoritative secured-asset ledger, exact transfer checks, and per-launch executor/codehash pinning. `complete()` is a *single EVM transaction*.
- `KuruGraduationExecutorV2.sol` and `UniswapV4GraduationExecutorV2.sol` already exist as separate venue-specific contracts. **Do not re-extract code that is already separate.**
- `RetroPickLaunchFactoryV2.sol` nevertheless imports and requires V4 `IPoolManager`, `IPositionManager`, `IAllowanceTransfer`, locker, hook and buyback dependencies at construction; `_requireLaunchDependenciesWired` contains hook/manager checks. Legacy default `launchToken` overloads select `GraduationVenue.UNISWAP_V4`.
- `IGraduationExecutorV2.sol` defines a two-value `GraduationVenue` enum and universal `poolFee`, `tickSpacing`, `protectedLPAmount`, `positionId` semantics. These fields are not meaningful for every destination.
- `RetroPickQuoteAssetRegistryV2.sol` hardcodes chain 10143 and only accepts `venueMask <= 3`; it is not portable to a third venue or a new chain as-is.
- `contracts/script/DeployV2MonadTestnet.s.sol` deploys V4 infrastructure and the Kuru executor as one deployment profile. Deployment scripts select dependencies, but cannot remove already compiled factory dependencies.
- `contracts/README.md` records a **historical** Factory runtime of **23,423 bytes**, close to the standard EIP-170 24,576-byte limit. This is not a new compiler measurement or a guarantee that today's artifact has that exact size.

## Architecture boundaries

```text
RetroPick UI/SDK
    -> chain-local LaunchFactoryV3
          -> Token/Curve implementation (shared launch policy)
          -> GraduationCoordinatorV3 (sole onchain ledger)
                  -> VenueRegistryV3 (admission lookup at launch commit)
                  -> pinned IAtomicVenueExecutor (Uniswap, Kuru, ...)
                  -> AsyncGraduationEscrow / verifier family (HyperCore, bridges)
    -> indexer/API from chain-specific, pinned manifests
```

1. **Factory** creates and registers launches and authenticates curve callbacks. It may validate a typed commitment supplied by the caller, but MUST NOT import concrete Uniswap/Kuru venue implementations, construct venue-owned assets, or know a venue's routing ABI.
2. **VenueRegistry** is a chain-local, governance-controlled admission directory for *new launches*. Key by `(venueId, version)`; record executor/adapter, code hash, settlement class and policy hash. Existing versions are immutable; administrators can disable new admission, not rewrite old commitments.
3. **Coordinator** owns graduation custody and obligations and verifies external receipts. Pin `sourceChainId`, factory, launch ID, quote policy version, `venueId`, adapter version, adapter address/codehash, venue-policy hash and settlement kind in a domain-separated launch commitment before trading.
4. **Atomic adapters** execute only approved operations on the same EVM chain, with exact allowances and physical-balance verification. Retain V2's durable secure/atomic complete/retry behavior and qualified external venue checks.
5. **Async routes** MUST NOT satisfy a fake synchronous `execute()` by returning an optimistic HyperCore/bridge receipt. Require an explicit state machine, bounded authority, independently verifiable cross-environment checkpoints, supply and escrow conservation, and an accepted recovery design. No mainnet authorization from this ADR.
6. **Modules for creator/community economics** (fee splits, buybacks, burns, succession) are separate approved launch/fee modules, not venue routing logic. Revenue streams are capability-gated; do not promise hooks or LP receipts from venues that do not expose them.

## Hard invariants

- `factory runtime bytecode` is independent of the number of admitted venue entries.
- No unqualified or arbitrary EOA/contract can become a venue executor; registration is privileged and versioned.
- An existing launch pins its adapter and policy. Registry changes cannot silently redirect it.
- No executor can seize unrelated launches' collateral; per-launch balances/allowances and liability accounting must be independently tested.
- No duplicate graduation, reopens after terminal completion, or cross-venue rollback assumptions.
- No `delegatecall` to registered venue implementations.
- No approval based only on a returned event/receipt: verify external market state and physical assets.
- A venue's deactivation for **new** launches is distinct from emergency halting of committed launches; the latter needs its own explicitly accepted governance/recovery policy.
- One canonical launch ID is scoped to `sourceChainId + factory + launch nonce/token`; a venue ID alone is not a token identity or cross-chain bridge.
- Separate quote eligibility per `(chain, quote asset, venue version)`, not a fixed bitmask.

## Migration sequence — no in-place V2 mutation

**Gate 0: Baseline audit.** Pin the exact V2 compiler, optimizer, `via_ir`, dependency hashes, code sizes, test results and deployed manifest. Record baseline independently; do not rewrite historical receipts.

**Gate 1: Admission/immutability proof.** Research contract in `contracts/src/v3-research-experiment/VenueRegistryV3.sol` and tests demonstrate registering venue B/C after a minimal factory has been deployed, no factory bytecode change, immutable per-launch snapshots, versioning, disabling new admission, ownership and chain scoping. This is structural research, NOT audited production custody logic.

**Gate 2: Production-shaped V3 factory.** Preserve launch token/curve economics by differential testing V2 vs V3. Remove Uniswap-specific constructor/wiring and default Uniswap assumptions. Move fee policy dependence on V4 hook behind a venue-neutral, qualified interface. No existing V2 factory is upgraded.

**Gate 3: Atomic coordinator integration.** Port/adapt V2 secure + complete logic. Prove Kuru and Uniswap graduation with real destination-state tests, negative/retry tests, no collateral leak, no duplicate execution and deterministic pinning. New registry entries must not require factory code changes.

**Gate 4: Chain profiles.** Deploy isolated stacks with verified `chainId`, quote assets and dependencies. Start Monad testnet, then HyperEVM testnet. Deploy only the venues available and qualified on each chain; generated manifests drive SDK/indexer/QA.

**Gate 5: HyperCore research.** HIP-1 spot creation uses native multi-step `spotDeploy` operations; HIP-2 is native Hyperliquidity, NOT a Uniswap LP NFT. Define separate async transition, token-link/supply semantics and objective native proof sources. Never claim atomicity across native and EVM environments.

**Gate 6: Governance and release.** Accept a separate ADR for emergency handling and async recovery. Complete security review, integration/fork tests, testnet receipts and operator-runbook qualification before any mainnet funding.

## Test and build gates

From `contracts/`, after initializing required submodules:

```sh
forge fmt --check
forge test --match-path test/v3-research-experiment/VenueRegistryV3.t.sol
forge build --sizes --skip test --skip script
FOUNDRY_CODE_SIZE_LIMIT=1048576 forge test --match-path test/v2/invariant/GraduationCoordinatorV2Invariant.t.sol
```

Run the complete applicable V2 unit/fuzz/invariant/integration suite plus newly written V3 differential tests. The increased Foundry code-size limit is for test harnesses only; it is NOT an authorization to deploy oversized real runtime bytecode. Enforce each deployed contract's chain-specific runtime and initcode limits, with Factory target <= 23,500 bytes until a new accepted threshold is established. EIP-170's 24,576-byte and EIP-3860's 49,152-byte limits are the conservative EVM reference where adopted.

An **admission proof alone does not pass Gate 2/3**: the research harness performs no bonding trades, custody, liquidity seeding or actual graduation.

## Agent delivery requirements

All venue/chain PRs provide: pinned baseline commit, source/target chain IDs, venue + settlement class, verified addresses/bytecode, adapter version/policy, quote policy, capability matrix, launch and graduation receipts, exact commands and outputs, bytecode-size delta, threat model, test/invariant matrix, remaining risks and SDK/indexer ABI manifest changes. State unavailable external fork/RPC data as BLOCKED, not PASS.

## References

- `contracts/README.md`, `contracts/AGENTS.md`, `docs/launchpad/INVARIANTS.md`
- `development/launchpad/contracts/DEV4_GRADUATION_EXTRACTION_TECHNICAL_PACKET.md`
- `decisions/ADR-019-launchpad-non-upgradeability.md`, `ADR-023-kuru-graduation-atomic-retry-and-verification.md`
- EIP-170: https://eips.ethereum.org/EIPS/eip-170
- EIP-3860: https://eips.ethereum.org/EIPS/eip-3860
- HIP-1/HIP-2 deployment: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/deploying-hip-1-and-hip-2-assets

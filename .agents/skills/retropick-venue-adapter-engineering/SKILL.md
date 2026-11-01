---
name: retropick-venue-adapter-engineering
description: Design, implement, review and qualify new RetroPick launchpad venue adapters and chain deployments without growing the core factory or weakening graduation accounting. Use for Uniswap, Kuru, HyperEVM/HyperCore, or future venue work.
---

# Venue Adapter Engineering — RetroPick

## Scope and precedence

**Launchpad only** (token issuance, bonding and graduation). Do not mix this with prediction/PRISM. Read **first**:

1. `contracts/AGENTS.md` and `docs/launchpad/INVARIANTS.md`.
2. `decisions/ADR-008-retropick-launchpad-v2-development-line.md`, `ADR-019-launchpad-non-upgradeability.md`, `ADR-023-kuru-graduation-atomic-retry-and-verification.md`.
3. `decisions/ADR-024-modular-venue-registry-and-chain-aware-graduation.md` (**PROPOSED; not production authority**).
4. `contracts/src/v2/{RetroPickLaunchFactoryV2,GraduationCoordinatorV2,RetroPickQuoteAssetRegistryV2,KuruGraduationExecutorV2,UniswapV4GraduationExecutorV2}.sol`.
5. `contracts/src/v2/interfaces/IGraduationExecutorV2.sol`, `contracts/README.md` and the accepted venue-specific ADRs/manifest.

**Source truth:** Current V2 ALREADY deploys separate Kuru and V4 executors. Do not describe Kuru as inlined execution inside Factory, and do not repeat completed extraction. The remaining coupling includes mandatory V4 constructor dependencies, fixed two-venue enum/mask, V4-oriented receipt fields and synchronous completion.

## Mandatory decision tree

- New venue on an already supported EVM chain, with atomic settlement? Add independently deployed `IAtomicVenueExecutor` implementation; register an immutable version and test real external behavior.
- New EVM chain? Deploy a distinct core stack with verified per-chain runtime settings, quote tokens and venue adapters. Do **not** reuse state or addresses from another chain.
- HyperEVM -> HyperCore HIP-1/HIP-2? Use separately qualified native-system / async orchestration. No claim of atomic EVM execution or LP-NFT receipt. Identify auction, genesis, spot and Hyperliquidity steps from current official documentation.
- Cross-chain source -> destination? Requires accepted bridge, supply model, trust/proof rules and recovery design. Never silently relabel this as same-chain graduation.
- New launch economics (curve, buyback, burn, creator/community fees)? Isolate in a versioned launch/economics module. No modification of venue adapter to force unsupported fee mechanics.

## Design invariants (PR review blockers)

- Factory has NO imports, constructor arguments, internal new/deployment bytecode, or branching for a specific venue. Minimal common types/interfaces are allowed.
- Registry has no custody and no arbitrary execute/delegatecall. Only governance can admit independently qualified versions. `(venueId, version)` cannot be overwritten.
- Launch commits pin chain/factory/launch identity, quote/economic policy, venue ID, settlement kind, adapter/version/address/codehash and venue config hash before public bonding.
- A revoked adapter prevents NEW launches; it must not silently change an existing launch's pinned destination. Separate emergency behavior needs governance and explicit recovery criteria.
- Coordinator is sole authoritative graduation ledger. `secure` must reconcile exact balances; `complete` must verify postconditions and be replay-safe; external failure does not erase secured assets.
- Adapters cannot siphon unrelated launches' funds: exact allowances/transfers, allowlist of external contracts, callback/reentrancy guards and residual asset checks.
- Venue-specific receipts reflect what actually exists: Uniswap LP position, Kuru market/vault shares, or native HyperCore asset/spot balances. Do NOT require fictitious LP shares.
- The indexer is a *projection*; events, backend signatures or status labels alone do not prove onchain/native settlement.
- No `delegatecall` to venue plugins, no user-selected arbitrary target/calldata and no fake compliance across target chains.
- No changes to canonical V1/V2 or deployment manifests as a side effect of research. Research V3 lives under `v3-research-experiment` until authorized.

## Work sequence for every new venue

1. Pin `main` SHA and `contracts/foundry.toml` compiler settings. Run `forge build --sizes --skip test --skip script`; attach measured deployed runtime + initcode sizes. Historical 23,423-byte Factory is NOT a new measurement.
2. Identify `chainId`, verified target venue addresses, proxy/implementation state, external call permissions, quote asset semantics, precision, LP/ownership model, fees, slippage and failure surface. Record provenance.
3. Write capability record: `venueId`, version, `ATOMIC_EVM | NATIVE_ASYNC | CROSS_CHAIN_ASYNC`, supported chain/quotes, policy digest, receiver behavior and method/receipt ABI.
4. Implement a thin adapter using external calls, not copied venue matching-engine implementation or imported creation code in Factory.
5. Implement tests: happy path, wrong chain, disabled version, wrong quote, stale codehash, missing liquidity, malicious recipient, callback/reentrancy, partial failure, replay, exact reserve/fee conservation and frozen launch configuration.
6. Prove an N+1th venue can be registered AFTER factory deployment with identical factory codehash and no changes to existing launch commitments.
7. Run local Foundry tests, fork integration where available, full relevant V2 regression/invariant tests, format/build/code size, and target-chain testnet smoke. Preserve exact commands/receipts; unavailable evidence is BLOCKED.
8. Hand off versioned deployment manifest, ABI/events, TypeScript SDK bindings, indexer decoding, frontend capability flags, governance operations and operator runbook.

## Command quickstart

```sh
cd contracts
forge fmt --check
forge test --match-path test/v3-research-experiment/VenueRegistryV3.t.sol
forge build --sizes --skip test --skip script
FOUNDRY_CODE_SIZE_LIMIT=1048576 forge test --match-path test/v2/invariant/GraduationCoordinatorV2Invariant.t.sol
```

Note: larger test harness size limit is not a production size waiver. Also run full scope-specific tests and live/fork tests when qualified and funded. Never claim verification if tools, submodules, credentials or RPC are unavailable.

## Agent output contract

```text
TASK / SCOPE
BASE SHA / CURRENT BRANCH
VENUE + CHAIN + SETTLEMENT CLASS
V2 AS-IS EVIDENCE (paths/lines)
ADR / POLICY STATUS
CHANGED FILES
FACTORY CODE SIZE BEFORE -> AFTER (measured, settings attached)
SECURITY & ACCOUNTING INVARIANTS
TESTS RUN WITH EXACT OUTPUTS / NOT RUN
ABI + EVENT + MANIFEST + SDK / INDEXER HANDOFF
REMAINING RISKS AND BLOCKERS
GO / NO-GO FOR TESTNET; GO / NO-GO FOR MAINNET (separate)
```

# M6 candidate decision: extract Kuru implementation to legacy

Status: **PROPOSED — owner-directed source separation; not an accepted protocol ADR, migration authorization, or deployment approval.** Independent read-only dependency/ABI review, 2026-11-05. Inspected source baseline `7ddf4dae65e11acb489be7eceb30a4846adf18cc`; concurrent M6 work is uncommitted and remains outside this snapshot. No source, script, test or deployed contract changed by this review.

## Decision requested

Remove concrete Kuru implementation from the active canonical and experimental V2 smart-contract lanes. Archive the implementation, historical deployment workflow and custody/retry verification under an explicitly nonproduction `contracts/legacy/v2-kuru/` lane. Keep the active new-launch stack V4-only. Preserve the binary identity of already deployed contracts, all committed packets, secured assets, existing claims and historical evidence. Keep numeric venue1 reserved for historical Kuru; it must never become another venue.

This is a source organization and future-admission change. No running non-upgradeable contract is patched, no existing launch is redirected, and no Kuru LP lock is unlocked. Continuous Kuru community revenue remains `BLOCKED_EXTERNAL_CAPABILITY`.

## Verified source facts

The current Factory and Coordinator already import **no concrete Kuru implementation**. Kuru execution is separate; there is no Kuru matching-engine implementation to extract from Factory bytecode. Factory uses the shared `GraduationVenue` enum and generic Coordinator configuration; Coordinator pins executor/codehash/policy/receiver into each launch packet. Its `complete()` uses the packet executor, not the latest executor mapping. Removing a source file therefore cannot change any deployed packet or enable migration.

`contracts/src/v2/interfaces/IGraduationExecutorV2.sol:6` declares `UNISWAP_V4=0`, `KURU=1`. The enum is ABI-encoded as uint8, used in mappings, events, packet hashes, economics commitments and quote-asset venue masks. `RetroPickQuoteAssetRegistryV2.sol:27` permits masks1..3; bit1 permits Kuru. The new-launch stack must enforce V4-only admission independently of whether an old enum name still exists.

The concrete Kuru closure is five files in each of `src/v2` and `src/v2-research-experiment`:

| Original relative path | Canonical baseline SHA256 | Experiment comparison |
|---|---|---|
| `KuruEnvironmentV2.sol` | `aa915a37dbdf2b439983d4b8791bbbc61d64730aee879e44a322b4148ab7c99f` | Identical |
| `KuruGraduationExecutorV2.sol` | `8d3212f6d12580cab1e928afdcf28519145b50e97b05ffd311c4a2dee200217c` | Identical |
| `KuruLiquidityLockV2.sol` | `fdb8ada56145a8418d277131bd834444273bc5ce81736d61b941c760431b19c1` | Identical |
| `interfaces/IKuruV2.sol` | `8cd18dd7032a8b9a7ca2b54ae88eef17c055e6b9a92996cae87b7c9996dedeb2` | Different bytes; preserve each origin independently |
| `libraries/KuruParameterPolicyV2.sol` | `f0979f764111c2fb537caf3f4d6a34cad6419b66da4f5279d6bfbe373c857750` | Identical |

The minimal **relative-import closure** of these five also needs frozen `interfaces/IGraduationExecutorV2.sol`, `interfaces/IRetroPickLaunchpadV2.sol`, `libraries/ExactAssetV2.sol`, `libraries/ExecutorDonationsV2.sol` plus the actual pinned external dependencies. Active imports must not point back into these archived Kuru files. Frozen common interfaces copied into legacy are historical types, not active authority.

## Critical code-identity constraint

A move is not an identity-preserving recompilation. Solidity includes source-unit keys/content/dependency/settings metadata in artifacts. Changing a source path or import may change creation/runtime codehash even with identical logic. `KuruGraduationExecutorV2.sol:316` incorporates `type(KuruLiquidityLockV2).creationCode` into CREATE2 receiver prediction; a changed lock artifact changes the predicted permanent receiver. `previewReceiver`, pinned packet receiver and execution must continue to agree.

For each archive record original repository commit, Git blob, SHA256, original source-unit key, compiler version/settings, exact dependency revisions, original initcode/runtime hashes where available, and any deployed identity. Retain original build input/artifacts unchanged. For an exact historical rebuild, supply the frozen files under their **original virtual source-unit keys** to the pinned compiler, rather than asserting the new filesystem path produces the old artifact. A relocated logic regression is useful but must be labeled a relocated rebuild; it is not proof of original deployed code identity. Never refresh a historical manifest from a new compilation.

The existing `contracts/test/v2/community-economy/reference/v2/` is a31-file snapshot of `7bad742b67e2fa58ebf680eadbfa6194d5bbf0c3`, with `reference/PROVENANCE.json`. Preserve it unchanged. It can support old semantics, but must not be relabeled a full exact snapshot of later `7ddf4dae` community additions. Do not delete historical snapshots to suppress duplicate artifact names; use source-scoped runs and fully qualified artifacts.

## Mechanical separation plan

1. Inventory exact tracked/untracked work and pin current main. Materialize the archive from explicit Git blobs, with separate canonical and experimental provenance. Do not overwrite either existing snapshot or current test edits. Archive the five Kuru files and their necessary frozen local import closure; archive the original deploy/smoke scripts and historical tests with their original bytes and source keys recorded before changing active references.
2. Remove the five concrete files from active `src/v2` and `src/v2-research-experiment`. Do not leave forwarding import shims there: those keep Kuru in the active dependency graph. Avoid changing the shared packet/receipt structs or numeric enum. The retained enum name is a historical ABI tombstone, not active venue support. Renaming it is optional tooling churn and provides no safety benefit; retaining `KURU=1` with an explicit legacy-only comment is preferred.
3. Make the **new active admission path** V4-only. The narrowest unchanged-Factory route is a separately qualified V4-only quote registry deployed for the new stack, with mask1 only and `admitted(...,KURU)` always reverting. Prove Factory cannot bypass that registry through any launch overload. If the owner explicitly selects an in-place source revision of the registry or Factory, keep the ABI selectors and enum ordinals; document changed future-admission behavior and measure Factory runtime/codehash. Existing deployed registries are not silently upgraded.
4. Do not reinterpret generic Coordinator code as Kuru implementation. Retaining its generic mappings, packet fields and terminal custody verification preserves ABI and reduces regressions. An optional guard rejecting configuration/registerLaunch for venue1 on a **new Coordinator deployment** is defense in depth, not required for existing commitments. Do not add that guard to old-instance servicing logic or historical tests. `complete()` must never consult live registry admission or reject an already pinned Kuru packet merely because new launches are V4-only.
5. Active deployment/qualification imports must no longer compile concrete Kuru implementations. Add a distinct V4-only deployment profile; do not run it. Preserve the original Kuru-bearing script under legacy with its original source data/inputs. Do not modify deployed address JSON, release manifests or historical script evidence. Any move of a tracked production script requires the repository ownership/protection checker to explicitly recognize the reviewed migration, not a broad exemption.
6. Repoint Kuru-only tests to the archived/frozen stack and a dedicated legacy runner. Keep test assertions, failure injection and custody/retry scenarios. Active V4 tests use current V4 sources; historical Kuru tests use matching historical Factory/Coordinator/registry. Add current-source **Kuru rejection** tests instead of weakening historical positive Kuru admission assertions.
7. Update only new build/catalog tooling needed to separate active and legacy outputs. Namespace generated artifacts by source revision/lane and fully qualified source path. Keep deployed ABI packages untouched; SDK/indexer changes below are a handoff until separately authorized. Verify protected historical files and V1/V3 remain unchanged.

## Direct consumer and test impact

| Consumer | Source dependency | Required treatment |
|---|---|---|
| `contracts/script/DeployV2MonadTestnet.s.sol:16,17,79,84,117` | Creates Environment/Executor and registers Kuru; quote helper uses mask3 | Preserve exact historical workflow in legacy; new V4-only profile has no Kuru construction/configuration and mask1. Script currently broadcasts when invoked: do not execute it. |
| `contracts/script/SmokeV2MonadTestnet.s.sol:33,36` | Chooses Kuru economics and launches venue1 | Archive as legacy operational reference; no new-stack launch qualification through it. |
| `contracts/script/TradeV2KuruTestnet.s.sol:5` | Imports IKuru and uses existing market/margin/vault | Preserve for old deployed market servicing in legacy; source separation is not authorization to trade. |
| `contracts/test/v2/integration/KuruV2EndToEndFork.t.sol` | Concrete Kuru imports, FQ artifact strings, current Factory fixture | Archive/use frozen matching old fixture. Keep genuine-fork identity, failed destination/retry, duplicate, environment drift and protected LP tests. Do not silently skip them. |
| `contracts/test/v2/unit/KuruPolicyAndLockV2.t.sol` | Lock and ParameterPolicy imports | Move/repoint to legacy-qualified source identity with assertions unchanged. |
| `contracts/test/v2/integration/KuruForkResearch.t.sol`, `KuruAtomicResearch.t.sol` | Locally declared research interfaces/coordinator | Preserve research as legacy evidence; no production-capability inference. |
| `contracts/test/v2/unit/QuoteAssetRegistryV2.t.sol` | Positive mask3/Kuru admission and later revocation | Preserve original as historical registry test; add new mask1-only rejection/version tests for active registry. Do not rewrite old assertions to manufacture compatibility. |
| `GraduationCoordinatorV2Authority.t.sol` | Unauthorized calls use Kuru enum as an argument | No concrete dependency. Keep unauthorized-before-body semantics and enum1; add separate authorized venue-rejection test if the new Coordinator deliberately restricts admission. |
| V4/Curve community fixture comments | Mentions of unsupported Kuru | Comments do not import implementation. Correct current scope without deleting historical claims/evidence. |
| `scripts/launchpad/export_abi_catalog.py:32,34,42,76..78` | Owned Kuru catalog entries | Separate active candidate catalog from frozen legacy/deployed ABI catalog; do not regenerate production ABI files from renamed artifacts. |
| `scripts/launchpad/export_deployed_abis.py:21,22,90,108` | Deployed Kuru roles/locks/interfaces | Preserve deployed ABI servicing and pin original artifact identities; active new-candidate export must not overwrite it. |

## SDK/indexer/frontend handoff (no edits in this review)

`packages/launchpad-sdk/src/registry.ts:12` maps V4=0,Kuru=1; keep this historical decode identity. Its discovery at line101 attempts both venues: introduce deployment-profile capability selection for new creation rather than globally removing Kuru and breaking older deployments. `prepare.ts` has Kuru margin/order/LP write functions and validates terminal Coordinator receipts; keep those behind old deployment identity/capability gates. `decode.ts`, `kuru.ts`, `orders.ts`, `liquidity.ts` and the Kuru ABI modules remain necessary for historical markets, replay and existing user withdrawals. Removing them globally would exceed the smart-contract extraction task and could strand a UI path for user-owned positions.

`packages/launchpad-sdk/src/read-model.ts` has Kuru-specific trade/LP/price variants; new V4 revenue requires additional explicit variants, not relabeling historic Kuru data. `apps/indexer/src/{sync,project}.ts` discover and project Kuru state. Preserve historical journal/reorg replay and old venue1 decoding. `apps/retro-ui` currently exposes Kuru create/trading/orderbook/liquidity components; new deployments should advertise V4-only creation after onchain admission is qualified, while existing Kuru markets remain discoverable/serviced. These are separate ownership-scoped handoffs, not authorization for unrelated UI changes.

## Historical commitments and operational invariants

- Old deployed Factory/Curve/Coordinator/Executor/Lock bytecode is immutable and untouched. Source removal is not a chain transaction.
- Existing packet executor/codehash/policy/receiver and quote-policy snapshots stay authoritative through `NONE -> GRADUATING -> GRADUATED`. Failed destination execution retains secured obligations; independent retry remains available on the original stack.
- Do not repurpose executor mapping1 or enum1 for V4 or a third venue. New config must not rewrite old packets. Never migrate reserves to a new Coordinator by file move or offchain annotation.
- New V4-only admission can change the new registry policyHash/economics quote; SDK must obtain a fresh commitment. Do not reuse an old Kuru expectedEconomics hash.
- Kuru lock CREATE2 salt, creationCode, deployer and predicted receiver remain bound to the original packet. No permissionless replacement lock is a migration path for old funds.
- Existing fee claims, buyback vests, user margin assets and locked LP share rights do not become treasury revenue. Source extraction grants no right to harvest/redirect them.

## Required executable acceptance checks

1. Machine import graph: no active `src/v2` or `src/v2-research-experiment` dependency resolves into concrete Kuru files or legacy; allow the common historical enum value. Active V4 profile has no Kuru deployment action. Capture the exact search/import-graph result, not just filenames.
2. Frozen blob/archive manifest and old deployed-artifact verification: byte hashes, source keys, dependency revisions, compiler settings. Explicitly distinguish relocated artifact hashes from original ones; test CREATE2 receiver consistency under each qualified build.
3. Active new launch: every overload rejects venue1 before token/Curve/Router/Vault durable creation or fee accrual; mask2/3 cannot restore admission. Disclose owner capability if a generic deployed registry remains mutable. V4 launches and native/six-decimal paths still pass with identical accepted curve math, fee rates and supply.
4. Legacy replay: pinned Kuru packet can secure, fail destination, preserve quote/token liabilities, retry exact packet, verify permanent LP lock and complete once. Live registry revocation/config replacement does not alter its packet. Run with the historical stack; record mock/local/fork truthfully.
5. ABI differential: numeric enums, function selectors, tuple field order/types, event topics and original return fields retained where claimed. Common receipt market/vault fields remain for historical decode even if new V4 receipts leave them zero. No storage-layout/deployed-identity equivalence implied by ABI equality.
6. Fully qualified artifact runs repair ambiguity. All current V4, treasury, native/USDC unit/fuzz/invariants pass; original Kuru tests remain in an explicit legacy gate with pass/fail/skip evidence. No test removed or silently skipped as a side effect.
7. Measure active Factory/Coordinator/Registry initcode and runtime under exact profile. Because Factory never imported concrete Kuru, a five-file move alone should not be advertised as meaningful Factory logic-size savings. Any changed metadata/runtime hash must be reported exactly. Respect EIP170/3860; harness size overrides are not release waivers.
8. Protection checker explicitly validates the bounded source moves and unchanged historical evidence, addresses, V1/V3 and unrelated app files. No checker is relaxed merely to turn migration green.

## Alternatives rejected

Deleting all mentions of Kuru, deleting enum1 or shrinking its range would change ABI validation and destroy historical decoding. Keeping active forwarding imports leaves the implementation active. Deleting retry/fork tests erases required custody evidence. Recompiling moved source and labeling its new hash an old deployed hash is false. Redirecting already pinned Kuru packets to V4 would alter protected commitments and requires a separate, expressly authorized asset migration design; it is outside this decision.

## Review/promotion status

This packet is actionable source-separation guidance, not an accepted ADR. Parent should record owner acceptance of the concrete scope before changing normative venue policy, archive exact source identities before deleting active files, and obtain a separate read-only review of the actual patch. No Kuru continuous fee right has been proven. No chain call, fork test or source rebuild was executed by this reviewer for this packet.


## Implementation increment — owner steering, 2026-11-05

Owner explicitly requested current `contracts/src/v2` development with all active concrete Kuru code removed and a separate deployed `legacy-v2` archive retained during judging. The active enum member is now `LEGACY_RESERVED` at unchanged wire index1; neither active lane nor active Solidity/Python scripts contains a Kuru dependency. This is an intentional source-level symbol rename, so source consumers must update their enum references; ABI uint8 values and historical packets retain their interpretation.

The exact deployed source archive is `contracts/legacy-v2`, pinned to f0363249, distinct from the later7dd regression closure at `contracts/src/legacy/v2/kuru`. Original release driver bytes are retained as an inactive `.orig` record; no replacement live broadcast workflow is introduced. A separate V4-only local/fork construction candidate does not use broadcast flags or historical manifest paths.

The Factory/Curve financial source files are unchanged. Compiler metadata can change through renamed dependencies, so full runtime codehash equality is not asserted. The artifact comparison separately checks ABI and executable runtime after outer metadata removal. Do not rebuild historical CREATE2 commitments from relocated sources.

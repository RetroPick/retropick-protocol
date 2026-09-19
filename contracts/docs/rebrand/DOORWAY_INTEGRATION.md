# RetroPick Doorway V1 — Rebrand, Test Suite & Security Notes

**Status:** `experimental reference implementation`

This document records the integration of the cross-chain liquidity migration
Doorway into the RetroPick contracts package: the rebrand from the upstream
`PonsDoorway` reference, the modular interface scaffolding, and the Foundry test
suite added under `test/`.

## What was added

| File | Purpose |
|------|---------|
| `src/RetroPickDoorwayV1.sol` | Rebranded migration orchestrator (Solana ↔ RetroPick Doorway ↔ Monad Chain). |
| `src/interfaces/IRetroPickDoorwayV1.sol` | `IRetroPickDoorwayV1` external surface + shared enums/structs, plus modular scaffolding interfaces `IRetroPickDoorwayRegistryV1`, `IRetroPickDoorwayVaultV1`, `IRetroPickDoorwayStakingV1`. |
| `test/mocks/MockERC20.sol` | Mintable ERC-20 used as a registrable Monad-side token. |
| `test/unit/RetroPickDoorwayBase.t.sol` | Shared harness (actors + lifecycle helpers). |
| `test/unit/RetroPickDoorwayRequest.t.sol` | Monad→Solana request path + full admin/access-control matrix (16 tests). |
| `test/unit/RetroPickDoorwayLifecycle.t.sol` | Solana→Monad request, attestation, execution, cancellation (19 tests). |
| `test/fuzz/RetroPickDoorwayFuzz.t.sol` | Fee-math, accounting, and id-uniqueness properties (5 tests). |
| `test/invariant/RetroPickDoorwayInvariant.t.sol` | Stateful handler + 4 security invariants. |
| `test/integration/RetroPickDoorwayE2E.t.sol` | End-to-end bidirectional lifecycle + pause/resume + cancellation (4 tests). |

`forge-std` (v1.16.2) was installed to `lib/forge-std` and wired via
`remappings.txt`. An `[invariant]` profile (`runs=64, depth=64`) was added to
`foundry.toml` to keep the stateful campaign fast (~3s vs ~11min at defaults).

## Rebrand scope

The rebrand preserves behavior exactly (identifiers, arithmetic, state
machine); only naming changed:

- `PonsDoorway` → `RetroPickDoorwayV1`
- All revert strings `"PonsDoorway: …"` → `"RetroPickDoorwayV1: …"`
- NatSpec / architecture references → RetroPick, `Solana ↔ RetroPick Doorway ↔ Monad Chain`

### Chain rename: Robinhood → Monad

RetroPick deploys on **Monad**, so the Robinhood-side of the doorway was renamed
throughout the contract, interfaces, tests, and this doc. This changes the
**public ABI** (deliberately, since the Doorway had no prior deployment):

- Enum `MigrationDirection`: `ROBINHOOD_TO_SOLANA` → `MONAD_TO_SOLANA`,
  `SOLANA_TO_ROBINHOOD` → `SOLANA_TO_MONAD`.
- `Migration.robinhoodToken` struct field → `Migration.monadToken`.
- `setRobinhoodToken` → `setMonadToken`,
  `isRobinhoodTokenSupported` → `isMonadTokenSupported`,
  storage `supportedRobinhoodTokens` → `supportedMonadTokens`.
- `MigrationRequested` event `robinhoodToken` param → `monadToken`.
- Test names / helpers updated accordingly (e.g. `test_e2e_monadToSolana_fullLifecycle`,
  `test_attest_knownLimitation_zeroHashLatchesForMonadToSolana`).

Enums (`MigrationDirection`, `MigrationStatus`) and structs (`Migration`,
`Attestation`) were lifted into the interface file so modules and consumers
share one ABI. `RetroPickDoorwayV1` implements `IRetroPickDoorwayV1`,
`IRetroPickDoorwayRegistryV1`, and `IRetroPickDoorwayVaultV1`.

## Verification

- `forge build` — 0 errors (pre-existing lint warnings in `RetroPickMemeHookV1.sol` unchanged).
- `forge test --match-path 'test/**/RetroPickDoorway*'` — **45 passed, 0 failed**.
- `forge test --match-path 'test/fuzz/*' --fuzz-runs 10000` — all 5 fuzz properties hold.
- Invariant campaign — 4/4 invariants hold (runs: 64, calls: 4096, reverts: 0).
- `forge fmt --check` — clean on all Doorway files.

## Known reference-implementation limitations (documented, not fixed)

The chosen scope preserves the reference behavior; the following are pinned by
tests and/or NatSpec so any future change is deliberate and visible.

1. **Zero-hash attestation latch (correctness).** `attestMigration` keys replay
   protection on `sourceTxHash`. Monad→Solana migrations store
   `sourceTxHash == bytes32(0)`, so `processedAttestations[0]` latches after the
   first such attestation and **every subsequent Monad→Solana migration can never
   be attested**. Pinned by
   `test_attest_knownLimitation_zeroHashLatchesForMonadToSolana`. A future
   fix would key replay protection on `migrationId`.
2. **Pure accounting, no token custody.** `migrateToSolana` / `requestFromSolana`
   update `tokenLiquidity` / `pendingFees` but never pull ERC-20 tokens via
   `transferFrom`. Tests assert accounting only.
3. **`ATTESTATION_DELAY` is unused.** Declared but not enforced anywhere.
4. **`executeMigration` is `doorwayOpen`-gated.** Pausing the Doorway blocks
   completion of already-attested, in-flight migrations (covered by
   `test_e2e_pauseAndResume`).
5. **`executeMigration` does not enforce `minAmountOut`.**

## `forge lint` findings on `RetroPickDoorwayV1.sol`

All informational and inherited from the reference design (scope preserves
behavior):

- `missing-zero-check` (×5): constructor / setter address params have no
  zero-address guard (except `transferOwnership`, which does).
- `missing-events-access-control` on `owner`: `transferOwnership` emits no event.
  (`setRelayer` / `setGuardian` / `setFee` **do** emit events; the lint flags the
  emit-before-write ordering and is a false positive for those.)
- `block-timestamp`: the cancellation delay compares against `block.timestamp`
  (acceptable for a 30-minute safety window).

These are candidate hardening items for a production Doorway alongside items 1–5.

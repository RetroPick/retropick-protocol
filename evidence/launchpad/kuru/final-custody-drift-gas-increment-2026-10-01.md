# Final research custody, drift, retry and gas increment — 2026-10-01

**Classification:** `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN` only for the enumerated pinned-fork research-fixture checks below. This is **not** production executor qualification, Factory integration, a gas distribution, or an ADR acceptance.

**Source baseline:** `6859aa770159d6d63ed3805275e9db30a43020dd` with uncommitted research-fixture edits in `KuruAtomicResearch.t.sol` and `KuruForkResearch.t.sol` at execution time. **Fork:** Monad Testnet block `66752717`, chain ID `10143`. The pinned Router is `0x7EFbE105Ca7415dE98F96682173458ac1c054630`; MarginAccount is `0xd029C2D98ff85D8F64799017fE00a59B1159CE02`; OrderBook implementation is `0x72caE0a99C19B574e8a6De558F43fc1D019c9374`; vault implementation is `0x4d54e0d60CaB0cec0100cdA8e00897bC933C5Bb6`.

From the repository root, the exact reproductions were:

```bash
set -a; source contracts/.env.local; set +a
cd contracts
forge test --summary --match-path 'test/v2/integration/KuruAtomicResearch.t.sol' -vvv
forge test --summary --match-path 'test/v2/integration/KuruForkResearch.t.sol' -vvv
```

Results were `16 passed / 0 failed` and `3 passed / 0 failed`. No transaction was broadcast and no keystore was read.

## B7 — protected custody

The coordinator now constructs `KuruResearchBoundLock` only after deriving the deterministic expected market and vault. Both the native-MON and canonical Circle paths send real first-deposit LP directly to that lock and transfer the exact excess launch tokens to the same bound address.

For the test contract acting as creator/operator and two independent arbitrary actors, the fixtures require:

- immutable lock/base/market/vault identities;
- exact locked LP-share and excess-base balances;
- direct vault `withdraw` rejects;
- launch-token `transferFrom` out of the lock rejects;
- raw LP `transfer`, `approve`, and `burn` calls do not execute;
- generic `execute(address,bytes)` and `delegate(address,bytes)` calls do not execute;
- LP allowances remain zero; and
- protected LP and excess-base balances remain unchanged.

This closes the declared P0 no-exit research architecture boundary. It does not implement or accept the production lock, does not authorize an unrelated-token rescue path, and does not audit every possible inherited ERC-20 hook. ADR-022 remains `PROPOSED`.

## B8 — atomic failure and retry

The expanded suite preserves the prior twelve boundaries and now includes the final bound-lock custody paths. Covered failures include Router deployment revert, registry mismatch, unexpected pre-existing market, implementation drift, wrong MarginAccount getter, base approval failure, Circle approval/quote-transfer failure, excess-lock transfer failure, malformed post-deposit results, zero liquidity or order size, price-bound failure, and forced failure after final coordinator writes. Every checked failure leaves the secured launch in `GRADUATING`, destination unset, secured assets accounted, and the same launch retryable; successful completion rejects replay before useful asset movement.

This is still a research coordinator. Actual Factory/Coordinator state extraction, production state-machine writes and ADR-023 acceptance remain outside this row.

## B9 — observable drift

The coordinator pins Router and MarginAccount **runtime** code hashes in addition to Router implementation getters and OrderBook/vault implementation hashes. `vm.etch` fault injection changes observable runtime code without pretending to SLOAD another proxy's private EIP-1967 slot. Router and Margin runtime drift both stop before market creation; restoring the pinned target allows the same secured launch to retry.

The fixture also checks deployed-market `marketState() == ACTIVE`. External implementation identity and private ERC-1967-slot qualification remain an offchain manifest responsibility. Any Kuru upgrade requires a new manifest and requalification; the onchain executor must fail closed to new graduations on observable drift.

## B10 — deterministic gas matrix

The matrix measures one failed attempt, one successful retry, and one replay rejection for small/medium/large profiles in both quote classes. Recorded fork block gas limit is `150,000,000`.

| Quote | Profile | Failed | Successful retry | Replay rejection |
| --- | --- | ---: | ---: | ---: |
| MON | small | 1,182,498 | 1,618,870 | 51,196 |
| MON | medium | 1,182,498 | 1,618,870 | 51,196 |
| MON | large | 1,182,498 | 1,618,918 | 51,196 |
| Circle | small | 1,355,434 | 1,896,521 | 51,196 |
| Circle | medium | 1,355,434 | 1,879,551 | 51,196 |
| Circle | large | 1,355,395 | 1,879,546 | 51,156 |

The normal native completion in the non-matrix retry case measured `1,628,657` gas. Standalone real Router/vault measurements were `1,122,451 / 503,242` gas for MON deploy/deposit and `1,285,671 / 635,246` gas for canonical Circle. These are single deterministic Foundry deltas, not p50/p95 values, receipts, or an operational SLO. The later integrated Factory/Coordinator/executor architecture must be remeasured after implementation.

## Gate effect

Accordingly, B7/B8/B9/B10 are technical `PASS` only for this pinned research architecture. B2/B3/B4 remain `DECISION_REQUIRED`; B11/B12 remain `NOT_RUN`; `KURU_TECHNICAL_BENCHMARK = PASS`; and `KURU_TARGET_FROZEN = DECISION_REQUIRED`. No top-level Core, target-freeze or DEV-4 authorization is implied.

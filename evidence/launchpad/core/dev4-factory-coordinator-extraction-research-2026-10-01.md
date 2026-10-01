# DEV-4 Factory-to-Coordinator extraction research — 2026-10-01

**Status:** passing research-fixture evidence; not production implementation authority.

**Branch / HEAD:** `codex/kuru-freeze-smart-contract-spec` / `22068a4eebd7663cbdbec1f30d696ace70dc5959`

**Toolchain:** Foundry `1.8.3`, solc `0.8.26`, optimizer runs `200`, `via_ir = true`.

## Fixture

`contracts/test/v2/integration/DEV4GraduationExtractionResearch.t.sol` defines test-local thin Factory, Coordinator, venue-executor, and permanent-custody research fixtures. None is moved into `contracts/src/v2`, and none is production authority.

The fixture reuses the production `RetroPickBondingCurveV2`, `RetroPickLauncherTokenV2`, `RetroPickBuybackVaultV2`, and `RetroPickFeeEscrowV2`.

## Command and result

From `contracts/`:

```bash
forge test --match-path test/v2/integration/DEV4GraduationExtractionResearch.t.sol -vv
```

Result:

```text
4 passed; 0 failed; 0 skipped
```

Passing cases:

1. native-MON automatic handoff, injected phase-2 failure, permissionless retry, replay rejection, and custody proof;
2. ERC20-quote automatic handoff, failure, retry, replay, and custody proof;
3. thin Factory runtime-size boundary;
4. wrong-executor rejection before secured packet consumption.

## Qualified research properties

In this bounded fixture domain:

- unchanged production Curve graduation callback behavior drives the handoff;
- Factory delegates one-hop authority to the Coordinator and retains no secured balances;
- Coordinator receives and records the exact terminal quote/token packet;
- `GRADUATING` is durable across phase-2 failure;
- failed phase 2 leaves secured assets and ledger identity unchanged;
- retry is permissionless and succeeds with the immutable executor packet;
- completed launches reject replay;
- native MON and exact ERC20 quote paths pass;
- LP shares are recorded only in protected custody;
- excluded excess launch tokens remain protected;
- a wrong executor cannot consume the packet;
- approvals are exact packet-sized and cleared after completion.

## Size boundary

The research-only thin Factory runtime measures **21,810 bytes**, leaving 2,766 bytes below EIP-170 and meeting the approximate 23.5 KB extraction research target.

This does **not** prove the production Factory refactor size. The current production Factory remains 24,565 bytes, only 11 bytes below EIP-170.

## Explicit limitations

This evidence does not:

- implement production Factory, Coordinator, Kuru executor, V4 executor, or custody contracts;
- prove the complete stateful Factory/escrow/custody conservation matrix;
- implement the accepted venue-generic completion-ceiling guard;
- qualify integrated production Core-to-Kuru execution;
- accept ADR-009, ADR-011, ADR-020, ADR-021, ADR-022, or ADR-023;
- promote `CORE_BASELINE_P0_QUALIFIED`, `KURU_TARGET_DEV_FROZEN`, or `READY_FOR_DEV4_KURU_EXECUTOR`;
- authorize staging or mainnet deployment.

It supplies bounded architectural evidence that the DEV-4 extraction shape is executable and small enough for hackathon-stage development under hard policy guards.

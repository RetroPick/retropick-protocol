# Core V2 Factory launch qualification increment — 2026-09-29

**Status:** `CORE_BASELINE_QUALIFIED = BLOCKED`. This increment qualifies a narrow present-code path, not the Core V2 production architecture or Kuru destination. No production Solidity changed.

## Executable scope

`contracts/test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol` constructs the real Factory, Deployer, Token, Curve, Locker, BuybackVault and GraduationExecutor. V4-only PositionManager/Hook dependency getters are explicitly mocked. It does **not** simulate V4 pool creation, V4 position minting, Kuru, or a live FeeEscrow. The test fee ledger is test-only.

Five tests verify:

1. Factory-mediated native-quote launch records the creator and phase; the Curve receives the fixed token supply and the expected half-supply reserve, with factory/token/curve identities wired.
2. A changed launch config invalidates the pinned economics digest; a disabled config rejects launch.
3. Different `salt` inputs from the same prelaunch state yield identical token/curve addresses. Current `CREATE` deployment ignores salt; this is a documented negative control, **not** CREATE2 qualification.
4. An unapproved six-decimal ERC20 quote rejects; an owner-approved quote with declared economics launches. Admission does not establish fee-on-transfer, rebasing, callback or external-balance-loss safety.
5. Valid factory anti-snipe settings (default versus zero start bps and one-second window) do not change the current buy output or creator-tax balance. This is a negative control: the current Curve's anti-snipe exemption hook is a no-op.

## Reproduction

- `cd contracts && forge test --match-path test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol -vv`: 5 pass, 0 fail.
- `cd contracts && forge fmt --check test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol`: pass.
- `cd contracts && forge test --summary`: 67 pass, 0 fail; 45 Doorway and 22 Core V2 qualification tests. Core stateful invariants remain bounded to the native-quote Curve handler with default 64 runs ×64 depth in this suite; independent high-run seeds are recorded in the earlier baseline.
- Test-file SHA-256: `31d4f9675d9b13e9a3fb528b1733c566e5c22a4804c3a4f9fdd399faa59ec919`.

## Classification and remaining work

**SUPPORTED_BY_EXECUTABLE_TEST_WITHIN_DECLARED_FIXTURE:** Factory-mediated creation, records, economics pin, simple quote admission and current-code salt/anti-snipe behavior. **NOT_YET_VALIDATED:** malicious or nonstandard ERC20 quote, Factory permission/timelock matrix, FeeEscrow implementation, buyback distribution, current V4 graduation failure/retry, LP-I-006..009 lifecycle, and Kuru atomic target integration. LP-I-001, LP-I-004, LP-I-010 and LP-I-011 gain partial evidence only. No LP-I property is promoted to full PASS on this increment.

Core remains the primary production-development lane. Prediction V2 and PRISM V2 remain separate research-gated lanes; this evidence confers no readiness on them.

## Subsequent checks

Later tests in the same Factory fixture preserve a [nonstandard quote deficit](quote-surcharge-counterexample-2026-09-29.md) and exercise the [crossing-buy/Swept failure path](graduation-failure-increment-2026-09-29.md). The five-test count and SHA above identify this first committed checkpoint, not the later fixture revision.

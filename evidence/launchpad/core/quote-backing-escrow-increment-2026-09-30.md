# Core V2 quote-backing and escrow qualification increment — 2026-09-30

**Classification:** partial executable qualification; `CORE_BASELINE_QUALIFIED` remains **BLOCKED**. Branch `codex/kuru-freeze-smart-contract-spec`, base `d6dcde593f8fcba4c5e22ee86d2e2fdbb28bb09c`, implementation commit `07515ea`; Forge 1.8.3, solc 0.8.26, optimizer 200, viaIR. This is local Foundry evidence, not live Circle/Kuru qualification.

## Closed counterexample paths

- A sender-surcharge ERC20 previously could reduce the Curve's physical balance more than its tracked quote on an outgoing transfer. Both sender and recipient balance deltas are now checked on ERC20 ingress/egress, with a permanent negative test. The Curve checks `physical >= trackedQuote` before relevant state changes and after transfers; donations may make physical greater without changing pricing.
- An externally reducible/rebasing quote can still lose backing outside RetroPick's control. The Curve now fails closed on subsequent accounting reads and writes; the loss is **not** repaired or declared supported. P0 admission is native MON or the exact chain-10143 Circle test-USDC address, never an arbitrary owner-approved ERC20. The immutable policy also checks current code and six-decimal metadata. Address admission alone does not prove exact transfer behavior or remove Circle issuer controls.
- The missing production `RetroPickFeeEscrowV2` now has per-asset credit/liability ledgers, exact ERC20 transfer checks, pull claims, reentrancy guard and donation separation. Sender-surcharge credit reverts before creating liability; externally reduced balances stop claims without mutating ledgers.

## Commands and observations

| Command | Result |
| --- | --- |
| `forge build --sizes --skip test --skip script` | PASS; Factory runtime **24,502 bytes**, only **74 bytes** below EIP-170; Curve 10,711, FeeEscrow 3,013, policy 682. The Factory margin is an explicit architecture constraint, not comfortable expansion space. |
| `forge test --match-path 'test/v2/unit/**' --fuzz-runs 32 -vv` | 20/20 PASS, including five production-escrow tests. |
| `forge test --match-path test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol -vv` | 15/15 PASS; includes exact-transfer, false-return, callback, sender-surcharge and external-loss cases. V4 dependency is mocked here. |
| `FOUNDRY_INVARIANT_RUNS=4 forge test --match-path test/v2/invariant/RetroPickCurrentCurveV2Invariant.t.sol --invariant-depth 8 -vv` | 2/2 PASS; 4 runs, 32 calls, 0 reported reverts, production escrow in the fixture. This is a bounded native-Curve profile, **not** the complete required stateful matrix. |
| `forge test --match-path 'test/v2/**' --fuzz-runs 32 -vv` | Interrupted after >5 minutes in the default 64×64 invariant profile; the suites printed before interruption passed, but the command **did not complete** and must not be cited as a full-suite pass. |

The Circle-identity unit fixture deliberately replaces code at the accepted address to test missing code and incorrect/correct decimal metadata. It is **not** a real Circle transfer or Kuru-deposit test. The local Foundry network can expose live testnet code at this address; the test clears it explicitly for the missing-code negative.

## Remaining Core blockers

Successful V4 graduation/retry and remaining fee/buyback/graduation branches are not completely qualified; ERC20 and native stateful invariant matrices remain incomplete. The Factory's V4 `_transferExact` verifies recipient gain but not sender loss, leaving a multi-launch custody risk if a quote's transfer behavior changes after admission; this is not covered by the Curve/Escrow repair. Actual Circle Core-path behavior and the full Kuru profile also remain open (a later scoped Kuru fork deposit is separate evidence). The Factory's 74-byte runtime margin forbids embedding Kuru logic and warrants further extraction before new production features. No production Kuru executor or liquidity lock was created. No live transactions were sent. `KURU_TARGET_FROZEN` and `READY_FOR_DEV4_KURU_EXECUTOR` remain BLOCKED.

# Atomic research fixture: additional failure and drift boundaries

**Classification:** partial pinned-fork B8/B9 evidence; neither row is `PASS`. **Source baseline:** `a27406b` on `codex/kuru-freeze-smart-contract-spec`. **Fork:** Monad Testnet block `66752717`, chain ID 10143. **Toolchain:** Forge 1.8.3, solc 0.8.26, optimizer 200, viaIR. No broadcast or wallet signer was used.

From `contracts/`, after loading the existing `.env.local` into the command environment:

```bash
set -a; source .env.local; set +a
forge test --match-path test/v2/integration/KuruAtomicResearch.t.sol --summary
```

Observed after the Circle quote-failure increment: **12 passed, 0 failed, 0 skipped**. The native/identity and Circle paths extend the previous seven-test research fixture:

| Injected condition | Boundary actually reached | Rejected-state evidence | Same-launch retry |
| --- | --- | --- | --- |
| Router OrderBook implementation getter returns a different address | Environment validation, before deploy | `GRADUATING`, destination unset, assets and approvals unchanged, no market/vault code | PASS after restoring getter |
| Router vault implementation getter returns a different address | Environment validation, before deploy | Same | PASS after restoring getter |
| Predicted market already has code | Pre-existing-market check, before deploy or asset movement | `GRADUATING`, destination unset, secured assets and approvals unchanged | PASS after removing injected code |
| Launch-token approval to vault reverts | After real Router deploy and verification, before deposit | The entire phase-2 deployment and approvals roll back; secured balances remain | PASS after removing fault |
| Circle quote approval to vault reverts | After real Router deploy and verification, before deposit | Real Circle balance/allowance and secured launch remain unchanged | PASS after removing fault |
| Circle `transferFrom` during real Kuru deposit reverts | After real Router deploy, both approvals and entry to real vault deposit | Market/vault creation, approvals and deposit roll back; Circle and base remain secured | PASS after removing fault |
| Transfer of excess launch tokens to the protected lock reverts | After real Router deploy and first deposit | Market/vault creation, seed, LP issuance and allowances all roll back; secured balances remain | PASS after removing fault |
| Returned market/vault base or LP share value is wrong; vault bid size is zero; opening ask exceeds candidate price cap | Research-only local value substitution **after the real deploy/deposit/readback** | Each existing postcondition rejects and rolls the entire phase-2 transaction back | PASS with real values on the same launch |
| Final destination/phase write is followed by a forced revert | After all real Kuru calls and the research coordinator's final writes | `GRADUATING` and unset destination are restored; no market, vault or LP residue | PASS without changing secured inputs |

The test intentionally uses a stateful real Router/Vault fork for nonfaulted calls. It does **not** turn a mock into target-integration truth. A Foundry fixture pitfall was observed and excluded from the result: installing `vm.mockCall` on a deterministic market/vault address **before** `deployProxy` makes that address report nonzero code length. The coordinator then correctly rejects the unexpected pre-existing address before the intended post-deploy getter/deposit boundary. Such a test cannot count as a wrong vault or LP-share postcondition test. Those postconditions still need a fault mechanism that reaches them without altering the pre-deploy code-presence check.

The local value substitutions verify **guard behavior and transaction rollback**, not that the live Router or vault can actually return those malformed values. Post-deploy external-result mutation against the real interfaces and actual Core/Factory finalization are not yet qualified.

Still open for full B8/B9: wrong quote and vault parameters, wrong LP recipient, native settlement faults, reentrancy and lingering-approval probes, Router proxy identity/code-hash drift, and observable pause/unusable-market variants. The Circle failures use fault-injected calls on the pinned real-token/real-vault fork; they do not claim the live issuer will execute those faults. The research coordinator has no production Factory wiring or accepted immutable execution packet. ADR-023 remains `PROPOSED`, and `KURU_TARGET_DEV_FROZEN` remains blocked.

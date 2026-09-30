# DEV-4 authority reconciliation packet

**Status:** PROPOSED — decision and test packet, not implementation authority.

**Inspected branch:** `codex/kuru-freeze-smart-contract-spec` at `81fb80b648164a356ec176d191c9ed36f5ca0487`.

**Scope:** Launchpad Core graduation venue and the development-versus-live Kuru gate boundary.

## Current authority and contradiction

Accepted ADRs outrank canonical Launchpad documents, which outrank development proposals. Neither [ADR-009](../../../decisions/ADR-009-kuru-default-launchpad-graduation-venue.md) nor [ADR-020](../../../decisions/ADR-020-v4-retirement-after-kuru-proof.md) is accepted. The current [Protocol](../../../docs/launchpad/PROTOCOL.md), [Graduation](../../../docs/launchpad/GRADUATION.md), [State Machine](../../../docs/launchpad/STATE_MACHINE.md), and [target architecture](../contracts/TARGET_V2_ARCHITECTURE.md) describe Kuru as the P0 destination. The later [batch owner packet](../integrations/DEV4_BATCH_OWNER_DECISION_PACKET.md) records direction toward creator-selected `KURU` or `UNISWAP_V4`, immutable before public bonding, with V4 retained. The documents cannot both be the final venue rule.

The current Factory has no venue field: it records `NotGraduated`, `Swept`, or `PoolCreated` for the V4 path and holds secured assets while `Swept`. A creator-selectable target therefore requires an explicit launch commitment and a migration of graduation authority. Merely renaming `PoolCreated` to `GRADUATED` would not provide the required route, custody, or retry proof.

The historical `KURU_TARGET_FROZEN` gate includes live market and usability rows B11/B12. Requiring a real Core-to-Kuru graduation before authorizing the executor that performs it is circular. The proposed [scope migration](DEV4_GATE_SCOPE_MIGRATION.md) creates `KURU_TARGET_DEV_FROZEN` for development evidence and `KURU_LIVE_TESTNET_QUALIFIED` for later staging evidence. Both are currently blocked. The old broad key remains blocked as provenance until a separately accepted reconciliation explicitly disposes of it.

## Recommended decision, subject to protocol-owner acceptance

1. Revise ADR-009 and ADR-020 together: a creator commits exactly one closed venue value, `KURU` or `UNISWAP_V4`, at launch creation before public bonding. The selected venue is immutable. Completion and retry use that venue only; there is no automatic fallback or operator override. V4 remains supported in DEV-4, with retirement requiring a later migration decision. If the owner instead chooses a Kuru-only P0, revise this packet, the batch packet, and the canonical docs together before coding.
2. Use `CORE_BASELINE_P0_QUALIFIED = PASS` plus `KURU_TARGET_DEV_FROZEN = PASS` as prerequisites for `READY_FOR_DEV4_KURU_EXECUTOR = PASS`. The former covers the admitted native MON/Circle-USDC Core accounting and the current supported V4 success/failure path. The latter covers B1–B10, the accepted economic policies, and the accepted ADRs. It does not assert that the executor already exists.
3. Require the accepted implementation-authority `docs/smart-contract/*` pack before production DEV-4 Solidity. After implementation, require B11/B12 real Core-to-Kuru and distinct-actor market usability for `KURU_LIVE_TESTNET_QUALIFIED`; staging depends on that separate gate. Leave the broad historical Core/Kuru keys blocked until their original scope is fulfilled or an explicit migration records their disposition.

## Authority and implementation consequences

| Surface | Current | Proposed after acceptance | Proof required before implementation authority |
| --- | --- | --- | --- |
| Launch venue | Kuru-only canonical prose; V4-only current Factory | Closed `KURU`/`UNISWAP_V4` selection committed with launch economics | ADR-009/020 accepted; immutable-choice, wrong-route, retry and no-fallback tests |
| Graduation state | Factory `NotGraduated → Swept → PoolCreated`; Factory holds swept assets | One GraduationCoordinator owns venue commitment, phase, secured balances and destination; Factory remains launch/config authority | V4 positive-path regression oracle before extraction; single authoritative custody ledger and code-size proof |
| Kuru development gate | Broad freeze wording includes live B11/B12 | Scoped B1–B10 plus ADR acceptance | Complete [benchmark rows](../../../evidence/launchpad/kuru/kuru-benchmark-gates-2026-09-30.yaml), not mock-only tests |
| Live/staging gate | No separate historic key | Real deployment, first deposit, distinct-actor order/fill/cancel after DEV-4 | Receipts, events, balances, independent market/vault readback |

The proposed coordinator must hold the only authoritative graduation phase and secured-asset accounting. Factory launch metadata may point to it, but cannot maintain a second independently mutable balance ledger. Venue executors are transaction-scoped workers; neither becomes long-term asset custody. Kuru LP shares and excess launch tokens go directly to a bound no-exit lock under the separately accepted custody rule. No Kuru deployment, parameter, seed, or verification logic belongs in the Factory; its measured runtime is 24,565 bytes, 11 below EIP-170.

## Dependency order and falsifiers

1. Record successful native and canonical Circle-USDC V4 launch → threshold → sweep → position mint → locker custody → replay rejection, plus durable failed destination → same-launch retry → success. Current tests prove launch/sweep and mocked failure, not the positive path.
2. Qualify Core fees, escrow, buyback, graduation custody and stateful conservation over both admitted quote classes. Preserve pathological-token negatives.
3. Specify and test Kuru venue-specific launch admission before bonding. The current one-token Factory minimum is a concrete counterexample to the candidate Kuru min-size class; do not admit it to a Kuru-bound launch without a revised, verified tuple.
4. Complete B2–B10, including the exact quote-custody path through Kuru MarginAccount, protected LP/excess custody, all external failure boundaries, observable drift, and final-architecture gas.
5. Present one owner decision on ADR-009/020/011/021/022/023 with the completed evidence. Amend canonical docs and the machine-readable gate record only after that decision; leave every unaccepted ADR `PROPOSED`.

The recommended rule is falsified if either supported V4 quote class cannot graduate safely, venue choice can change after bonding, a Kuru-bound accepted launch is unseedable, a failed destination loses secured assets, or the final atomic path is infeasible within the accepted target-chain execution envelope. Those outcomes require revising the candidate architecture or envelope rather than promoting a gate.

**Current verdict:** `CORE_BASELINE_P0_QUALIFIED`, `KURU_TARGET_DEV_FROZEN`, `READY_FOR_DEV4_KURU_EXECUTOR`, and smart-contract specification readiness remain **BLOCKED**. This packet supplies a reviewable reconciliation proposal; it does not accept an ADR or authorize production Kuru code.

---
id: LP-DEV4-GRADUATION-EXTRACTION
type: implementation_research
status: proposed
owner: launchpad-solidity
product: launchpad
version: v2
---

# DEV-4 graduation extraction technical packet

This packet converts the current Factory/V4 graduation implementation into a DEV-4 extraction requirement. It is technical decision preparation only. It does not accept ADR-009, ADR-011, ADR-020, ADR-021, ADR-022, or ADR-023, promote a control-plane gate, or authorize production Kuru code.

## 1. Baseline and hard constraint

At HEAD `1dd9868bc4623d6e3af644c0950618a986c4dae8`, `RetroPickLaunchFactoryV2` measures 24,565 runtime bytes: 11 bytes below EIP-170. That is zero feature headroom. The target post-extraction budget is approximately 23.5 KB, leaving deployment and maintenance margin rather than merely fitting once.

The size result is reproducible with Foundry 1.8.3, solc 0.8.26, optimizer runs 200, and `via_ir = true`:

```bash
cd contracts
forge build --sizes --skip test --skip script
```

Fresh evidence is recorded in `evidence/launchpad/core/factory-code-size-2026-10-01.md`.

## 2. Current production behavior that must be extracted

The current Factory is simultaneously:

1. launch/configuration authority;
2. receiver and temporary custodian of secured quote and launch tokens;
3. authoritative writer of `sweptQuote`, `sweptTokens`, and `sweptAt`;
4. V4 pool constructor/executor;
5. verifier of the resulting position;
6. retry and replay authority; and
7. emergency rescue authority.

The exact current sequence is:

```text
NotGraduated
  -> Factory.graduate(token)
  -> curve.readyToGraduate()
  -> Factory V4 seed preflight
  -> curve.graduate(Factory)
  -> Factory measures received quote/token balances
  -> Factory writes sweptQuote/sweptTokens/sweptAt
  -> Factory.phase = Swept
  -> Factory.createGraduatedPool(token)
  -> Factory executes V4 seeding and custody
  -> Factory.phase = PoolCreated
```

That implementation provided useful two-phase behavior, but it cannot become the DEV-4 target: adding Kuru logic, venue routing, protected custody, or a coordinator ledger beside it would exceed the code limit and duplicate authority.

## 3. Target authority boundaries

```text
RetroPickLaunchFactoryV2
  | launch/config authority
  | immutable venue commitment before public bonding
  | bounded handoff to one coordinator
  v
GraduationCoordinatorV2
  | authoritative graduation phase
  | sole secured-asset ledger
  | destination identity and replay guard
  | permissionless completion/retry dispatch
  |
  +--> V4GraduationExecutorV2
  |      transaction-scoped V4 worker
  |
  +--> KuruGraduationExecutorV2
         transaction-scoped Router/market/vault worker
         protected LP/excess receiver outside Factory
```

### Factory retains

- launch existence and launch economics;
- immutable `venueId` selected before public bonding;
- quote asset identity and quote-class admission;
- coordinator binding;
- a small completion-registration interface;
- compatibility views/migration metadata where explicitly accepted.

### Factory must not retain

- secured quote or launch-token custody;
- authoritative swept balances;
- `GRADUATING` phase mutation;
- destination execution;
- Kuru ABI calls, market parameters, environment checks, seed arithmetic, or LP custody;
- a second mutable graduation ledger.

### Coordinator owns

- `ACTIVE`, `GRADUATING`, and `GRADUATED` authority for newly extracted launches;
- exact secured quote and token accounting;
- immutable venue packet identity;
- destination address/value recorded at most once;
- permissionless retry;
- replay rejection before asset movement.

A terminal `FAILED` or `RESCUED` state is not implied by this packet. The current P0 direction is durable `GRADUATING` with no protected-asset rescue shortcut. Any exception requires explicit owner acceptance and its own failure/recovery proof.

## 4. Exact Curve handoff seam

`RetroPickBondingCurveV2` currently permits only `factory` to call `graduate(recipient)`, and the threshold-crossing buy calls that same Factory callback. Rewriting the Curve around a venue would violate the venue-agnostic requirement.

### Recommended extraction shape: Factory-mediated one-hop handoff

```text
caller or Curve auto-graduation callback
  -> Factory.graduate(token)
  -> Factory validates launch, immutable venue, coordinator binding, readiness
  -> coordinator.secure(token)
  -> coordinator calls narrow Factory secure-curve callback
  -> Factory calls curve.graduate(coordinator)
  -> coordinator independently measures exact quote/token receipt
  -> coordinator writes one secured ledger and GRADUATING
  -> Factory emits/records only non-authoritative authority handoff metadata
```

This preserves the Curve's existing immutable Factory trust root and `onlyFactory` graduation guard while making the Coordinator the sole asset recipient and ledger owner. The Factory callback must be bounded to:

- the bound coordinator;
- an existing launch;
- the pre-`GRADUATING` authority state;
- one in-flight secure operation;
- a Curve that has not yet graduated.

The Coordinator, not Factory, records received amounts. A Factory copy of those values would be a second mutable ledger and is prohibited.

### Rejected alternatives

- **Make Curve call Coordinator directly:** the existing Curve Factory identity also authorizes fee/admin operations; repointing it broadly would expand Coordinator authority and require a riskier Curve rewrite.
- **Factory sweeps then transfers to Coordinator:** it reintroduces Factory custody and a second accounting transition without reducing Factory responsibility.
- **Factory retains `Swept` compatibility as authoritative:** it preserves the exact duplicated-state problem DEV-4 must remove.

## 5. State machine and transition ordering

For newly extracted launches:

```text
ACTIVE
  -> secure()
  -> GRADUATING
  -> complete()
  -> GRADUATED
```

### `ACTIVE -> GRADUATING`

Required order:

1. validate immutable launch identity and venue packet;
2. ensure Curve is ready and not already graduated;
3. ensure Coordinator has no prior secured ledger for the launch;
4. perform the one-hop Curve sweep directly to Coordinator;
5. independently measure exact received quote and launch tokens;
6. require nonzero secured assets and exact transfer behavior;
7. write the single authoritative secured ledger;
8. write `GRADUATING`;
9. emit `GraduationSecured`.

If any step reverts, no durable `GRADUATING` ledger may exist. If the Curve has already halted but Coordinator commit did not occur, the exact recovery rule must be specified before implementation; it must not reopen bonding or permit a second asset sweep.

### `GRADUATING -> GRADUATED`

One venue executor transaction performs, in order:

1. revalidate immutable venue packet;
2. validate venue environment and deterministic addresses;
3. deploy/construct or reserve the destination;
4. verify runtime identities and state readback;
5. approve only exact required assets to the pinned spender;
6. seed or mint the destination;
7. verify physical balance deltas and received LP shares;
8. verify protected LP/excess receiver and amounts;
9. verify opening prices/order sizes and accepted tolerances;
10. return an exact completion receipt to Coordinator;
11. Coordinator records destination once;
12. Coordinator writes `GRADUATED` last;
13. Coordinator emits completion.

Any phase-2 revert leaves `GRADUATING`, the secured ledger, and all already-custodied protected assets unchanged. Retry is permissionless and carries no caller discretion. A completed launch rejects duplicate completion before useful asset movement.

## 6. One-ledger conservation requirements

The Coordinator must maintain, for each launch and quote class:

```text
securedQuote
securedLaunchTokens
consumedQuote
consumedLaunchTokens
destinationIdentity
destinationQuote
destinationLaunchTokens
protectedLPReceiver
protectedLPAmount
protectedExcessTokenReceiver
protectedExcessTokenAmount
```

Required invariants:

- `consumedQuote + availableQuote == securedQuote`;
- `consumedLaunchTokens + availableLaunchTokens == securedLaunchTokens`;
- no reusable approval survives a failed or successful executor call;
- physical Coordinator balance is at least available secured assets;
- physical deficits fail closed;
- unsolicited donations do not alter the ledger or seed;
- destination is recorded at most once;
- `GRADUATED` implies the venue receipt passed every verification;
- protected LP/excess custody cannot be redirected after `GRADUATING`.

The Factory may expose a launch-to-coordinator pointer, but must not mirror mutable amounts or phase. Compatibility views, if retained, must clearly derive from or delegate to Coordinator rather than own values.

## 7. Immutable venue commitment

The venue must be committed with launch economics before public bonding:

```text
enum GraduationVenue { UNISWAP_V4, KURU }
```

The selection and its complete immutable packet are fixed before a token, Curve, or public launch is accepted:

- `UNISWAP_V4`: pool fee, tick spacing, executor, custody/locker identity;
- `KURU`: accepted environment manifest version, parameter-class/version, seed tolerance, executor, permanent LP/excess lock.

There is no venue fallback, operator override, or post-bonding change. Completion and every retry dispatch only to the committed venue. This packet leaves the final Kuru/V4 choice set and ADR-009/ADR-020 wording to protocol-owner acceptance.

## 8. Venue-agnostic completion ceiling placement

The repeatable two-raw-unit buy/sell witness falsifies `terminal Q == graduationThreshold`. A LaunchConfig-only all-history bound is therefore not a valid admission rule. The accepted replacement must enforce the stronger whole-transition liveness property:

```text
completionTerminalQuote(nextState) <= graduationQuoteCeiling
```

for every accepted economic transition, where `completionTerminalQuote` uses exact production integer arithmetic for the immediate final buy that exhausts remaining sellable tokens, including:

- current real quote reserve;
- remaining sellable token reserve;
- phantom plus real quote reserve;
- exact `getAmountIn`;
- gross-up ceiling;
- fee flooring;
- creator-tax flooring;
- current buyback/fee/rescue state.

The ceiling is supplied by accepted launch/venue policy at launch. Kuru derives its ceiling from its accepted parameter envelope; V4 derives its own. The Curve contains no venue enum, Router call, Kuru tuple, or `venue == KURU` branch.

The guard must cover buys, sells, fee sweeps, buyback transitions, authorized fee rescue, and any other accepted quote/token reserve transition. A transition that leaves the Curve below its ceiling but without a valid immediate completion path must be rejected. This is stronger than checking `currentQ <= cap` and is the production defense against headroom-consuming deadlock/grief.

Production placement remains blocked until the model is accepted as exact and the owner accepts the policy value/derivation.

## 9. Protected custody boundary

The Kuru executor must send first-deposit LP shares directly to the immutable no-exit lock. The same lock, or an explicitly bound permanent custody contract, receives excluded excess launch tokens. Neither Factory, creator, operator, graduation caller, nor Coordinator operator may transfer, approve, burn, withdraw, or arbitrary-call protected holdings.

P0 has no protected-asset emergency withdrawal. Any unrelated-token rescue must be separately accepted and must exclude:

- the LP share token;
- the launch token;
- every admitted quote asset;
- any venue position representation.

The Coordinator is an authority and ledger owner, not an emergency exit for protected assets.

## 10. Migration and compatibility

Existing V2 launches remain on the current Factory/V4 path. DEV-4 extraction applies to newly created launches unless the owner explicitly accepts a migration.

Required reconciliation before implementation:

1. preserve supported-asset V4 success/failure/retry/replay behavior as the behavioral oracle;
2. choose whether old Factory phase views remain deprecated compatibility views;
3. define launch-id versioning so indexers never interpret old `Swept` as new `GRADUATING`;
4. ensure the new Factory constructor/runtime cannot bind two authoritative coordinators to one launch;
5. qualify code-size reduction after removal, not projected reduction;
6. keep V4 retirement outside DEV-4.

No existing launch may be silently reinterpreted, reopened, or swept a second time.

## 11. Required DEV-4 extraction tests

A research-only extraction fixture should qualify the following before production Solidity:

1. Factory-to-Coordinator authority handoff succeeds exactly once;
2. Curve sends directly to Coordinator and Factory records no duplicate balances;
3. `GRADUATING` survives every injected phase-2 failure;
4. permissionless retry succeeds after each failure;
5. completed launch rejects replay before approvals or asset movement;
6. one-ledger conservation holds across success/failure/retry;
7. malicious/unexpected coordinator callbacks cannot resweep a Curve;
8. venue packet cannot change after public bonding;
9. wrong-venue executor cannot receive or consume secured assets;
10. generic completion ceiling admits only whole transitions retaining an immediate valid completion;
11. protected custody receiver/amounts are immutable after securing;
12. post-extraction Factory runtime is at or below the accepted byte target.

### Current research-fixture result

The bounded fixture at `contracts/test/v2/integration/DEV4GraduationExtractionResearch.t.sol` passes 4/4 for native-MON and ERC20 handoff, durable failure, permissionless retry, replay rejection, protected custody, wrong-executor rejection, and the thin-runtime size boundary. Its research Factory measures 21,810 runtime bytes. Reproducible evidence and limitations are recorded in [DEV-4 Factory-to-Coordinator extraction research](../../../evidence/launchpad/core/dev4-factory-coordinator-extraction-research-2026-10-01.md).

This closes only the first executable-boundary question: the extraction shape can be represented without violating the research size budget. It does not close production extraction, the broader stateful conservation matrix, integrated Core-to-venue qualification, or any owner decision. Items 1, 3, 4, 5, 7, 9, 11, and 12 now have targeted fixture-domain evidence; remaining venue-packet, completion-ceiling, migration, and integrated accounting boundaries stay open.

The existing B8 12/12 fault matrix must be preserved; do not expand it unless a final-architecture boundary is genuinely missing.

## 12. Falsifiers

This architecture is falsified by any of:

- Factory or a second ledger can mutate authoritative secured balances;
- phase 2 partially consumes an asset without accounting or reusable approval;
- a failed completion forces owner intervention to retry;
- duplicate completion moves any protected asset;
- venue or LP receiver changes after public bonding/securing;
- a creator or operator can obtain protected LP shares or excess launch tokens;
- a Curve transition leaves current Q below the cap but no valid immediate completion;
- extracted Factory exceeds the accepted runtime budget;
- existing supported-asset V4 behavior cannot be represented by the V4 executor.

## 13. Remaining blockers

This packet does not close:

- owner acceptance of ADR-009/020 venue policy;
- owner acceptance of ADR-011 quote policy and issuer liveness risk;
- owner acceptance of ADR-021 terminal-Q ceiling and Kuru parameter class;
- owner acceptance of ADR-022 permanent P0 custody;
- owner acceptance of ADR-023 atomic retry packet;
- production extraction implementation and broader stateful conservation tests beyond the new bounded research fixture;
- accepted generic completion-ceiling placement in Curve;
- Factory code-size reduction proof;
- real integrated Core-to-venue qualification.

Accordingly, `CORE_BASELINE_P0_QUALIFIED`, `KURU_TARGET_DEV_FROZEN`, and `READY_FOR_DEV4_KURU_EXECUTOR` remain blocked.

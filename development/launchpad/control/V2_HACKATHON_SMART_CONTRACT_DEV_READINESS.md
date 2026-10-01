---
id: LP-V2-HACKATHON-SMART-CONTRACT-DEV-READINESS
status: conditional_pass
scope: hackathon_smart_contract_development_only
owner: launchpad-solidity
version: v2
---

# V2 smart-contract hackathon development readiness

## Decision

**V2_HACKATHON_SMART_CONTRACT_DEV_READY = CONDITIONAL_PASS**

This is a deliberately lower, scoped development-readiness standard for a hackathon implementation track. It is **not** production/P0 qualification, does not accept any proposed ADR, and does not authorize staging or mainnet deployment.

The broader `HACKATHON_READY` product gate remains blocked because a full product hackathon requires more than smart-contract research readiness.

## Lower standard

Hackathon smart-contract development may begin when:

1. the current V2 source baseline and target boundaries are explicit;
2. supported native-MON and canonical chain-10143 Circle-USDC paths have focused passing evidence;
3. Kuru environment, real pinned-fork deploy/seed, custody, retry, drift, and gas rows pass in a declared research-fixture domain;
4. terminal-Q path dependence is understood rather than hidden;
5. Factory extraction has an executable passing research fixture and explicit size target;
6. permanent protected-custody and durable-retry behavior have bounded evidence;
7. unresolved owner decisions can be encoded as hard development guards;
8. the output remains clearly labeled hackathon-stage and cannot be promoted to production.

## Current research inventory

### Core / V4

- Production FeeEscrow, Curve, and exact quote guards pass their declared supported-asset domains.
- Native MON and canonical Circle USDC V4 success/failure/retry/replay behavior is recorded as the behavioral oracle.
- Near-graduation buyback fold-back, repeated sweeps, and partial/full vesting are covered.
- The known sender-surcharge and externally reducible quote accounting defects are closed in tested supported paths by fail-closed accounting.
- The current production Factory is 24,565 bytes: only 11 bytes below EIP-170, so it has zero feature headroom.
- The new extraction research fixture passes native/ERC20 failure, retry, replay, custody, wrong-executor, and thin-runtime properties; its Factory runtime is 21,810 bytes.

Primary evidence:

- `evidence/launchpad/core/dev4-core-quote-invariant-increment-2026-09-30.md`
- `evidence/launchpad/core/dev4-supported-asset-buyback-vesting-2026-10-01.md`
- `evidence/launchpad/core/v4-supported-asset-behavior-oracle-2026-09-30.md`
- `evidence/launchpad/core/factory-code-size-2026-10-01.md`
- `evidence/launchpad/core/dev4-factory-coordinator-extraction-research-2026-10-01.md`

### Terminal-Q / Kuru envelope

- `terminal secured Q == graduationThreshold` is falsified.
- A valid two-raw-unit buy/sell cycle restores the token reserve while increasing real quote reserve by one raw unit and is repeatably pumpable.
- Therefore unrestricted `LaunchConfig` alone cannot establish a finite all-history terminal-Q bound.
- The recommended replacement is an immutable venue-generic `graduationQuoteCeiling` checked as exact `completionTerminalQuote(state) <= ceiling` after every accepted transition.
- Every integer terminal Q from the exact immediate-completion lower bound through the declared 50× threshold domain is admissible in the pinned reduced model for five positive profiles and both P0 quote classes.
- That is declared-domain research evidence, not an accepted economic ceiling or all-history reachable-state proof.

Primary evidence:

- `evidence/launchpad/kuru/prelaunch-round-trip-witness-2026-09-30.md`
- `evidence/launchpad/kuru/completion-liveness-research-2026-10-01.md`
- `evidence/launchpad/kuru/p0-terminal-envelope-2026-10-01.md`
- `evidence/launchpad/kuru/exact-terminal-q-admissibility-2026-10-01.md`

### Kuru integration

Kuru B1 and B5–B10 pass in the pinned research-fixture domain:

- environment identity;
- real Router market deployment;
- real vault first seed;
- protected LP/excess custody;
- failure/retry/replay;
- observable drift rejection;
- deterministic MON/Circle gas matrix.

B2 quote policy, B3 parameters, and B4 accepted seed envelope remain decision-gated. B11 live testnet and B12 two-party usability are intentionally not run and remain post-implementation staging evidence.

Primary evidence:

- `evidence/launchpad/kuru/kuru-benchmark-gates-2026-09-30.yaml`
- `evidence/launchpad/kuru/final-custody-drift-gas-increment-2026-10-01.md`

## Hackathon development guards

Hackathon code must implement against these hard restrictions:

1. Factory stays thin; no Kuru logic or secured-asset custody enters Factory.
2. Target boundary is Factory → Coordinator → venue executor → protected custody.
3. Venue is immutable before public bonding; no fallback between Kuru and V4.
4. Quotes are native MON or canonical chain-10143 Circle USDC only.
5. Address `0x3bA3d39AFcf8bb994f7964B3e0171Ea2Ba361570` is `KURU_TEST_USDC`, never canonical Circle USDC.
6. Creators never provide raw Kuru parameters.
7. `GRADUATING` is durable, phase 2 is atomic, retry is permissionless, and completed graduation cannot replay.
8. LP shares and excess launch tokens go directly to a permanent P0-style no-exit protected custody.
9. The Curve remains venue-agnostic; the accepted completion ceiling must be modeled as a generic launch bound, not a Kuru branch.
10. B11/B12 live testnet work is not claimed until a deployable integrated implementation exists.

## Why this is not P0 readiness

The strict gates remain:

- `CORE_BASELINE_P0_QUALIFIED = BLOCKED`
- `KURU_TARGET_DEV_FROZEN = BLOCKED`
- `READY_FOR_DEV4_KURU_EXECUTOR = BLOCKED`
- `KURU_TARGET_FROZEN = BLOCKED`
- `KURU_LIVE_TESTNET_QUALIFIED = BLOCKED`

Missing for production/P0 qualification include accepted ADRs, accepted economic ceilings and parameter classes, production Factory extraction, integrated stateful invariants, and live integrated qualification.

## Recommended hackathon track

Start with research-to-implementation scaffolding in this order:

1. narrow interfaces and shared types;
2. Factory secure-callback extraction;
3. Coordinator secured-packet ledger;
4. protected custody;
5. environment and parameter-policy libraries;
6. venue executors behind the immutable packet;
7. differential and fault tests;
8. integrated fork qualification.

The hackathon track should produce auditable candidate contracts and tests, not a deployment candidate.

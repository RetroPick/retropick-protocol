# Completion-Liveness Expanded Bounded Campaign — 2026-10-01

**Status:** `SUPPORTED_BY_SIMULATION` within a bounded model domain; not an accepted production guard or Kuru policy.
**Branch:** `codex/kuru-freeze-smart-contract-spec`.
**HEAD before this increment:** `c48a4b129cb984a0ef9f613db3201606b8235de4`.
**Generator:** `research/integration/kuru/curve_liveness_campaign.py` (`run_campaign`, schema version 2).
**Machine evidence:** `evidence/launchpad/kuru/curve-liveness-campaign-2026-10-01.json`.
**Production Solidity changed:** none. **Live transactions sent:** none.

## Research question

The prior assumption that terminal secured quote equals the nominal graduation threshold is false. A fresh-state buy of two raw quote units followed by sale of exactly the purchased launch tokens restores the tracked-token reserve and increases real quote by at least one raw unit. This is repeatably pumpable. Consequently, an unrestricted history-dependent terminal quote has no tight upper bound derived from `LaunchConfig` alone; no such bound should be claimed for the current state machine.

The replacement venue-agnostic safety/liveness question is whether every accepted state retains an immediate valid completion path whose terminal quote remains within an accepted immutable graduation ceiling:

```text
completionTerminalQuote(state) <= graduationQuoteCeiling
```

The exact production-integer model in `completion_terminal_quote.py` is used throughout. For every accepted intermediate state with sellable tokens, the campaign rechecks exact completion arithmetic against `CurveState.completion()`.

## Expanded bounded domain

The expanded campaign covers 48 deterministic histories:

- eight launch/economic profiles: `BASELINE`, `MINIMUM_VALID`, `SMALL`, `MEDIUM_NONDIVISIBLE`, `HIGH_COMBINED_FEE`, `ZERO_FEE`, `LARGE`, and `MAXIMUM_CANDIDATE`;
- quote scales 18 decimals (native-MON-like) and 6 decimals (Circle-USDC-like);
- seeds `20260930`, `20261001`, and `20261002`;
- 220 randomized modeled attempts after each structured prelude.

Every history first executes four fresh-state two-raw-unit pump cycles, performs a local boundary rejection immediately after a post-buy completion, finds the first terminal-crossing gross buy with exact checked arithmetic, attempts the immediately preceding near-crossing buy, then attempts a one-token sale and a fee rescue when fee buckets exist. Random actions include buys, sells, sweeps, authorized fee rescue, and a reduced-model buyback toggle.

Observed totals:

```text
histories        = 48
accepted         = 4,954
ceiling rejected = 48
invalid calls    = 6,176
```

All 48 pump preludes complete four cycles and gain positive real quote. All 48 near-crossing one-token sells are rejected by the current production-integer model for `zero gross quote output`; this records the actual transition boundary, not a guard exception. All 48 local boundary probes use a transition-local ceiling equal to the immediate post-buy completion and reject the following sell as a whole transition. These 48 rejections are distinct from the broader illustrative campaign ceiling.

## Ceiling interpretation

The campaign ceiling is:

```text
max(graduationThreshold, freshCompletion)
+ max(oneQuoteUnit, thatBase // 100)
```

It is deliberately labeled illustrative. Fresh completion can differ materially from nominal threshold because launch tokens are integer quantities and the reserved-token allocation is floored. In particular, `MEDIUM_NONDIVISIBLE` fresh completion is about 6.28% above nominal threshold, while `MAXIMUM_CANDIDATE` is about 10.8% above; other geometries can complete below nominal threshold. Therefore a threshold-plus-fixed-percentage rule is not universally valid. No value in this artifact is an accepted Kuru or Launchpad ceiling.

The local boundary probe instead sets its ceiling to the immediate post-buy completion only, demonstrating that admission of that intermediate state would make the following sell unable to satisfy the same local bound. It is evidence for whole-transition admission, not production policy.

## Limitations

- This is a bounded multi-profile model campaign, not an exhaustive or symbolic all-configuration proof.
- Authorization, ERC20/native transfer, callbacks, external custody, Factory state, and venue execution are abstracted.
- Buyback enable/disable is a reduced-model field toggle, not a production transaction.
- The illustrative ceiling has no accepted protocol authority.
- The campaign does not qualify the production Kuru executor, coordinator, lock, Factory integration, or live market.
- These results do not promote `CORE_BASELINE_P0_QUALIFIED` or `KURU_TARGET_DEV_FROZEN`.

## Consequence

The accepted policy still needs to choose a generic immutable `graduationQuoteCeiling`, define its derivation from an accepted launch/venue envelope, and specify whether all economic transitions (including buys, sells, sweeps, and authorized rescues) are admitted only when their resulting immediate completion remains at or below that ceiling. Until that decision and broader qualification exist, `KURU_TARGET_DEV_FROZEN` remains blocked.

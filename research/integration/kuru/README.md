# Kuru Integration Research

This is the active Launchpad Core V2 graduation-destination research lane for
Kuru on Monad. It models the RetroPick-owned economic derivation and checks it
against the external Kuru implementation. It is not production Solidity and
does not freeze the Kuru target by itself.

Current authoritative integration status is recorded in:

- [development/launchpad/control/status.yaml](../../../development/launchpad/control/status.yaml)
- [development/launchpad/integrations/KURU_BENCHMARK_GATE.md](../../../development/launchpad/integrations/KURU_BENCHMARK_GATE.md)
- [development/launchpad/integrations/KURU_TARGET_FREEZE_PACKET.md](../../../development/launchpad/integrations/KURU_TARGET_FREEZE_PACKET.md)
- [evidence/launchpad/kuru/](../../../evidence/launchpad/kuru/)

## Research target

The architecture direction keeps the current Factory thin and moves graduation
coordination and venue-specific execution out of it:

```text
RetroPickLaunchFactoryV2
  -> GraduationCoordinatorV2
     -> V4GraduationExecutorV2
     -> KuruGraduationExecutorV2
        -> Kuru Router
           -> OrderBook
           -> Kuru AMM Vault
              -> RetroPick protected LP/excess custody
```

This is mandatory because the current Factory runtime is 24,565 bytes against
the 24,576-byte EIP-170 limit, leaving only 11 bytes. Kuru logic must not be
embedded in that contract.

The researched P0 custody rule sends first-deposit LP shares and excluded
excess launch tokens to permanent protected custody. For P0 there is no
protected-asset emergency-exit shortcut.

## Central terminal-Q result

The old assumption:

```text
terminal secured Q == graduationThreshold
```

is falsified.

[`prelaunch_round_trip_witness.py`](prelaunch_round_trip_witness.py) and the
related campaign show a repeatable raw-unit cycle:

```text
buy 2 raw quote units
sell exactly the purchased launch tokens
tracked token reserve restored
real quote reserve increased
```

The behavior is repeatably pumpable. Therefore unrestricted `LaunchConfig`
alone cannot prove a tight all-history terminal-Q envelope, and threshold-only
admission is invalid.

The stronger replacement property is:

```text
completionTerminalQuote(state) <= graduationQuoteCeiling
```

where `completionTerminalQuote` is calculated with the same exact production
integer arithmetic as an immediate final buy of all remaining sellable launch
tokens. This property guarantees a valid completion path rather than merely
checking the current reserve. The Curve stays venue-agnostic: the accepted
graduation policy supplies the ceiling, and the Curve enforces generic
completion liveness.

## Declared admissibility domain

The current exact-domain result covers every integer terminal Q from each
profile's exact immediate-completion lower bound through the declared 50x
graduation-threshold upper bound for:

- `MINIMUM_VALID_LAUNCH`
- `SMALL`
- `MEDIUM`
- `LARGE`
- `MAXIMUM_SUPPORTED_CANDIDATE`

and both P0 quote classes:

- native MON;
- canonical chain-10143 Circle test USDC.

Checks include:

- `B = floor(T * Q / (P + Q)) > 0`;
- accepted precision and tick domain;
- representable first ask/bid;
- nonzero and in-range vault bid/ask sizes;
- positive LP shares;
- integer-width safety.

Classification:

```text
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
```

This is a reduced-model result only. It is not an all-history reachable-Q
proof, accepted economic policy, real-Router qualification by itself, or
authority to implement production Kuru Solidity.

## Quote identity

P0 research distinguishes contracts by chain and address, never by symbol.

| Label | Chain | Address | Use |
| --- | --- | --- | --- |
| Canonical Circle test USDC | 10143 | `0x534b2f3A21130d7a60830c2Df862319e593943A3` | Selected canonical Circle quote candidate |
| `KURU_TEST_USDC` | 10143 | `0x3bA3d39AFcf8bb994f7964B3e0171Ea2Ba361570` | Compatibility fixture only |

The Kuru-listed compatibility fixture must not be reported as Circle USDC.

## File map

### Source and compatibility analysis

- [KURU_TOKEN_COMPATIBILITY.md](KURU_TOKEN_COMPATIBILITY.md): token classes,
  observed external behavior, and compatibility risks.
- [PARAMETER_WORKSHEET.md](PARAMETER_WORKSHEET.md): market tuple inputs,
  derivations, candidate policies, and open decisions.
- [calculate_precisions.mjs](calculate_precisions.mjs): SDK precision
  calculation cross-check. It is a compatibility check, not the canonical
  RetroPick economic derivation.

### Seed and profile models

- [launchpad_seed_model.py](launchpad_seed_model.py): exact first-seed integer
  arithmetic.
- [benchmark_launch_profiles.py](benchmark_launch_profiles.py): representative
  launch profiles and initial parameter candidates.
- [test_launchpad_seed_model.py](test_launchpad_seed_model.py): exact seed-model
  regression tests.

Historical profile scripts may state `Q == threshold`; that assumption is
historical and is superseded for final graduation admission by the terminal-Q
models below.

### Curve completion and liveness

- [completion_terminal_quote.py](completion_terminal_quote.py): exact
  immediate-completion terminal quote calculation.
- [curve_liveness_model.py](curve_liveness_model.py): reduced state machine for
  accepted transitions and completion.
- [curve_liveness_campaign.py](curve_liveness_campaign.py): exact production
  arithmetic campaign and completion differential checks.
- [completion_liveness_witness.py](completion_liveness_witness.py): compact
  liveness/deadlock witness generation.
- [test_curve_liveness_model.py](test_curve_liveness_model.py): invariant and
  transition tests.

### Terminal-Q witnesses and envelopes

- [prelaunch_quote_witness.py](prelaunch_quote_witness.py): prelaunch reserve
  witness.
- [prelaunch_round_trip_witness.py](prelaunch_round_trip_witness.py): minimized
  repeatably pumpable buy/sell cycle.
- [bounded_q_envelope.py](bounded_q_envelope.py): bounded envelope attack.
- [wide_q_envelope.py](wide_q_envelope.py): wider search profile.
- [terminal_q_interval.py](terminal_q_interval.py): monotonic endpoint checks.
- [terminal_q_exact_admissibility.py](terminal_q_exact_admissibility.py):
  exhaustive integer admissibility inside the declared domain.
- [p0_terminal_envelope.py](p0_terminal_envelope.py): five-profile, two-quote
  P0 envelope.
- [test_terminal_q_interval.py](test_terminal_q_interval.py)
- [test_terminal_q_exact_admissibility.py](test_terminal_q_exact_admissibility.py)
- [test_p0_terminal_envelope.py](test_p0_terminal_envelope.py)

## Run

```bash
cd research/integration/kuru
python3 -m unittest discover -s . -p 'test_*.py' -v
```

The unit suite exercises the local exact models. It does not replace pinned
real-Router fork evidence, external fault injection, gas matrices, accepted
ADRs, or later live qualification.

## Non-goals

- No production `KuruGraduationExecutorV2`.
- No Factory expansion or Kuru-specific branch inside the bonding Curve.
- No creator-supplied raw Kuru market parameters.
- No reinterpretation of Kuru liquidity as RetroPick backing.
- No substitution of the Kuru-listed compatibility token for canonical Circle
  USDC.
- No declaration of staging, mainnet, audit, or DEV-4 readiness from this lane
  alone.

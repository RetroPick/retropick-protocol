# Exact terminal-Q admissibility over a declared 50× domain

**Classification:** `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN` for every integer raw terminal `Q` in each declared interval under the pinned reduced-model predicates; `NOT_YET_VALIDATED` for accepted economics, production enforcement, and real Router/vault execution at those boundaries.

- Branch: `codex/kuru-freeze-smart-contract-spec`
- Parent research baseline: `c38c92ea6c458d39e75779fed999e5d126428ab9`
- Generator: `research/integration/kuru/terminal_q_exact_admissibility.py`
- Machine artifact: `evidence/launchpad/kuru/exact-terminal-q-admissibility-2026-10-01.json`
**Production Solidity changed:** none. **Live transactions sent:** none. **ADR status changed:** none.

## Research result

For each of the five positive P0 launch profiles and each P0 quote class, this packet proves every inclusive integer terminal `Q` from the exact immediate-completion lower bound through `50 × graduationThreshold` admissible under the pinned reduced first-deposit model:

- native MON, 18 decimals;
- canonical chain-10143 Circle test USDC, six decimals, address `0x534b2f3A21130d7a60830c2Df862319e593943A3`.

The checked profiles are `MINIMUM_VALID_LAUNCH`, `SMALL`, `MEDIUM`, `LARGE`, and `MAXIMUM_SUPPORTED_CANDIDATE`. The `FACTORY_MINIMUM_NEGATIVE` one-token profile remains a permanent negative control because it is outside the P0 launch envelope under the candidate minimum-size rule; its exclusion is not a claim that every raw Q in its geometry is otherwise unseedable.

For every `Q` in each positive interval, the proof covers:

- positive base seed `B = floor(T·Q/(P+Q))`, with non-seed excess retained;
- pinned Router parameter predicates and size/price precision domains;
- Kuru minimum and maximum order-size bounds;
- representable opening bid and ask plus valid tick spacing;
- the candidate five-bps combined seed/tick error bound;
- nonzero vault bid and ask sizes;
- positive first-deposit LP shares;
- uint256 arithmetic intermediates and uint96 vault-size bounds.

## Proof method

The proof combines:

1. conservative uniform bounds for the non-monotone floor-derived seed residual and tick residual; and
2. monotone bounds for base seed, vault sizes, LP shares, tick upper limits, and integer-width limits.

The lower and upper endpoints are additionally checked by the exact reduced-model predicate. A `True` result proves every integer `Q` in the declared interval. A `False` result would only mean this sufficient interval proof failed; it would not prove an interior point inadmissible.

This packet does not enumerate every 18-decimal integer. Exhaustive enumeration remains practical only for small intervals and is retained as a test cross-check.

## Why 50× rather than 100×

The earlier 100× threshold artifact was a stress domain for isolated wide intervals, and the subsequent sufficient-envelope packet reports conservative boundaries, not owner-selectable economics. The narrower 50× domain is used here because its five-profile, two-quote matrix can be stated as one continuous technically proven candidate envelope without claiming an economic ceiling.

The protocol owner may choose a smaller multiplier. Exceeding 50× requires either a new exact declared-domain proof or a separately accepted policy with explicit evidence outside this packet.

## What this does not prove

- It does not bound every reachable terminal `Q` produced by the unrestricted current Curve history.
- It does not discover the exact mathematical maximum admissible `Q`.
- It does not accept `graduationQuoteCeiling`, the five-bps error cap, or any Kuru tuple.
- It does not prove the real Router/vault at every declared boundary.
- It does not implement or qualify a production completion guard.
- It does not resolve the one-token Factory-minimum policy contradiction.
- It does not accept ADR-021 or authorize the production Kuru executor.

The repeatable two-raw-unit buy/sell pump remains a preserved counterexample to any threshold-only or configuration-derived all-history claim. The production-facing requirement remains an accepted venue-agnostic completion-ceiling policy plus exact whole-transition enforcement and real-fork boundary qualification.

## Reproduce

Run from `research/integration/kuru` so local research modules import correctly:

```bash
python3 terminal_q_exact_admissibility.py
python3 -m unittest -v test_terminal_q_exact_admissibility.py
python3 -m unittest discover -s research/integration/kuru -p 'test_*.py'
```

The machine artifact is generated from the module directory with `build_declared_p0_matrix()` and `json.dumps(..., indent=2)`.

"""Reproducible bounded stateful campaigns for the proposed generic guard.

The 2026-09-30 single-profile generator is retained verbatim as legacy
evidence. ``run_campaign`` is the expanded multi-profile campaign and must
remain deterministic so its dated JSON artifact can be regenerated exactly.
"""

import json
import random
from dataclasses import replace

from completion_terminal_quote import (
    CurveCompletionState, completion_terminal_quote, terminal_quote_lower_bound,
)
from curve_liveness_model import (
    CompletionCeilingRejected, CurveState, TradeRejected, admit_transition,
)


SEEDS = (20260930, 20261001, 20261002)
RANDOM_STEPS_PER_HISTORY = 300
EXPANDED_RANDOM_STEPS_PER_HISTORY = 220


Profiles = tuple[
    str,
    int,  # whole launch supply
    int,  # whole phantom quote
    int,  # whole graduation threshold
    int,  # curve fee bps
    int,  # creator tax bps
    bool, # initial buyback setting
]


EXPANDED_PROFILES: tuple[Profiles, ...] = (
    ("BASELINE", 1_000_000, 100, 100, 100, 50, False),
    ("MINIMUM_VALID", 1_000, 1, 1, 100, 50, False),
    ("SMALL", 100_000, 10, 11, 100, 50, False),
    ("MEDIUM_NONDIVISIBLE", 1_000_000, 100, 97, 200, 300, False),
    ("HIGH_COMBINED_FEE", 1_000_000, 100, 100, 1_000, 1_000, False),
    ("ZERO_FEE", 1_000_000, 100, 100, 0, 0, False),
    ("LARGE", 100_000_000, 1_000, 1_001, 100, 50, True),
    ("MAXIMUM_CANDIDATE", 1_000_000_000, 10_000, 9_500, 100, 50, True),
)


def run_legacy_campaign() -> dict:
    rows = []
    for decimals in (18, 6):
        for seed in SEEDS:
            rng = random.Random(seed + decimals)
            state = CurveState(
                phantom_quote=100 * 10**decimals,
                reserved_tokens=500_000 * 10**18,
                tracked_tokens=1_000_000 * 10**18,
            )
            ceiling = state.phantom_quote + 10  # Illustrative, not accepted.
            initial_product = state.reserve_product
            lower_bound = terminal_quote_lower_bound(
                initial_tokens=state.tracked_tokens,
                phantom_quote=state.phantom_quote,
                reserved_tokens=state.reserved_tokens,
            )
            assert state.completion() <= ceiling
            accepted = 0
            ceiling_rejected = 0
            invalid = 0
            action_counts = {"buy": 0, "sell": 0, "sweep": 0, "toggle_buyback": 0}
            # Reach the boundary with four accepted two-raw-unit cycles.
            for _ in range(4):
                bought_state, tokens, _ = state.buy(2)
                state = admit_transition(bought_state, ceiling)
                assert state.reserve_product >= initial_product
                sold_state, _ = state.sell(tokens)
                state = admit_transition(sold_state, ceiling)
                assert state.reserve_product >= initial_product
                accepted += 2
                action_counts["buy"] += 1
                action_counts["sell"] += 1

            for _ in range(RANDOM_STEPS_PER_HISTORY):
                choice = rng.randrange(5)
                action = ("buy", "buy", "sell", "sweep", "toggle_buyback")[choice]
                action_counts[action] += 1
                try:
                    if action == "buy":
                        gross = rng.choice((1, 2, 3, 10, 100, 10**decimals,
                                            20 * 10**decimals))
                        candidate, _, _ = state.buy(gross)
                    elif action == "sell":
                        quantity = rng.choice((1, max(1, state.user_tokens // 2),
                                               state.user_tokens))
                        candidate, _ = state.sell(quantity)
                    elif action == "sweep":
                        candidate = state.sweep(min_buyback_tokens_out=1)
                    else:
                        candidate = replace(state, buyback_enabled=not state.buyback_enabled)
                    candidate = admit_transition(candidate, ceiling)
                except CompletionCeilingRejected:
                    ceiling_rejected += 1
                except (TradeRejected, OverflowError, ValueError):
                    invalid += 1
                else:
                    state = candidate
                    accepted += 1
                    assert state.completion() <= ceiling
                    assert state.completion() >= lower_bound
                    assert state.reserve_product >= initial_product
                    if state.sellable_tokens:
                        exact = completion_terminal_quote(CurveCompletionState(
                            phantom_quote=state.phantom_quote,
                            tracked_quote=state.tracked_quote,
                            quote_fee_balance=state.quote_fee_balance,
                            creator_tax_balance=state.creator_tax_balance,
                            tracked_tokens=state.tracked_tokens,
                            reserved_tokens=state.reserved_tokens,
                            curve_fee_bps=state.fee_bps,
                            creator_tax_bps=state.tax_bps,
                        ))
                        assert exact.gross_quote_in > 0
                        assert exact.terminal_real_quote == state.completion()
            rows.append({
                "quote_decimals": decimals,
                "seed": seed,
                "prelude_accepted_calls": 8,
                "random_attempts": RANDOM_STEPS_PER_HISTORY,
                "accepted_total": accepted,
                "ceiling_rejected": ceiling_rejected,
                "invalid_calls": invalid,
                "action_attempts": action_counts,
                "final_immediate_terminal_quote_raw": state.completion(),
                "ceiling_raw": ceiling,
            })
    return {
        "schema_version": 1,
        "classification": "BOUNDED_MODEL_CAMPAIGN_NOT_PRODUCTION_GUARD_PROOF",
        "domain": "single aggregate holder; exact-transfer quote; current buy/sell/sweep integer model; native 18 and Circle-like 6 decimals",
        "seeds": list(SEEDS),
        "random_steps_per_history": RANDOM_STEPS_PER_HISTORY,
        "rows": rows,
        "totals": {
            "accepted": sum(row["accepted_total"] for row in rows),
            "ceiling_rejected": sum(row["ceiling_rejected"] for row in rows),
            "invalid_calls": sum(row["invalid_calls"] for row in rows),
        },
    }


def _first_crossing_gross(state: CurveState) -> int | None:
    """Smallest exact-input buy that exhausts remaining sellable tokens.

    The search is deterministic and uses only the model's checked arithmetic.
    It is an adversarial prelude helper, not a proposed production routine.
    """
    if state.sellable_tokens == 0:
        return None
    low, high = 1, 1
    crossing = None
    while high <= 2 * 10**30:
        try:
            candidate, _, _ = state.buy(high)
        except (TradeRejected, OverflowError):
            low = high + 1
            high *= 2
            continue
        if candidate.sellable_tokens == 0:
            crossing = high
            break
        low = high + 1
        high *= 2
    if crossing is None:
        return None
    while low < crossing:
        mid = (low + crossing) // 2
        try:
            candidate, _, _ = state.buy(mid)
        except (TradeRejected, OverflowError):
            low = mid + 1
            continue
        if candidate.sellable_tokens == 0:
            crossing = mid
        else:
            low = mid + 1
    return crossing


def _run_expanded_history(profile: Profiles, decimals: int, seed: int) -> dict:
    name, whole_supply, whole_phantom, whole_threshold, fee_bps, tax_bps, buyback = profile
    rng = random.Random(seed + decimals + sum(profile[1:6]))
    quote_unit = 10**decimals
    phantom = whole_phantom * quote_unit
    threshold = whole_threshold * quote_unit
    state = CurveState(
        phantom_quote=phantom,
        reserved_tokens=whole_supply * 10**18
            - whole_supply * 10**18 * phantom // (phantom + threshold),
        tracked_tokens=whole_supply * 10**18,
        fee_bps=fee_bps,
        tax_bps=tax_bps,
        buyback_enabled=buyback,
    )
    # One percent (at least one quote unit) above the unavoidable fresh-state
    # completion is an illustrative research ceiling. Some legal launch
    # geometries have a fresh completion above -- or materially below -- the
    # nominal threshold because the reserved-token floor is floored, so using
    # threshold alone would reject an unlaunched valid state. This remains
    # research-only policy, not an accepted Kuru or Launchpad bound.
    fresh_completion = state.completion()
    ceiling = max(threshold, fresh_completion) + max(
        quote_unit, max(threshold, fresh_completion) // 100
    )
    initial_product = state.reserve_product
    lower_bound = terminal_quote_lower_bound(
        initial_tokens=state.tracked_tokens,
        phantom_quote=state.phantom_quote,
        reserved_tokens=state.reserved_tokens,
    )
    assert fresh_completion <= ceiling

    action_counts = {
        "buy": 0,
        "sell": 0,
        "sweep": 0,
        "rescue_fees": 0,
        "model_buyback_toggle": 0,
    }
    accepted = 0
    ceiling_rejected = 0
    invalid = 0
    prelude = {
        "first_terminal_crossing_gross_raw": None,
        "fresh_pump": {
            "cycles_attempted": 4,
            "accepted": 0,
            "ceiling_rejected": 0,
            "invalid_calls": 0,
            "buy_failure_reasons": [],
            "sell_failure_reasons": [],
            "quote_gain_raw": 0,
        },
        "near_crossing_buy_gross_raw": None,
        "near_crossing_buy": {
            "accepted": False,
            "ceiling_rejected": False,
            "invalid_reason": None,
        },
        "near_crossing_one_token_sell": {
            "attempted": False,
            "accepted": False,
            "ceiling_rejected": False,
            "invalid_reason": None,
        },
        "fee_rescue": {
            "attempted": False,
            "accepted": False,
            "ceiling_rejected": False,
            "invalid_reason": None,
        },
        "accepted": 0,
        "invalid_calls": 0,
        "ceiling_rejected": 0,
        "pump_cycles_accepted": 0,
    }

    # Execute the known two-raw-unit round trip from a fresh state, before a
    # near-terminal buy makes the marginal token too inexpensive to sell.
    # This is the smallest repeatably pumpable witness in the current model.
    fresh_real_quote = state.real_quote
    for cycle_index in range(4):
        try:
            bought, pump_tokens, _ = state.buy(2)
            bought = admit_transition(bought, ceiling)
        except CompletionCeilingRejected:
            prelude["fresh_pump"]["ceiling_rejected"] += 1
            prelude["ceiling_rejected"] += 1
            break
        except (TradeRejected, OverflowError, ValueError) as exc:
            prelude["fresh_pump"]["invalid_calls"] += 1
            prelude["fresh_pump"]["buy_failure_reasons"].append(str(exc))
            prelude["invalid_calls"] += 1
            break
        try:
            sold, _ = bought.sell(pump_tokens)
            sold = admit_transition(sold, ceiling)
        except CompletionCeilingRejected:
            prelude["fresh_pump"]["ceiling_rejected"] += 1
            prelude["ceiling_rejected"] += 1
            break
        except (TradeRejected, OverflowError, ValueError) as exc:
            prelude["fresh_pump"]["invalid_calls"] += 1
            prelude["fresh_pump"]["sell_failure_reasons"].append(str(exc))
            prelude["invalid_calls"] += 1
            break
        state = sold
        prelude["accepted"] += 2
        prelude["fresh_pump"]["accepted"] += 2
        prelude["pump_cycles_accepted"] = cycle_index + 1
    prelude["fresh_pump"]["quote_gain_raw"] = state.real_quote - fresh_real_quote

    # At the post-pump state, pin the ceiling to the immediate post-buy
    # completion and prove that the next exact-token sell is rejected as a
    # whole transition. This is a local boundary probe; it does not alter the
    # research ceiling used by the rest of the campaign.
    prelude["boundary_sell_probe"] = {
        "attempted": False,
        "accepted": False,
        "ceiling_rejected": False,
        "invalid_reason": None,
        "boundary_ceiling_raw": None,
    }
    try:
        probe_bought, probe_tokens, _ = state.buy(2)
        boundary_ceiling = probe_bought.completion()
        admit_transition(probe_bought, boundary_ceiling)
        probe_sold, _ = probe_bought.sell(probe_tokens)
        prelude["boundary_sell_probe"]["attempted"] = True
        prelude["boundary_sell_probe"]["boundary_ceiling_raw"] = boundary_ceiling
        admit_transition(probe_sold, boundary_ceiling)
    except CompletionCeilingRejected:
        prelude["boundary_sell_probe"]["ceiling_rejected"] = True
        prelude["ceiling_rejected"] += 1
    except (TradeRejected, OverflowError, ValueError) as exc:
        prelude["boundary_sell_probe"]["invalid_reason"] = str(exc)
        prelude["invalid_calls"] += 1
    else:
        state = probe_sold
        prelude["boundary_sell_probe"]["accepted"] = True
        prelude["accepted"] += 2

    crossing = _first_crossing_gross(state)
    if crossing is not None:
        prelude["first_terminal_crossing_gross_raw"] = crossing
        near_gross = max(1, crossing - 1)
        prelude["near_crossing_buy_gross_raw"] = near_gross
        try:
            bought, _, _ = state.buy(near_gross)
            bought = admit_transition(bought, ceiling)
        except CompletionCeilingRejected:
            prelude["near_crossing_buy"]["ceiling_rejected"] = True
            prelude["ceiling_rejected"] += 1
        except (TradeRejected, OverflowError, ValueError) as exc:
            prelude["near_crossing_buy"]["invalid_reason"] = str(exc)
            prelude["invalid_calls"] += 1
        else:
            state = bought
            prelude["near_crossing_buy"]["accepted"] = True
            prelude["accepted"] += 1

    if state.user_tokens and state.sellable_tokens:
        prelude["near_crossing_one_token_sell"]["attempted"] = True
        try:
            sold, _ = state.sell(1)
            sold = admit_transition(sold, ceiling)
        except CompletionCeilingRejected:
            prelude["near_crossing_one_token_sell"]["ceiling_rejected"] = True
            prelude["ceiling_rejected"] += 1
        except (TradeRejected, OverflowError, ValueError) as exc:
            prelude["near_crossing_one_token_sell"]["invalid_reason"] = str(exc)
            prelude["invalid_calls"] += 1
        else:
            state = sold
            prelude["near_crossing_one_token_sell"]["accepted"] = True
            prelude["accepted"] += 1

    if state.quote_fee_balance or state.creator_tax_balance:
        prelude["fee_rescue"]["attempted"] = True
        try:
            rescued = admit_transition(state.rescue_fees(), ceiling)
        except CompletionCeilingRejected:
            prelude["fee_rescue"]["ceiling_rejected"] = True
            prelude["ceiling_rejected"] += 1
        except (TradeRejected, OverflowError, ValueError) as exc:
            prelude["fee_rescue"]["invalid_reason"] = str(exc)
            prelude["invalid_calls"] += 1
        else:
            state = rescued
            prelude["fee_rescue"]["accepted"] = True
            prelude["accepted"] += 1

    # Exercise the reduced-model authority toggle once from the opposite
    # setting so both sweep behaviors are reachable in every history.
    action_counts["model_buyback_toggle"] += 1
    try:
        candidate = replace(state, buyback_enabled=not state.buyback_enabled)
        candidate = admit_transition(candidate, ceiling)
    except CompletionCeilingRejected:
        ceiling_rejected += 1
    except (TradeRejected, OverflowError, ValueError):
        invalid += 1
    else:
        state = candidate
        accepted += 1

    for _ in range(EXPANDED_RANDOM_STEPS_PER_HISTORY):
        choice = rng.randrange(7)
        action = (
            "buy",
            "buy",
            "sell",
            "sell",
            "sweep",
            "rescue_fees",
            "model_buyback_toggle",
        )[choice]
        action_counts[action] += 1
        try:
            if action == "buy":
                headroom = ceiling - state.completion()
                profile_scaled = rng.choice((1, 2, 3, quote_unit, 2 * quote_unit))
                boundary_probe = max(1, headroom - rng.choice((1, 2, quote_unit)))
                gross = rng.choice((profile_scaled, boundary_probe))
                candidate, _, _ = state.buy(gross)
            elif action == "sell":
                token_unit = 10**18
                quantity = rng.choice((
                    1,
                    2,
                    token_unit,
                    max(1, state.user_tokens // 2),
                    state.user_tokens,
                ))
                candidate, _ = state.sell(quantity)
            elif action == "sweep":
                candidate = state.sweep(min_buyback_tokens_out=1)
            elif action == "rescue_fees":
                candidate = state.rescue_fees()
            else:
                candidate = replace(state, buyback_enabled=not state.buyback_enabled)
            candidate = admit_transition(candidate, ceiling)
        except CompletionCeilingRejected:
            ceiling_rejected += 1
        except (TradeRejected, OverflowError, ValueError):
            invalid += 1
        else:
            state = candidate
            accepted += 1
            assert state.completion() <= ceiling
            assert state.completion() >= lower_bound
            assert state.reserve_product >= initial_product
            if state.sellable_tokens:
                exact = completion_terminal_quote(CurveCompletionState(
                    phantom_quote=state.phantom_quote,
                    tracked_quote=state.tracked_quote,
                    quote_fee_balance=state.quote_fee_balance,
                    creator_tax_balance=state.creator_tax_balance,
                    tracked_tokens=state.tracked_tokens,
                    reserved_tokens=state.reserved_tokens,
                    curve_fee_bps=state.fee_bps,
                    creator_tax_bps=state.tax_bps,
                ))
                assert exact.gross_quote_in > 0
                assert exact.terminal_real_quote == state.completion()
            else:
                assert state.completion() == state.real_quote

    return {
        "profile": name,
        "quote_decimals": decimals,
        "launch_supply_raw": whole_supply * 10**18,
        "phantom_quote_raw": phantom,
        "graduation_threshold_raw": threshold,
        "curve_fee_bps": fee_bps,
        "creator_tax_bps": tax_bps,
        "initial_buyback_enabled": buyback,
        "ceiling_policy": "max(threshold, fresh completion) + max(one quote unit, that base // 100); illustrative research ceiling",
        "ceiling_raw": ceiling,
        "seed": seed,
        "prelude": prelude,
        "random_attempts": EXPANDED_RANDOM_STEPS_PER_HISTORY,
        "accepted_total": accepted,
        "ceiling_rejected": ceiling_rejected,
        "invalid_calls": invalid,
        "action_attempts": action_counts,
        "final_immediate_terminal_quote_raw": state.completion(),
        "final_sellable_tokens_raw": state.sellable_tokens,
    }


def run_campaign() -> dict:
    rows = [
        _run_expanded_history(profile, decimals, seed)
        for profile in EXPANDED_PROFILES
        for decimals in (18, 6)
        for seed in SEEDS
    ]
    return {
        "schema_version": 2,
        "classification": "BOUNDED_MULTI_PROFILE_MODEL_CAMPAIGN_NOT_PRODUCTION_GUARD_PROOF",
        "domain": (
            "single aggregate holder; exact-transfer quote; exact current buy/sell/sweep/fee-rescue integer model; "
            "native-like 18 and Circle-like 6 decimals; eight isolated launch/economic profiles"
        ),
        "limitations": [
            "ERC20/native transfer, authorization, external hook, and custody behavior are abstracted",
            "buyback enable/disable is a reduced-model field toggle, not a production Curve transaction",
            "ceilings are illustrative research bounds, not accepted Kuru or Launchpad policy",
            "random histories do not establish exhaustive or symbolic all-configuration coverage",
        ],
        "profiles": [
            {
                "name": name,
                "launch_supply_whole": supply,
                "phantom_quote_whole": phantom,
                "graduation_threshold_whole": threshold,
                "curve_fee_bps": fee,
                "creator_tax_bps": tax,
                "initial_buyback_enabled": buyback,
            }
            for name, supply, phantom, threshold, fee, tax, buyback in EXPANDED_PROFILES
        ],
        "seeds": list(SEEDS),
        "random_steps_per_history": EXPANDED_RANDOM_STEPS_PER_HISTORY,
        "rows": rows,
        "totals": {
            "histories": len(rows),
            "accepted": sum(row["accepted_total"] + row["prelude"]["accepted"] for row in rows),
            "ceiling_rejected": sum(
                row["ceiling_rejected"] + row["prelude"]["ceiling_rejected"] for row in rows
            ),
            "invalid_calls": sum(
                row["invalid_calls"] + row["prelude"]["invalid_calls"] for row in rows
            ),
        },
    }


if __name__ == "__main__":
    print(json.dumps(run_campaign(), indent=2))

"""Reproducible bounded stateful campaign for the proposed generic guard."""

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


def run_campaign() -> dict:
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


if __name__ == "__main__":
    print(json.dumps(run_campaign(), indent=2))

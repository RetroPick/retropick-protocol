"""Machine-readable minimal pump and proposed generic ceiling witness."""

import json

from completion_terminal_quote import CurveCompletionState, completion_terminal_quote
from launchpad_seed_model import round_trip_crossing_quote


def build_witness() -> dict:
    rows = []
    for quote, decimals in (("MON", 18), ("CIRCLE_TEST_USDC", 6)):
        phantom = 100 * 10**decimals
        supply = 1_000_000 * 10**18
        ceiling = phantom + 10  # Research-only illustrative cap, not policy.
        cases = []
        for rounds in (0, 1, 4, 5, 16, 1000):
            if rounds:
                path = round_trip_crossing_quote(
                    launch_supply=supply, phantom_quote=phantom,
                    graduation_threshold=phantom,
                    curve_fee_bps=100, creator_tax_bps=50,
                    rounds=rounds, round_trip_gross_quote=2,
                )
                assert path.real_quote_before_crossing == rounds
            state = CurveCompletionState(
                phantom_quote=phantom, tracked_quote=rounds,
                quote_fee_balance=0, creator_tax_balance=0,
                tracked_tokens=supply, reserved_tokens=supply // 2,
                curve_fee_bps=100, creator_tax_bps=50,
            )
            completion = completion_terminal_quote(state)
            cases.append({
                "completed_round_trips": rounds,
                "real_quote_raw": rounds,
                "immediate_terminal_quote_raw": completion.terminal_real_quote,
                "within_research_ceiling": completion.terminal_real_quote <= ceiling,
            })
        rows.append({
            "quote": quote,
            "quote_decimals": decimals,
            "configured_threshold_raw": phantom,
            "research_only_ceiling_raw": ceiling,
            "minimum_positive_round_trip_buy_raw": 2,
            "round_trip_sell_payout_raw": 1,
            "delta_real_quote_per_verified_cycle_raw": 1,
            "one_raw_buy_sell_payout": "REVERT_ZERO_GROSS_OUTPUT",
            "cases": cases,
        })
    return {
        "schema_version": 1,
        "classification": "BOUNDED_REPEATABLE_PUMP_AND_RESEARCH_CEILING_WITNESS",
        "source": "Current RetroPickBondingCurveV2 exact arithmetic; no production ceiling guard exists",
        "rows": rows,
    }


if __name__ == "__main__":
    print(json.dumps(build_witness(), indent=2))

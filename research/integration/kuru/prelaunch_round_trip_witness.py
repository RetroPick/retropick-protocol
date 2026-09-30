"""Emit a bounded real-curve history witness against threshold-only admission."""

import json
from dataclasses import asdict

from launchpad_seed_model import one_shot_crossing_quote, round_trip_crossing_quote


def build_witness() -> dict:
    rows = []
    for quote, decimals in (("MON", 18), ("CIRCLE_TEST_USDC", 6)):
        threshold = 100 * 10**decimals
        args = dict(
            launch_supply=1_000_000 * 10**18,
            phantom_quote=threshold,
            graduation_threshold=threshold,
            curve_fee_bps=100,
            creator_tax_bps=50,
        )
        one_shot = one_shot_crossing_quote(**args)
        ten_rounds = round_trip_crossing_quote(
            **args, rounds=10, round_trip_gross_quote=10,
        )
        terminal = one_shot.terminal_tokens
        rows.append({
            "quote": quote,
            "quote_decimals": decimals,
            "configured_threshold_raw": threshold,
            "one_shot_secured_quote_raw": one_shot.secured_quote,
            "round_trip_path": asdict(ten_rounds),
            "one_shot_base_seed_raw": terminal * one_shot.secured_quote // (threshold + one_shot.secured_quote),
            "round_trip_base_seed_raw": terminal * ten_rounds.secured_quote // (threshold + ten_rounds.secured_quote),
        })
    return {
        "schema_version": 1,
        "classification": "BOUNDED_PATH_COUNTEREXAMPLE_NOT_REACHABLE_RANGE_PROOF",
        "path_assumptions": "ten buy(10 raw quote)/sell(exact purchased tokens) cycles, then one clamped crossing buy; no buyback or earlier fee sweep",
        "rows": rows,
    }


if __name__ == "__main__":
    print(json.dumps(build_witness(), indent=2))

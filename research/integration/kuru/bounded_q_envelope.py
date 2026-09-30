"""Illustrative all-raw-Q interval matrix; not an accepted P0 ceiling."""

import json

from benchmark_launch_profiles import PROFILE_INPUTS
from completion_terminal_quote import CurveCompletionState, completion_terminal_quote
from terminal_q_interval import check_terminal_q_interval


def build_matrix() -> dict:
    rows = []
    for quote, decimals in (("MON", 18), ("CIRCLE_TEST_USDC", 6)):
        scale = 10**decimals
        for name, supply_units, phantom_units, threshold_units in PROFILE_INPUTS:
            supply = supply_units * 10**18
            phantom = phantom_units * scale
            threshold = threshold_units * scale
            terminal = supply * phantom // (phantom + threshold)
            if not 0 < terminal < supply:
                raise ValueError("profile has empty terminal allocation")
            initial = completion_terminal_quote(CurveCompletionState(
                phantom_quote=phantom, tracked_quote=0,
                quote_fee_balance=0, creator_tax_balance=0,
                tracked_tokens=supply, reserved_tokens=terminal,
                curve_fee_bps=100, creator_tax_bps=50,
            ))
            # Illustrative 10-raw-unit headroom above the exact initial
            # completion, not a recommended economic tolerance.
            ceiling = initial.terminal_real_quote + 10
            result = check_terminal_q_interval(
                launch_supply=supply, phantom_quote=phantom,
                graduation_threshold=threshold, quote_decimals=decimals,
                graduation_quote_ceiling=ceiling,
            )
            rows.append({
                "profile": name,
                "quote": quote,
                "initial_immediate_completion_q_raw": initial.terminal_real_quote,
                "proven_lower_q_raw": result["proven_lower_q_raw"],
                "illustrative_ceiling_q_raw": ceiling,
                "checked_raw_q_cells": result["checked_raw_q_cells"],
                "valid_cells": result["valid_cells"],
                "all_cells_valid_in_reduced_model": result["all_cells_valid_in_reduced_model"],
                "first_invalid_q_raw": (
                    None if result["first_invalid"] is None
                    else result["first_invalid"]["secured_quote_raw"]
                ),
                "first_invalid_constraints": (
                    [] if result["first_invalid"] is None
                    else [name for name, valid in
                          result["first_invalid"]["result"].get("constraints", {}).items()
                          if not valid]
                ),
                "monotone_fields_observed": result["monotone_fields_observed"],
                "worst_combined_error_bps_numerator": result["worst_combined_error_bps_numerator"],
                "worst_combined_error_bps_denominator": result["worst_combined_error_bps_denominator"],
            })
    return {
        "schema_version": 1,
        "classification": "ILLUSTRATIVE_BOUNDED_ALL_Q_REDUCED_MODEL_NOT_ACCEPTED_CEILING",
        "upper_policy": "initial immediate completion Q plus 10 raw quote units; no economic authority",
        "candidate_parameter_policy": "benchmark_launch_profiles.py fixed research tuple and five-bps combined error",
        "rows": rows,
    }


if __name__ == "__main__":
    print(json.dumps(build_matrix(), indent=2))

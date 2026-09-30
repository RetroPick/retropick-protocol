"""Wide-Q sufficient-bound research; 100x threshold is a stress input only."""

import json

from benchmark_launch_profiles import PROFILE_INPUTS
from completion_terminal_quote import terminal_quote_lower_bound
from terminal_q_interval import prove_interval_sufficient


def build_matrix() -> dict:
    rows = []
    for quote, decimals in (("MON", 18), ("CIRCLE_TEST_USDC", 6)):
        scale = 10**decimals
        for name, supply_units, phantom_units, threshold_units in PROFILE_INPUTS:
            supply = supply_units * 10**18
            phantom = phantom_units * scale
            threshold = threshold_units * scale
            terminal = supply * phantom // (phantom + threshold)
            lower = terminal_quote_lower_bound(
                initial_tokens=supply, phantom_quote=phantom,
                reserved_tokens=terminal,
            )
            upper = 100 * threshold
            proof = prove_interval_sufficient(
                terminal_tokens=terminal, phantom_quote=phantom,
                lower_q=lower, upper_q=upper, quote_decimals=decimals,
            )
            rows.append({
                "profile": name,
                "quote": quote,
                "lower_q_raw": lower,
                "stress_upper_q_raw": upper,
                "all_q_proven_in_reduced_model": proof["all_q_proven_in_reduced_model"],
                "failed_sufficient_checks": [
                    key for key, valid in proof["checks"].items() if not valid
                ],
                "combined_error_bound_bps_numerator": proof["combined_error_bound_bps_numerator"],
                "combined_error_bound_bps_denominator": proof["combined_error_bound_bps_denominator"],
            })
    return {
        "schema_version": 1,
        "classification": "WIDE_Q_SUFFICIENT_REDUCED_MODEL_PROOF_NOT_ACCEPTED_POLICY",
        "upper_input": "100 times configured threshold for stress only; not a recommended ceiling",
        "candidate_parameter_policy": "benchmark_launch_profiles.py fixed research tuple and five-bps combined error",
        "rows": rows,
    }


if __name__ == "__main__":
    print(json.dumps(build_matrix(), indent=2))

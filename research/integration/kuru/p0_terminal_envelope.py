"""Conservative technical terminal-Q envelope limits for candidate launches.

This generator does not accept a P0 ceiling. It finds the largest finite
upper raw-Q endpoint for which the existing conservative sufficient proof
still passes. That endpoint is a safe technical coverage limit, not the
maximum Q that exact arithmetic might admit.
"""

import json

from benchmark_launch_profiles import PROFILE_INPUTS
from completion_terminal_quote import (
    CurveCompletionState,
    completion_terminal_quote,
    terminal_quote_lower_bound,
)
from launchpad_seed_model import UINT256_MAX
from terminal_q_interval import check_terminal_q, prove_interval_sufficient


PRICE_SCALE = 10**18


def _sufficient_endpoint(terminal_tokens, phantom_quote, lower_q, upper_q,
                         quote_decimals):
    return prove_interval_sufficient(
        terminal_tokens=terminal_tokens,
        phantom_quote=phantom_quote,
        lower_q=lower_q,
        upper_q=upper_q,
        quote_decimals=quote_decimals,
    )["all_q_proven_in_reduced_model"]


def largest_sufficient_endpoint(*, terminal_tokens, phantom_quote, lower_q,
                                quote_decimals, initial_upper=None):
    """Return the last endpoint covered by the sufficient proof and its proof.

    The predicate is expected to be an interval of true values followed by
    false values under the checked arithmetic bounds. The routine deliberately
    also returns a failing successor when bounded, so reports can distinguish
    a mathematical hard cap from this generator's uint256 search cap.
    """
    if min(terminal_tokens, phantom_quote, lower_q) <= 0:
        return {
            "bounded": False,
            "upper_q_raw": lower_q,
            "failing_successor_q_raw": lower_q + 1,
            "reason": "positive terminal, phantom and lower-Q inputs required",
            "proof_at_upper": prove_interval_sufficient(
                terminal_tokens=terminal_tokens,
                phantom_quote=phantom_quote,
                lower_q=lower_q,
                upper_q=lower_q,
                quote_decimals=quote_decimals,
            ) if min(terminal_tokens, phantom_quote, lower_q) > 0 else {
                "all_q_proven_in_reduced_model": False,
                "classification": "INVALID_INPUT",
            },
        }

    if not _sufficient_endpoint(
        terminal_tokens, phantom_quote, lower_q, lower_q, quote_decimals,
    ):
        return {
            "bounded": False,
            "upper_q_raw": lower_q,
            "failing_successor_q_raw": lower_q,
            "reason": "lower endpoint already fails sufficient conditions",
            "proof_at_upper": prove_interval_sufficient(
                terminal_tokens=terminal_tokens,
                phantom_quote=phantom_quote,
                lower_q=lower_q,
                upper_q=lower_q,
                quote_decimals=quote_decimals,
            ),
        }

    # The checked first-ask numerator imposes the simplest universal raw-Q
    # search cap: upper * baseScale * priceScale <= uint256.max.
    search_cap = UINT256_MAX // (10**18 * PRICE_SCALE)
    search_cap = min(search_cap, UINT256_MAX - phantom_quote)
    true_endpoint = max(initial_upper or lower_q, lower_q)
    if true_endpoint > search_cap:
        raise ValueError("initial upper endpoint exceeds uint256 search cap")
    if not _sufficient_endpoint(
        terminal_tokens, phantom_quote, lower_q, true_endpoint, quote_decimals,
    ):
        raise ValueError("initial upper endpoint does not pass sufficient proof")

    if _sufficient_endpoint(
        terminal_tokens, phantom_quote, lower_q, search_cap, quote_decimals,
    ):
        return {
            "bounded": True,
            "upper_q_raw": search_cap,
            "failing_successor_q_raw": None,
            "reason": "sufficient proof reaches generator uint256 search cap",
            "proof_at_upper": prove_interval_sufficient(
                terminal_tokens=terminal_tokens,
                phantom_quote=phantom_quote,
                lower_q=lower_q,
                upper_q=search_cap,
                quote_decimals=quote_decimals,
            ),
        }

    false_endpoint = search_cap
    while false_endpoint > true_endpoint + 1:
        midpoint = (true_endpoint + false_endpoint) // 2
        if _sufficient_endpoint(
            terminal_tokens, phantom_quote, lower_q, midpoint, quote_decimals,
        ):
            true_endpoint = midpoint
        else:
            false_endpoint = midpoint

    return {
        "bounded": True,
        "upper_q_raw": true_endpoint,
        "failing_successor_q_raw": false_endpoint,
        "reason": "last sufficient endpoint before first binary-search failure",
        "proof_at_upper": prove_interval_sufficient(
            terminal_tokens=terminal_tokens,
            phantom_quote=phantom_quote,
            lower_q=lower_q,
            upper_q=true_endpoint,
            quote_decimals=quote_decimals,
        ),
    }


def build_matrix() -> dict:
    rows = []
    for quote, decimals in (("MON", 18), ("CIRCLE_TEST_USDC", 6)):
        scale = 10**decimals
        for name, supply_units, phantom_units, threshold_units in PROFILE_INPUTS:
            supply = supply_units * 10**18
            phantom = phantom_units * scale
            threshold = threshold_units * scale
            terminal = supply * phantom // (phantom + threshold)
            if terminal <= 0:
                rows.append({
                    "profile": name,
                    "quote": quote,
                    "quote_decimals": decimals,
                    "launch_supply_raw": supply,
                    "terminal_tokens_raw": terminal,
                    "phantom_quote_raw": phantom,
                    "graduation_threshold_raw": threshold,
                    "classification": "NOT_APPLICABLE_EMPTY_TERMINAL_ALLOCATION",
                    "reason": (
                        "floor division leaves no terminal tokens to seed; "
                        "the profile is outside the positive launch envelope"
                    ),
                })
                continue
            lower = terminal_quote_lower_bound(
                initial_tokens=supply,
                phantom_quote=phantom,
                reserved_tokens=terminal,
            )
            initial_upper = max(threshold, lower)
            initial_completion = completion_terminal_quote(CurveCompletionState(
                phantom_quote=phantom,
                tracked_quote=0,
                quote_fee_balance=0,
                creator_tax_balance=0,
                tracked_tokens=supply,
                reserved_tokens=terminal,
                curve_fee_bps=100,
                creator_tax_bps=50,
            ))
            envelope = largest_sufficient_endpoint(
                terminal_tokens=terminal,
                phantom_quote=phantom,
                lower_q=lower,
                quote_decimals=decimals,
                initial_upper=initial_upper,
            )
            upper = envelope["upper_q_raw"]
            endpoint_checks = {
                "fresh_immediate_completion": check_terminal_q(
                    terminal_tokens=terminal,
                    phantom_quote=phantom,
                    secured_quote=initial_completion.terminal_real_quote,
                    quote_decimals=decimals,
                ),
                "configured_threshold": check_terminal_q(
                    terminal_tokens=terminal,
                    phantom_quote=phantom,
                    secured_quote=threshold,
                    quote_decimals=decimals,
                ) if threshold <= upper else None,
                "sufficient_upper": check_terminal_q(
                    terminal_tokens=terminal,
                    phantom_quote=phantom,
                    secured_quote=upper,
                    quote_decimals=decimals,
                ),
            }
            sufficient_at_upper = envelope["proof_at_upper"][
                "all_q_proven_in_reduced_model"
            ]
            row = {
                "profile": name,
                "quote": quote,
                "quote_decimals": decimals,
                "launch_supply_raw": supply,
                "terminal_tokens_raw": terminal,
                "phantom_quote_raw": phantom,
                "graduation_threshold_raw": threshold,
                "proven_lower_q_raw": lower,
                "fresh_immediate_completion_q_raw": (
                    initial_completion.terminal_real_quote
                ),
                "sufficient_endpoint": envelope,
                "endpoint_exact_checks": endpoint_checks,
                "initial_completion_within_envelope": bool(
                    lower <= initial_completion.terminal_real_quote <= upper
                ),
                "threshold_within_envelope": bool(threshold <= upper),
                "stress_100x_threshold_within_envelope": bool(
                    100 * threshold <= upper
                ),
                "sufficient_at_reported_upper": sufficient_at_upper,
            }
            rows.append(row)

    return {
        "schema_version": 1,
        "classification": (
            "CONSERVATIVE_SUFFICIENT_ENDPOINT_MATRIX_NOT_ACCEPTED_P0_POLICY"
        ),
        "policy_warning": (
            "These are upper coverage limits for the existing conservative "
            "reduced-model proof, not economic graduation ceilings and not "
            "real-fork qualification"
        ),
        "candidate_parameter_policy": (
            "benchmark_launch_profiles.py fixed research tuple and five-bps "
            "combined error"
        ),
        "rows": rows,
    }


if __name__ == "__main__":
    print(json.dumps(build_matrix(), indent=2))

"""Exact reduced-model admissibility over declared continuous Q intervals.

This module does not discover the mathematical maximum admissible Q and does
not accept a Kuru or economic policy.  For a caller-declared inclusive raw-Q
interval, it proves that every integer Q in that interval passes the exact
pinned reduced-model predicate.  It uses the existing uniform residual bound,
which is exact enough for the declared profile domains but can be
conservatively inconclusive elsewhere.
"""

from dataclasses import dataclass
import json

from benchmark_launch_profiles import PROFILE_INPUTS
from completion_terminal_quote import terminal_quote_lower_bound
from terminal_q_interval import check_terminal_q, prove_interval_sufficient


DECLARED_MULTIPLIER = 50
DECLARED_MULTIPLIER_REQUIREMENT = (
    "The owner may accept a smaller multiplier, but the accepted generic "
    "graduationQuoteCeiling must not exceed this technically proven domain "
    "without new exact interval evidence."
)


@dataclass(frozen=True)
class ExactAdmissibility:
    """A declared-domain result; never an accepted economic ceiling."""

    profile: str
    quote: str
    quote_decimals: int
    terminal_tokens_raw: int
    phantom_quote_raw: int
    lower_q_raw: int
    upper_q_raw: int
    all_q_admissible: bool
    endpoint_checks: dict


def prove_declared_interval(
    *, terminal_tokens: int, phantom_quote: int, lower_q: int, upper_q: int,
    quote_decimals: int, candidate_error_cap_bps: int = 5,
) -> dict:
    """Prove every raw Q in an inclusive interval is exactly admissible."""
    uniform = prove_interval_sufficient(
        terminal_tokens=terminal_tokens, phantom_quote=phantom_quote,
        lower_q=lower_q, upper_q=upper_q, quote_decimals=quote_decimals,
        candidate_error_cap_bps=candidate_error_cap_bps,
    )
    endpoints = {
        name: check_terminal_q(
            terminal_tokens=terminal_tokens, phantom_quote=phantom_quote,
            secured_quote=q, quote_decimals=quote_decimals,
            candidate_error_cap_bps=candidate_error_cap_bps,
        )
        for name, q in (("lower", lower_q), ("upper", upper_q))
    }
    all_q_admissible = bool(
        uniform["all_q_proven_in_reduced_model"]
        and all(result["valid"] for result in endpoints.values())
    )
    return {
        "all_q_admissible": all_q_admissible,
        "classification": (
            "EXACT_ALL_INTEGER_Q_PROOF_WITHIN_DECLARED_REDUCED_MODEL_DOMAIN"
            if all_q_admissible else
            "DECLARED_DOMAIN_NOT_PROVEN_BY_CONSERVATIVE_INTERVAL_BOUND"
        ),
        "domain_semantics": (
            "every inclusive integer raw Q from lower_q through upper_q"
        ),
        "proof_method": (
            "uniform bounds for non-monotone seed/tick residuals plus "
            "monotone bounds for B, order size, LP, width and tick limits"
        ),
        "uniform_interval_proof": uniform,
        "exact_endpoint_checks": endpoints,
    }


def build_declared_p0_matrix() -> dict:
    """Prove the proposed 50x-threshold technical domain, not its economics."""
    rows = []
    for quote, quote_decimals in (("MON", 18), ("CIRCLE_CANONICAL_TEST_USDC", 6)):
        scale = 10**quote_decimals
        for name, supply_units, phantom_units, threshold_units in PROFILE_INPUTS:
            launch_supply = supply_units * 10**18
            phantom = phantom_units * scale
            threshold = threshold_units * scale
            terminal = launch_supply * phantom // (phantom + threshold)
            if terminal <= 0:
                rows.append({
                    "profile": name,
                    "quote": quote,
                    "classification": "NOT_APPLICABLE_EMPTY_TERMINAL_ALLOCATION",
                })
                continue
            lower = terminal_quote_lower_bound(
                initial_tokens=launch_supply, phantom_quote=phantom,
                reserved_tokens=terminal,
            )
            upper = DECLARED_MULTIPLIER * threshold
            proof = prove_declared_interval(
                terminal_tokens=terminal, phantom_quote=phantom,
                lower_q=lower, upper_q=upper,
                quote_decimals=quote_decimals,
            )
            if name == "FACTORY_MINIMUM_NEGATIVE":
                # Preserve this contradiction even when a wider generic domain
                # is technically admissible: the factory profile remains out
                # of the launch envelope under the candidate minimum-size rule.
                all_q_admissible = False
                classification = (
                    "PERMANENT_NEGATIVE_PROFILE_NOT_IN_P0_LAUNCH_ENVELOPE"
                )
                proof["classification"] = classification
                proof["all_q_admissible"] = False
            else:
                all_q_admissible = proof["all_q_admissible"]
                classification = proof["classification"]
            rows.append({
                "profile": name,
                "quote": quote,
                "quote_decimals": quote_decimals,
                "launch_supply_raw": launch_supply,
                "terminal_tokens_raw": terminal,
                "phantom_quote_raw": phantom,
                "graduation_threshold_raw": threshold,
                "declared_lower_q_raw": lower,
                "declared_upper_q_raw": upper,
                "declared_domain_multiplier": DECLARED_MULTIPLIER,
                "all_q_admissible": all_q_admissible,
                "classification": classification,
                "proof": proof,
            })
    return {
        "schema_version": 1,
        "classification": (
            "EXACT_REDUCED_MODEL_DOMAIN_QUALIFICATION_NOT_FORK_OR_POLICY"
        ),
        "declared_domain": (
            "inclusive integer terminal Q from the exact immediate-completion "
            "lower bound through 50x the configured graduation threshold"
        ),
        "candidate_parameter_policy": (
            "benchmark_launch_profiles.py fixed research tuple and five-bps "
            "combined seed/tick error cap; the six-decimal rows model "
            "canonical chain-10143 Circle test USDC"
        ),
        "economic_warning": (
            "This is not an accepted graduationQuoteCeiling, not a maximum "
            "admissible-Q search, and not real Router/vault qualification"
        ),
        "rows": rows,
    }


if __name__ == "__main__":
    print(json.dumps(build_declared_p0_matrix(), indent=2))

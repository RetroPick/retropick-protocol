"""Emit a narrow, exact counterexample to assuming terminal Q equals threshold.

The current Curve's one-shot threshold crossing is mirrored exactly here.
This witness does not bound Q over all possible trading histories.
"""

import json
from dataclasses import asdict

from launchpad_seed_model import one_shot_crossing_quote


def build_witness() -> dict:
    rows = []
    for quote, decimals in (("MON", 18), ("CIRCLE_TEST_USDC", 6)):
        phantom = 100 * 10**decimals
        crossing = one_shot_crossing_quote(
            launch_supply=1_000_000 * 10**18,
            phantom_quote=phantom,
            graduation_threshold=phantom,
            curve_fee_bps=100,
            creator_tax_bps=50,
        )
        t = crossing.terminal_tokens
        q = crossing.secured_quote
        b_if_threshold = t * phantom // (phantom + phantom)
        b_actual = t * q // (phantom + q)
        rows.append({
            "quote": quote,
            "quote_decimals": decimals,
            "launch_supply_raw": 1_000_000 * 10**18,
            "phantom_quote_raw": phantom,
            "configured_threshold_raw": phantom,
            "curve_fee_bps": 100,
            "creator_tax_bps": 50,
            "one_shot_crossing": asdict(crossing),
            "secured_quote_minus_threshold_raw": q - phantom,
            "base_seed_if_q_equals_threshold_raw": b_if_threshold,
            "base_seed_from_measured_q_raw": b_actual,
            "base_seed_delta_raw": b_actual - b_if_threshold,
        })
    return {
        "schema_version": 1,
        "classification": "COUNTEREXAMPLE_TO_Q_EQUALS_THRESHOLD_NOT_TERMINAL_Q_RANGE_PROOF",
        "source": "RetroPickBondingCurveV2.initialize/buy/graduate and BondingCurveMathV2.getAmountIn",
        "path_assumptions": "one threshold-crossing buy, no prior trades, buyback disabled",
        "rows": rows,
    }


if __name__ == "__main__":
    print(json.dumps(build_witness(), indent=2))

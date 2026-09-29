"""Generate the exact replication and lot evidence fixture for PRISM P0."""
from __future__ import annotations

import hashlib
import json
import sys
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "models"))
from prism_p0 import ComponentIdentity, derive_lot_size, exact_component_amount, exact_replication_certificate


ROOT = Path(__file__).resolve().parents[3]
COMPONENTS = (
    ComponentIdentity(
        "PredictionMarketP0:market-A:YES",
        "PredictionMarketP0:market-A",
        0,
        "HackathonCollateralP0:stable",
        6,
        "0x70726564696374696f6e2d70302d737065632d686173682d30303030303030",
    ),
    ComponentIdentity(
        "PredictionMarketP0:market-A:NO",
        "PredictionMarketP0:market-A",
        1,
        "HackathonCollateralP0:stable",
        6,
        "0x70726564696374696f6e2d70302d737065632d686173682d30303030303030",
    ),
)
WEIGHTS = (Fraction(1, 2), Fraction(1, 2))
MATRIX = ((1, 0), (0, 1))
TARGET = (Fraction(1, 2), Fraction(1, 2))
MINT_AMOUNT = 10_000_000


def main() -> None:
    lot = derive_lot_size(WEIGHTS)
    certificate = exact_replication_certificate(MATRIX, TARGET, WEIGHTS, COMPONENTS)
    payload = {
        "schema_version": 1,
        "profile": "HACKATHON-P0",
        "artifact": "PRISM-H1/H2 exact replication and exact lot fixture",
        "arithmetic": "exact rational and integer only",
        "component_decimals": 6,
        "weights": [str(value) for value in WEIGHTS],
        "lot_size_raw": lot,
        "lot_derivation": {
            "reduced_denominators": [value.denominator for value in WEIGHTS],
            "formula": "lcm(reduced denominators)",
            "proof": "For q=k*L where L is the denominator lcm, q*n_i/d_i=k*(L/d_i)*n_i is integral for every i.",
        },
        "sample_mint": {
            "prism_amount_raw": MINT_AMOUNT,
            "component_amounts_raw": [exact_component_amount(MINT_AMOUNT, value, lot) for value in WEIGHTS],
            "valid_lot_multiple": MINT_AMOUNT % lot == 0,
        },
        "replication": certificate,
        "excluded": ["floor", "ceil", "cash settlement", "rounding cursor", "shared prefunding"],
    }
    canonical = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()
    payload["sha256"] = hashlib.sha256(canonical).hexdigest()
    output = ROOT / "research/hackathon-p0/fixtures/prism_p0_exact_lot.json"
    output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    print(output.relative_to(ROOT))
    print(payload["sha256"])


if __name__ == "__main__":
    main()

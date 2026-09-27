import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from invalid_floor_compositions import discharge_invalid_floor_compositions


EVIDENCE = Path(__file__).resolve().parents[3] / "evidence" / "research" / "prediction" / "invalid-floor-compositions-2026-09-26.json"


class InvalidFloorCompositionTests(unittest.TestCase):
    def test_cumulative_floor_telescopes_on_supply_compositions(self):
        report = discharge_invalid_floor_compositions()
        prior: dict[str, object] = {}
        if EVIDENCE.exists():
            loaded = json.loads(EVIDENCE.read_text())
            if isinstance(loaded, dict) and "solidity_execution" in loaded:
                prior["solidity_execution"] = loaded["solidity_execution"]
        if prior:
            report["solidity_execution"] = prior["solidity_execution"]
        EVIDENCE.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        self.assertEqual(report["supply_max"], 16)
        self.assertEqual(report["cumulative_floor"]["classification"], "EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN")
        self.assertIsNone(report["cumulative_floor"]["counterexample"])
        self.assertEqual(report["cumulative_floor"]["failure_count"], 0)
        self.assertEqual(report["per_call_floor"]["classification"], "COUNTEREXAMPLE_FOUND")
        witness = report["per_call_floor"]["smallest_witness"]
        self.assertEqual(witness["supply"], 2)
        self.assertEqual(witness["parts"], [1, 1])
        self.assertEqual(witness["one_shot"], 1)
        self.assertEqual(witness["cumulative_paid"], 1)
        self.assertEqual(witness["per_call_paid"], 0)
        self.assertEqual(witness["gap"], 1)
        self.assertEqual(report["per_call_floor"]["fragmentation_gap_supply_5"], 2)
        self.assertEqual(report["half_up"]["classification"], "COUNTEREXAMPLE_FOUND")
        self.assertEqual(report["half_up"]["both_sides_payment"], 2)
        self.assertEqual(report["pred_math_1"], "partial")
        self.assertEqual(report["canonical_math1"], "FAIL")
        self.assertFalse(report["formula_changed"])
        self.assertGreater(report["states"], 0)
        self.assertGreater(report["transitions"], 0)
        self.assertGreater(report["per_call_floor"]["gap_rows"], 0)


if __name__ == "__main__":
    unittest.main()

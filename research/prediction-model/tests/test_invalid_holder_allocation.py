"""Preserve the difference between aggregate conservation and holder entitlement."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from domain import Outcome, ResolutionResult  # noqa: E402
from market import activate_binary, create_market  # noqa: E402


class InvalidHolderAllocationTests(unittest.TestCase):
    def test_alternating_unit_redemptions_give_all_value_to_second_holder(self) -> None:
        units_per_holder = 10
        market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
        activate_binary(market, market_id="invalid-holder", resolver="resolver", spec_hash="hash")
        market.split("alice", units_per_holder, units_per_holder)
        market.split("bob", units_per_holder, units_per_holder)
        market.close_mint()
        market.begin_resolution()
        market.resolve("resolver", ResolutionResult.INVALID)
        market.open_redemption()

        paid = {"alice": 0, "bob": 0}
        for side in (Outcome.YES, Outcome.NO):
            for _ in range(units_per_holder):
                paid["alice"] += market.redeem("alice", side, 1)
                paid["bob"] += market.redeem("bob", side, 1)

        self.assertEqual(paid, {"alice": 0, "bob": 20})
        self.assertEqual(market.liability(), 0)
        self.assertEqual(market.collateral_locked, 0)
        self.assertEqual(market.yes_supply, 0)
        self.assertEqual(market.no_supply, 0)


if __name__ == "__main__":
    unittest.main()

"""Keep the Python/Solidity winner-liability boundary visible."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from domain import MarketState, ResolutionResult  # noqa: E402
from market import activate_binary, create_market  # noqa: E402


class WinnerLiabilityBoundaryTests(unittest.TestCase):
    def test_python_accepts_the_first_solidity_overflowing_supply(self) -> None:
        supply = 1 << 255
        for result in (ResolutionResult.YES_WIN, ResolutionResult.NO_WIN):
            with self.subTest(result=result):
                market = create_market(integer=True, collateral="COLL", dust_sink="SINK")
                activate_binary(market, market_id="winner-boundary", resolver="resolver", spec_hash="hash")
                market.split("alice", supply, supply)
                market.close_mint()
                market.begin_resolution()
                market.resolve("resolver", result)
                self.assertEqual(market.liability(), supply)
                market.open_redemption()
                self.assertEqual(market.state, MarketState.REDEEMABLE)
                self.assertEqual(market.collateral_locked, supply)


if __name__ == "__main__":
    unittest.main()

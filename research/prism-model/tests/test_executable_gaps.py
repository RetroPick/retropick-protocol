import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import random
import unittest
from fractions import Fraction

from adversarial import run_fixed_point_stress, run_reservation_stress
from fixed_point import WAD
from fixed_point_model import (
    FixedPointModelError,
    FixedPointSeries,
    FixedPointSettlement,
    normalize_raw,
    required_component_raw,
    required_settlement_raw,
)
from lifecycle import SeriesState
from model import ModelError, PrismSeries
from native_market import BinaryCompleteSetMarket, NativeMarketError, NativeMarketState
from reservation_ledger import ReservationError, ReservationLedger


G = [
    [0, 1],
    [0, 0],
    [1, 1],
    [1, 0],
]
WEIGHTS = [Fraction(3, 5), Fraction(2, 5)]


class ReservationLedgerTests(unittest.TestCase):
    def test_cross_series_double_allocation_is_rejected(self):
        ledger = ReservationLedger()
        ledger.deposit("FED_YES", 100)
        ledger.reserve("SERIES_A", {"FED_YES": 60})
        with self.assertRaises(ReservationError):
            ledger.reserve("SERIES_B", {"FED_YES": 50})
        ledger.reserve("SERIES_B", {"FED_YES": 40})
        self.assertEqual(ledger.total_reserved("FED_YES"), 100)
        self.assertEqual(ledger.available("FED_YES"), 0)
        self.assertTrue(ledger.assert_globally_backed())

    def test_reserved_units_cannot_be_withdrawn(self):
        ledger = ReservationLedger()
        ledger.deposit("BTC_NO", 10)
        ledger.reserve("A", {"BTC_NO": 8})
        with self.assertRaises(ReservationError):
            ledger.withdraw("BTC_NO", 3)
        ledger.withdraw("BTC_NO", 2)
        self.assertEqual(ledger.balance("BTC_NO"), 8)
        self.assertEqual(ledger.total_reserved("BTC_NO"), 8)

    def test_release_restores_available_capacity(self):
        ledger = ReservationLedger()
        ledger.deposit("ASSET", 10)
        ledger.reserve("A", {"ASSET": 7})
        ledger.release("A", {"ASSET": 2})
        self.assertEqual(ledger.available("ASSET"), 5)
        ledger.reserve("B", {"ASSET": 5})
        self.assertEqual(ledger.total_reserved("ASSET"), 10)


class NativeCompleteSetTests(unittest.TestCase):
    def test_split_merge_conservation(self):
        market = BinaryCompleteSetMarket()
        market.split(100)
        self.assertEqual(market.open_interest(), 100)
        market.merge(25)
        self.assertEqual(market.yes_supply, 75)
        self.assertEqual(market.no_supply, 75)
        self.assertEqual(market.collateral_locked, 75)
        self.assertTrue(market.assert_invariants())

    def test_resolution_and_both_claim_redemptions(self):
        market = BinaryCompleteSetMarket()
        market.split(100)
        market.resolve("YES")
        self.assertEqual(market.state, NativeMarketState.RESOLVED)
        self.assertEqual(market.redeem("NO", 40), 0)
        self.assertEqual(market.collateral_locked, 100)
        self.assertEqual(market.redeem("YES", 60), 60)
        self.assertEqual(market.collateral_locked, 40)
        self.assertEqual(market.yes_supply, 40)
        self.assertTrue(market.assert_invariants())

    def test_archive_requires_all_claims_burned_or_redeemed(self):
        market = BinaryCompleteSetMarket()
        market.split(3)
        market.resolve("NO")
        market.redeem("NO", 3)
        with self.assertRaises(NativeMarketError):
            market.archive()
        market.redeem("YES", 3)
        market.archive()
        self.assertEqual(market.state, NativeMarketState.ARCHIVED)


class PartialResolutionTests(unittest.TestCase):
    def make_series(self):
        s = PrismSeries(G, WEIGHTS)
        s.activate()
        s.mint_with_exact_backing(1000)
        return s

    def test_resolved_component_transforms_to_cash_and_conditions_worlds(self):
        s = self.make_series()
        cash = s.resolve_component(1, 1)
        self.assertEqual(s.state, SeriesState.MINT_PAUSED)
        self.assertEqual(cash, 400)
        self.assertEqual(s.backing[1], 0)
        self.assertEqual(s.transformed_settlement, 400)
        self.assertEqual(s.possible_states, {0, 2})
        self.assertTrue(s.assert_component_backed())
        self.assertTrue(all(ok for _, _, _, ok in s.terminal_solvency()))

    def test_partial_resolution_blocks_new_mint(self):
        s = self.make_series()
        s.resolve_component(0, 1)
        with self.assertRaises(ModelError):
            s.mint_with_exact_backing(1)

    def test_mixed_redemption_preserves_backing(self):
        s = self.make_series()
        s.resolve_component(1, 1)
        out = s.redeem_in_kind_mixed(100)
        self.assertEqual(out["components"], (Fraction(60), Fraction(0)))
        self.assertEqual(out["settlement"], 40)
        self.assertEqual(s.supply, 900)
        self.assertEqual(s.backing[0], 540)
        self.assertEqual(s.transformed_settlement, 360)
        self.assertTrue(s.assert_component_backed())
        self.assertTrue(all(ok for _, _, _, ok in s.terminal_solvency()))

    def test_inconsistent_component_resolution_rejected(self):
        s = self.make_series()
        s.resolve_component(0, 1)
        with self.assertRaises(ModelError):
            s.resolve_component(0, 0)

    def test_final_state_must_match_conditioned_state_space(self):
        s = self.make_series()
        s.resolve_component(1, 1)
        s.start_resolution()
        with self.assertRaises(ModelError):
            s.resolve(3)
        s.resolve(2)
        self.assertEqual(s.final_payout, 1)


class FixedPointTransferTests(unittest.TestCase):
    def make_series(self):
        return FixedPointSeries(
            weights_wad=[6 * 10**17, 4 * 10**17],
            component_decimals=[18, 6],
        )

    def test_decimal_normalization_is_conservative(self):
        raw = required_component_raw(WAD, 4 * 10**17, 6)
        self.assertEqual(raw, 400_000)
        self.assertEqual(normalize_raw(raw, 6), 4 * 10**17)

    def test_integer_mint_and_redeem_preserve_backing(self):
        s = self.make_series()
        s.mint_with_minimum_backing(WAD)
        self.assertTrue(s.assert_backed())
        released = s.redeem(WAD // 3)
        self.assertTrue(all(v >= 0 for v in released))
        self.assertTrue(s.assert_backed())
        s.redeem(s.supply_units)
        self.assertEqual(s.supply_units, 0)
        dust = s.sweep_dust()
        self.assertTrue(all(v >= 0 for v in dust))
        self.assertEqual(s.backing_raw, [0, 0])

    def test_binary_terminal_solvency_all_states(self):
        for q in [1, 7, 10**9, WAD, 3 * WAD + 7]:
            s = self.make_series()
            s.mint_with_minimum_backing(q)
            for bits in [(0, 1), (0, 0), (1, 1), (1, 0)]:
                backing, liability, ok = s.terminal_solvency_binary(bits)
                self.assertTrue(ok, (q, bits, backing, liability))

    def test_randomized_mint_redeem_sequences_never_underback(self):
        rng = random.Random(20260917)
        s = self.make_series()
        for _ in range(500):
            if s.supply_units == 0 or rng.random() < 0.6:
                q = rng.randint(1, 10**12)
                s.mint_with_minimum_backing(q)
            else:
                q = rng.randint(1, min(s.supply_units, 10**12))
                s.redeem(q)
            self.assertTrue(s.assert_backed())
            for bits in [(0, 1), (0, 0), (1, 1), (1, 0)]:
                self.assertTrue(s.terminal_solvency_binary(bits)[2])

    def test_dust_cannot_be_swept_with_live_liability(self):
        s = self.make_series()
        s.mint_with_minimum_backing(1)
        with self.assertRaises(FixedPointModelError):
            s.sweep_dust()


class FixedPointSettlementTransferTests(unittest.TestCase):
    def test_settlement_rounding_preserves_remaining_funding(self):
        supply = 3 * WAD + 7
        settlement = FixedPointSettlement(
            supply_units=supply,
            payout_wad=6 * 10**17,
            settlement_decimals=6,
        )
        required = settlement.required_balance_raw()
        self.assertEqual(required, required_settlement_raw(supply, 6 * 10**17, 6))
        settlement.fund(required)
        settlement.make_redeemable()
        payout1 = settlement.redeem(WAD + 3)
        self.assertGreaterEqual(payout1, 0)
        self.assertGreaterEqual(settlement.balance_raw, settlement.required_balance_raw())
        payout2 = settlement.redeem(settlement.supply_units)
        self.assertGreaterEqual(payout2, 0)
        self.assertEqual(settlement.supply_units, 0)
        self.assertGreaterEqual(settlement.sweepable_dust(), 0)

    def test_underfunded_fixed_point_settlement_rejected(self):
        settlement = FixedPointSettlement(
            supply_units=WAD,
            payout_wad=6 * 10**17,
            settlement_decimals=6,
        )
        settlement.fund(599_999)
        with self.assertRaises(FixedPointModelError):
            settlement.make_redeemable()


class AdversarialHarnessTests(unittest.TestCase):
    def test_fixed_point_stress_runner(self):
        report = run_fixed_point_stress(seed=7, steps=250)
        self.assertEqual(report["steps"], 250)
        self.assertEqual(report["terminal_checks"], 1000)

    def test_reservation_stress_runner(self):
        report = run_reservation_stress(seed=7, steps=250)
        self.assertEqual(report["steps"], 250)
        self.assertLessEqual(report["total_reserved"], report["balance"])


if __name__ == "__main__":
    unittest.main()

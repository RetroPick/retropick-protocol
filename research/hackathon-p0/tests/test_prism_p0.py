from fractions import Fraction
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "models"))

from prism_p0 import (
    ComponentIdentity,
    HackathonPrismModel,
    PrismP0Error,
    derive_lot_size,
    exact_component_amount,
    exact_replication_certificate,
)


def components():
    return (
        ComponentIdentity("yes", "market", 0, "stable", 6, "spec-hash"),
        ComponentIdentity("no", "market", 1, "stable", 6, "spec-hash"),
    )


class PrismP0ModelTest(unittest.TestCase):
    def test_reduced_fraction_derives_exact_lot_without_rounding(self):
        weights = (Fraction(2, 6), Fraction(4, 6))
        lot = derive_lot_size(weights)
        self.assertEqual(lot, 3)
        self.assertEqual(exact_component_amount(12, weights[0], lot), 4)
        self.assertEqual(exact_component_amount(12, weights[1], lot), 8)
        for amount in range(0, 300, lot):
            self.assertEqual(amount * weights[0].numerator % weights[0].denominator, 0)
            self.assertEqual(amount * weights[1].numerator % weights[1].denominator, 0)

    def test_mint_is_minter_funded_transferable_and_redeemable_in_kind(self):
        model = HackathonPrismModel(components(), (Fraction(1, 2), Fraction(1, 2)))
        self.assertEqual(model.lot_size_raw, 2)
        model.fund_wallet("alice", 0, 5_000_000)
        model.fund_wallet("alice", 1, 5_000_000)
        model.mint("alice", 10_000_000, "alice")
        self.assertEqual(model.physical_balances, [5_000_000, 5_000_000])
        model.transfer("alice", "bob", 6_000_000)
        self.assertEqual(model.redeem_in_kind("bob", 6_000_000), (3_000_000, 3_000_000))
        self.assertEqual(model.total_supply, 4_000_000)
        self.assertEqual(model.physical_balances, [2_000_000, 2_000_000])
        model.assert_backed()

    def test_unaligned_mint_and_unfunded_other_minter_preserve_state(self):
        model = HackathonPrismModel(components(), (Fraction(1, 2), Fraction(1, 2)))
        model.fund_wallet("alice", 0, 100)
        model.fund_wallet("alice", 1, 100)
        model.mint("alice", 100, "alice")
        before = model.snapshot()
        with self.assertRaises(PrismP0Error):
            model.mint("bob", 2, "bob")
        self.assertEqual(model.snapshot(), before)
        with self.assertRaises(PrismP0Error):
            model.mint("alice", 3, "alice")
        self.assertEqual(model.snapshot(), before)

    def test_direct_donation_remains_surplus_not_minter_credit(self):
        model = HackathonPrismModel(components(), (Fraction(1, 2), Fraction(1, 2)))
        model.donate(0, 100)
        before = model.snapshot()
        with self.assertRaises(PrismP0Error):
            model.mint("bob", 2, "bob")
        self.assertEqual(model.snapshot(), before)

    def test_factory_and_collateral_admission_are_explicit(self):
        unregistered = (components()[0], ComponentIdentity("other", "market2", 0, "stable", 6, "h", factory_admitted=False))
        with self.assertRaises(PrismP0Error):
            HackathonPrismModel(unregistered, (1, 1))
        wrong_collateral = (components()[0], ComponentIdentity("other", "market2", 1, "other", 6, "h"))
        with self.assertRaises(PrismP0Error):
            HackathonPrismModel(wrong_collateral, (1, 1))

    def test_only_deployment_pinned_creator_can_admit_a_series(self):
        with self.assertRaises(PrismP0Error):
            HackathonPrismModel(components(), (1, 1), series_creator="operator", caller="anyone")

    def test_standard_erc20_zero_and_self_transfer_are_noop_transitions(self):
        model = HackathonPrismModel(components(), (Fraction(1, 2), Fraction(1, 2)))
        model.fund_wallet("alice", 0, 5)
        model.fund_wallet("alice", 1, 5)
        model.mint("alice", 10, "alice")
        before = model.snapshot()
        model.transfer("alice", "bob", 0)
        model.transfer("alice", "alice", 4)
        self.assertEqual(model.snapshot(), before)

    def test_demo_series_has_an_exact_gx_equals_h_certificate(self):
        cert = exact_replication_certificate(
            ((1, 0), (0, 1)),
            (Fraction(1, 2), Fraction(1, 2)),
            (Fraction(1, 2), Fraction(1, 2)),
            components(),
        )
        self.assertTrue(cert["exact_recheck"])
        self.assertEqual(cert["recomputed_Gx"], cert["h"])


if __name__ == "__main__":
    unittest.main()

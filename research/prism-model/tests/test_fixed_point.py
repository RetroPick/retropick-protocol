import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import unittest
from fractions import Fraction

from fixed_point import (
    WAD,
    decode_fraction,
    encode_fraction_ceil,
    encode_fraction_floor,
    exact_required_fraction,
    mul_div_ceil,
    mul_div_floor,
    releasable_backing_units,
    required_backing_units,
    round_trip_dust_units,
)


class FixedPointTests(unittest.TestCase):
    def test_mul_div_floor_and_ceil(self):
        self.assertEqual(mul_div_floor(1, 3, 2), 1)
        self.assertEqual(mul_div_ceil(1, 3, 2), 2)

    def test_fraction_encoding(self):
        self.assertEqual(encode_fraction_floor(Fraction(3, 5)), 6 * 10**17)
        self.assertEqual(encode_fraction_ceil(Fraction(3, 5)), 6 * 10**17)
        self.assertEqual(decode_fraction(6 * 10**17), Fraction(3, 5))

    def test_exact_normal_sized_requirement(self):
        x = encode_fraction_ceil(Fraction(3, 5))
        q = WAD  # one whole series token in 18-decimal normalized units
        self.assertEqual(required_backing_units(q, x), 6 * 10**17)
        self.assertEqual(releasable_backing_units(q, x), 6 * 10**17)
        self.assertEqual(round_trip_dust_units(q, x), 0)

    def test_micro_quantity_is_conservative(self):
        x = encode_fraction_ceil(Fraction(3, 5))
        q = 1
        exact = exact_required_fraction(q, x)
        required = required_backing_units(q, x)
        released = releasable_backing_units(q, x)

        self.assertGreaterEqual(Fraction(required), exact)
        self.assertLessEqual(Fraction(released), exact)
        self.assertGreaterEqual(required, released)

    def test_round_trip_never_releases_more_than_required_in_bounded_grid(self):
        weights = [Fraction(1, 10), Fraction(1, 3), Fraction(3, 5), Fraction(1)]
        for weight in weights:
            x = encode_fraction_ceil(weight)
            for q in range(1, 1000):
                required = required_backing_units(q, x)
                released = releasable_backing_units(q, x)
                self.assertLessEqual(released, required)
                self.assertGreaterEqual(round_trip_dust_units(q, x), 0)

    def test_many_micro_redemptions_do_not_exceed_one_shot_exact_requirement(self):
        # This is a local safety property of floor-on-release. It also highlights
        # that dust/minimum-size policy still needs to be finalized before Solidity.
        x = encode_fraction_ceil(Fraction(3, 5))
        total_q = 100
        one_shot_required = required_backing_units(total_q, x)
        micro_released = sum(releasable_backing_units(1, x) for _ in range(total_q))
        self.assertLessEqual(micro_released, one_shot_required)


if __name__ == "__main__":
    unittest.main()

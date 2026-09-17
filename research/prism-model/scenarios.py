"""Deterministic Phase-1 scenarios."""
from fractions import Fraction

from model import PrismSeries
from replication import find_exact_nonnegative_replication


G = [
    [0, 1],  # Fed no, BTC no -> FED_YES=0, BTC_NO=1
    [0, 0],  # Fed no, BTC yes
    [1, 1],  # Fed yes, BTC no
    [1, 0],  # Fed yes, BTC yes
]


def main():
    series = PrismSeries(G, [Fraction(3, 5), Fraction(2, 5)])
    series.activate()
    series.mint_with_exact_backing(1000)

    print("terminal payoff:", [str(x) for x in series.terminal_payoff_vector])
    print("supply:", series.supply)
    print("backing:", [str(x) for x in series.backing])
    print("terminal solvency:")
    for state, backing, liability, solvent in series.terminal_solvency():
        print(state, "backing=", backing, "liability=", liability, "solvent=", solvent)

    released = series.redeem_in_kind(100)
    print("redeemed backing:", [str(x) for x in released])

    series.start_resolution()
    series.resolve(3)  # Fed yes, BTC yes => payout 0.6
    required = series.supply * series.final_payout
    series.fund_settlement(required)
    series.make_redeemable()
    paid = series.redeem_final(series.supply)
    series.archive()
    print("final paid:", paid)
    print("state:", series.state.value)

    # Demonstrate non-replicable AND with A=(0,0,1,1), B=(0,1,0,1)
    G_and = [
        [0, 0],
        [0, 1],
        [1, 0],
        [1, 1],
    ]
    target = [0, 0, 0, 1]
    print("AND replication:", find_exact_nonnegative_replication(G_and, target))


if __name__ == "__main__":
    main()

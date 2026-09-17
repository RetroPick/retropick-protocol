"""Deterministic Phase-1 scenarios for human review and evidence."""
from fractions import Fraction

from market_math import (
    buy_and_merge_profit,
    complete_set_open_interest,
    partial_resolution_nav,
    post_resolution_pair_value,
    prism_create_cost,
    prism_redeem_value,
    split_and_sell_profit,
)
from model import PrismSeries
from replication import find_exact_nonnegative_replication


# Worlds:
# 0 = Fed no,  BTC no
# 1 = Fed no,  BTC yes
# 2 = Fed yes, BTC no
# 3 = Fed yes, BTC yes
G = [
    [0, 1],
    [0, 0],
    [1, 1],
    [1, 0],
]
X = [Fraction(3, 5), Fraction(2, 5)]


def prism_accounting_scenario():
    print("=== PRISM exact-backed accounting ===")
    series = PrismSeries(G, X)
    series.activate()
    series.mint_with_exact_backing(1000)

    print("terminal payoff vector:", [str(x) for x in series.terminal_payoff_vector])
    print("expected worlds: [0.4, 0, 1.0, 0.6]")
    print("supply:", series.supply)
    print("backing:", [str(x) for x in series.backing])
    print("terminal solvency:")
    for state, backing, liability, solvent in series.terminal_solvency():
        print(
            f"  world={state}",
            "backing=", backing,
            "liability=", liability,
            "solvent=", solvent,
        )

    released = series.redeem_in_kind(100)
    print("redeem 100 -> backing released:", [str(x) for x in released])
    print("remaining supply:", series.supply)
    print("remaining backing:", [str(x) for x in series.backing])

    # Resolve to world 2: Fed YES + BTC NO. This is the historical report's
    # previously incorrect example. Correct payout is 1.0, not 0.6.
    series.start_resolution()
    series.resolve(2)
    print("resolved world 2 final payout:", series.final_payout)
    required = series.supply * series.final_payout
    print("settlement required:", required)
    series.fund_settlement(required)
    series.make_redeemable()
    paid = series.redeem_final(series.supply)
    series.archive()
    print("final paid:", paid)
    print("state:", series.state.value)


def replication_counterexample():
    print("\n=== Non-replicable AND counterexample ===")
    # A=(0,0,1,1), B=(0,1,0,1)
    G_and = [
        [0, 0],
        [0, 1],
        [1, 0],
        [1, 1],
    ]
    target = [0, 0, 0, 1]
    result = find_exact_nonnegative_replication(G_and, target)
    print("AND replication:", result)
    print("expected: None")


def complete_set_scenario():
    print("\n=== Native complete-set accounting ===")
    oi = complete_set_open_interest(100, 100, 100)
    print("100 collateral -> 100 YES + 100 NO")
    print("open interest:", oi, "(not 200)")

    split_profit = split_and_sell_profit(
        Fraction(55, 100),
        Fraction(50, 100),
        total_cost=Fraction(1, 100),
    )
    print("split+sell profit at bids 0.55/0.50 with 0.01 cost:", split_profit)

    merge_profit = buy_and_merge_profit(
        Fraction(45, 100),
        Fraction(50, 100),
        total_cost=Fraction(1, 100),
    )
    print("buy+merge profit at asks 0.45/0.50 with 0.01 cost:", merge_profit)


def market_value_scenario():
    print("\n=== PRISM market-value identities ===")
    asks = [Fraction(40, 100), Fraction(70, 100)]
    bids = [Fraction(38, 100), Fraction(68, 100)]
    create = prism_create_cost(X, asks, fees=Fraction(1, 100))
    redeem = prism_redeem_value(X, bids, fees=Fraction(1, 100))
    print("create cost:", create)
    print("redeem value:", redeem)
    print("reference interval before risk terms:", redeem, "to", create)

    partial = partial_resolution_nav(
        X,
        resolved={0: 1},
        unresolved_marks={1: Fraction(30, 100)},
    )
    print("partial resolution NAV (0.6*1 + 0.4*0.30):", partial)

    final_payout = Fraction(60, 100)
    print(
        "resolved 0.60 PRISM against MON=$2:",
        post_resolution_pair_value(final_payout, 2),
        "MON",
    )
    print(
        "resolved 0.60 PRISM against MON=$1:",
        post_resolution_pair_value(final_payout, 1),
        "MON",
    )


def main():
    prism_accounting_scenario()
    replication_counterexample()
    complete_set_scenario()
    market_value_scenario()


if __name__ == "__main__":
    main()

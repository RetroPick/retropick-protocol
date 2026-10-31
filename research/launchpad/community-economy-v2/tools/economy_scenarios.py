#!/usr/bin/env python3
"""Deterministic illustrative scenarios, not forecasts or execution qualification."""
import json
from decimal import Decimal

UNIT = 10**6  # hypothetical exact six-decimal quote
POLICIES = {
    "creator_meme": (6000, 0, 4000, 0, 0),
    "contributor_collective": (2000, 4000, 4000, 0, 0),
    "staker_rewards": (2000, 0, 4000, 4000, 0),
    "treasury_liquidity": (1000, 0, 6000, 1000, 2000),
}


def simulate():
    results = []
    for name, shares in POLICIES.items():
        assert sum(shares) == 10000
        for level, volume in [("low", 100), ("medium", 10000), ("high", 1000000)]:
            # $10 hypothetical gross trades, 1% base + 0.5% additional creator tax.
            trades = volume // 10
            base = trades * (10 * UNIT * 100 // 10000)
            tax = trades * (10 * UNIT * 50 // 10000)
            protocol = base * 3000 // 10000
            community = base - protocol + tax
            allocations = [community * s // 10000 for s in shares]
            dust = community - sum(allocations)
            allocations[2] += dust
            assert base + tax == protocol + sum(allocations)
            creator, contributor, treasury, rewards, liquidity_budget = allocations
            # Illustrative costs, not current network prices: 1 gwei, MON=$1.
            claim_quote = Decimal(83308) * Decimal("0.000000001")
            eligible_stakers = 10000
            equal_reward = Decimal(rewards) / UNIT / eligible_stakers
            # Constant-product spot model, no actual venue execution or exit guarantee.
            depth = 10000 * UNIT
            budget = liquidity_budget
            modeled_impact = Decimal(budget) / (depth + budget) if budget else Decimal(0)
            captured_rebate_bps = Decimal(3000) * Decimal(rewards) / (base + tax)
            # Attacker owning 30% of rewards still pays all trading fees; excludes price/MEV/gas.
            wash_fee = base + tax
            wash_rebate = rewards * 3000 // 10000
            results.append({
                "archetype": name, "activity": level, "gross_quote_units": volume * UNIT,
                "trade_count": trades, "base_fee": base, "creator_tax": tax,
                "protocol": protocol, "community": community,
                "creator": creator, "contributors": contributor, "treasury": treasury,
                "rewards": rewards, "liquidity_budget_unexecuted": liquidity_budget,
                "dust_to_treasury": dust, "eligible_stakers_assumed": eligible_stakers,
                "reward_per_equal_staker_quote": str(equal_reward),
                "assumed_claim_cost_quote": str(claim_quote),
                "reward_below_assumed_claim_cost": equal_reward < claim_quote,
                "largest_staker_reward_at_50pct": rewards // 2,
                "modeled_single_clip_impact_fraction": str(modeled_impact),
                "protected_exit_liquidity_after_budget_claim": depth,
                "wash_fee_cost_before_price_and_gas": wash_fee,
                "wash_rebate_to_30pct_staker": wash_rebate,
                "wash_net_fee_loss": wash_fee - wash_rebate,
                "captured_fee_rebate_bps": str(captured_rebate_bps),
                "settlement_gas_assuming_64_trades_per_settlement": ((trades + 63) // 64) * 456538,
                "status": "ILLUSTRATIVE_NOT_CALIBRATED_NOT_IMPLEMENTED_REWARDS_OR_LP",
            })
    return results


if __name__ == "__main__":
    print(json.dumps({"denomination": "6 decimals", "scenarios": simulate()}, indent=2))

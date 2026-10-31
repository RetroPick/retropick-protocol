# Competitor capability matrix

Documentation checked 2026-10-31; no third-party deployment or source audit performed. Feature presence is not adoption evidence. Source links and evidence limits are in PRODUCT_DEMAND_EVIDENCE.md.

| Capability | Pump official docs | Zora official docs | Uniswap v4 primitive | RetroPick experiment |
|---|---|---|---|---|
| Creator trading income | Documented | Documented | Custom hook can define it | Actual curve P/C separation locally tested |
| Multiple beneficiaries | Fee-sharing instructions | Reward categories described; arbitrary wallet split not established here | Custom logic required | Max10 published beneficiaries, independent claims |
| Changes and old earnings | Documented final-share update sweeps old fees, then revokes admin | Mutability guarantees not verified here | No generic constitutional guarantee | Delayed future policy; authentic old-epoch checkpoint |
| Venue collection rights | Canonical curve/AMM-specific instructions | Protocol/market-specific rewards | Hook fees distinct from pool LP fees | Curve supported; CE v4 collection disabled; Kuru blocked |
| Staker/holder reward mode | Do not infer current implementation from marketing/search snippets | Trading reward categories differ by coin/market | Requires additional implementation | DEFERRED, no all-holder promise |
| Treasury/recovery guarantees | Not independently verified | Not independently verified | Application-specific | EOA treasury disclosed; controller changes do not transfer old router credits |

[Uniswap custom accounting](https://developers.uniswap.org/docs/protocols/v4/guides/custom-accounting) documents hook-based custom fee logic separately from pool fees. That technical capability does not grant an existing token rights to unrelated pools.

Differentiation hypothesis: bounded, delayed future editing with independently payable old claims. Creator fees, rewards, buybacks and splitting alone are not defensible novelty claims. Competitive security, gas and user outcomes remain unmeasured. Do not claim competitors lack protections merely because this scoped review did not establish them.

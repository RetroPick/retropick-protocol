---
id: LP-FEES
type: normative
product: launchpad
version: v2
status: active
---

# Fees and Economics

Separate economic categories:
- base curve/trade fee;
- creator trade tax/fee where retained;
- protocol share;
- buyback share where retained;
- launch fee;
- Kuru venue fees after graduation.

For each active category the implementation must define payer, denomination, basis, maximum, receiver, collection point, mutability/snapshot behavior and event.

Normative constraints:
- combined primary trade fees are bounded;
- fee balances are not graduation reserves;
- creator settings cannot exceed protocol ceilings;
- Kuru maker/taker fees are destination-market parameters, not primary curve fee replacements;
- UI discloses applicable primary fees/slippage before signing.

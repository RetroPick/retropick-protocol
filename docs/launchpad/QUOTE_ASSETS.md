---
id: LP-QUOTE
type: normative
product: launchpad
version: v2
status: active
---

# Quote Assets

P0 supports native MON plus one explicitly qualified stable quote if target deployment supports it.

An ERC20 quote is not accepted merely because it implements IERC20.

Admission considers:
- decimals and configured economics;
- exact transfer behavior;
- rebasing/fee-on-transfer/callback behavior;
- freeze/blacklist issuer risk;
- liquidity/operational availability;
- Kuru pair compatibility;
- valid destination market parameters.

Same-quote graduation is the default. Cross-quote conversion requires a new explicit architecture because it introduces conversion/slippage/oracle/MEV risk.

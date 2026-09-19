---
id: LP-SC-QUOTE
type: normative_implementation
status: ready
owner: launchpad-solidity
product: launchpad
version: v2
---

# Quote Assets

## P0 policy
Native MON plus one explicitly qualified stable asset if target deployment supports it.

## ERC20 admission checks
- contract code exists;
- decimals readable and match stored economics;
- exact-transfer semantics required unless explicitly supported;
- no rebasing/fee-on-transfer/callback-dependent accounting in P0;
- freeze/blacklist issuer risk documented;
- Kuru pair is supported and market parameters can be validly derived.

## Security
Arbitrary IERC20 compatibility is not promised. Quote admission is a protocol decision, not creator input.

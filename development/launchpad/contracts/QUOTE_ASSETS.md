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

The current Factory verifies code, decimals and configured economics, but cannot infer exact-transfer behavior from ERC-20 metadata. An owner can approve a six-decimal sender-surcharge token that causes the Curve's physical quote balance to fall below `trackedQuote` on a sell; the executable counterexample is [recorded here](../../../evidence/launchpad/core/quote-surcharge-counterexample-2026-09-29.md). Admission therefore requires asset-specific evidence and operational approval controls; a successful `setPairTokenApproved` call is not proof of quote safety.

## Security
Arbitrary IERC20 compatibility is not promised. Quote admission is a protocol decision, not creator input.

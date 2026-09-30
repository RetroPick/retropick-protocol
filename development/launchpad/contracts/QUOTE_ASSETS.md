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
Native MON plus the specifically identified chain-10143 Circle test USDC (`0x534b2f3A21130d7a60830c2Df862319e593943A3`), subject to full Core/Kuru qualification. Kuru-listed `0x3bA3d39AFcf8bb994f7964B3e0171Ea2Ba361570` is a separate compatibility fixture, not canonical Circle USDC. Neither symbol nor owner approval confers asset identity. The current implementation has an immutable address/chain/decimal policy; it does not establish deployment readiness while the control-plane gates remain blocked.

## ERC20 admission checks
- contract code exists;
- decimals readable and match stored economics;
- exact-transfer semantics required unless explicitly supported;
- no rebasing/fee-on-transfer/callback-dependent accounting in P0;
- freeze/blacklist issuer risk documented;
- Kuru pair is supported and market parameters can be validly derived.

The historical owner-allowlist design admitted a six-decimal sender-surcharge token and could deficit Curve `trackedQuote`; the original [counterexample](../../../evidence/launchpad/core/quote-surcharge-counterexample-2026-09-29.md) remains preserved. The [2026-09-30 increment](../../../evidence/launchpad/core/quote-backing-escrow-increment-2026-09-30.md) adds an immutable P0 identity policy and checks exact sender/recipient deltas and physical backing in the Curve and production FeeEscrow. It rejects the tested surcharge transfer before accounting and fails closed after external token balance loss; it cannot reverse an issuer freeze, blacklist or external balance loss. The Factory's V4 `_transferExact` currently checks recipient gain but not its own sender loss, so a quote whose behavior changes after admission remains an open multi-launch custody risk until that path is separately qualified or eliminated from the P0 target. Do not mark `CORE_BASELINE_QUALIFIED` PASS on this evidence alone.

## Security
Arbitrary IERC20 compatibility is not promised. Quote admission is a protocol decision, not creator input.

# Adversarial grill — current decision record

Method: source/ABI inventory, explicit economic equations, attacker capabilities, smallest action-sequence tests, stateful conservation, differential baseline, static analysis and independent agent read-only review. A discovered grilling skill informed the review; no named skill is represented as an external audit. Security locations/results are in SECURITY_FINDINGS.md and compiled source inventory. Broad product review remains partial.

| Question | Skeptical conclusion | Reproduction / decision |
|---|---|---|
| Why switch launchpads? | Split fees are already competitive; bounded future changes may help teams, but demand is unproven | Require user evidence, no novelty or majority-demand claim |
| Can a policy steal old earnings? | A policy-history mapping alone cannot protect curve-held fees | Real checkpoint funds old epoch; beneficiary/epoch fuzz and activation sequences pass |
| Can creator identity become router administration? | Legacy recipient/controller conflation is unsafe for CE mode | Separate real controller; reject legacy owner/creator override paths; old credits unaffected |
| Can privileged parties drain accrued claims? | Router has no owner rescue or mutable source; guardian controls future admin only | Controller handoff, beneficiary rotation, bypass rejection and source bindings tested |
| Can fake volume become funded rewards? | Router accepts only immutable real curve; genuine versus wash trading is still not identifiable from receipts | Reject arbitrary attribution; donations create no income; reward economics remain adversarial |
| Can repeated sweeps change dust distribution? | Floors occur at settlement, residual goes to fixed treasury; very small claims may be zero | Native/USDC one-unit tests; disclose aggregate rounding and dust rather than promise exact fractional dust rights |
| Can recipient code block others? | It must only fail its own pull transaction | Reverting beneficiary, reentrant claim and independent treasury claims pass |
| Can one community cover another's deficit? | Separate per-launch custody prevents shared liability subsidy | Two-router USDC destruction/claim isolation test passes |
| Can an admitted token break backing? | Issuer balance destruction is not solved by SafeERC20 | Sender/receiver exact checks and pre/post backing; unsupported tokens fail closed, no insurance |
| Can conversions or operators freeze activation? | Quote settlement should not depend on discretionary swaps | Permissionless direct quote settlement; no conversion/buyback in slice; protocol escrow remains a liveness dependency |
| Can creator abandonment grant an attacker control? | No balance-based automatic takeover | Immutable guardian plus delays; expire only clears stale pending transition; full recovery races still open |
| Can recovery stop a compromised controller immediately? | No: existing future authority persists until delayed handoff | Disclose this limitation; old claims remain protected, no emergency confiscation |
| Are Kuru and v4 fees actually collectible? | Volume and locked LP do not establish rights | Kuru blocked; CE v4 snapshots zero unsupported hook fee/tax; actual adapter deferred |
| Can LP or graduation assets fund claims? | Only legitimate F/T may fund C; reserves are not income | Real source/coordinator graduation test secures net reserves and preserves payable claims |
| Can an expected buyback be manipulated? | Spot/slippage guards alone are insufficient | Keep execution disabled pending independent reference/MEV/clip/cooldown proof |
| Does low-volume yield justify custody complexity? | Often no, especially many eligible stakers | Deterministic scenarios show small reward/claim-cost mismatch; no APY promise |
| Does new code break legacy pricing? | New mode must be additive | Eight native/USDC buy/sell differential cycles compare fees, output, reserves and readiness |
| Is gas/bytecode acceptable? | Factory has only 90 bytes headroom; deployments are expensive | Source-identity-checked sizes, gas report and snapshot; long-history/max-recipient campaign open |

No arbitrary-attacker reserve theft is claimed. Baseline old-recipient/vest redirection reproduces intended authority that conflicts with CE guarantees. Reproducible defects and harness failures are preserved rather than relabeled as exploits. Missing reward/buyback/venue proofs block release.

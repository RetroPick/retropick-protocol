---
id: LP-INVARIANTS
type: normative
product: launchpad
version: v2
status: active
---

# Invariants

1. Total token supply follows the accepted fixed/capped model.
2. Real token/quote reserves reconcile actual transfers.
3. Explicit fee allocations reconcile and remain separate from reserves.
4. Quote payout never exceeds withdrawable real quote reserve.
5. Fee ceilings cannot be exceeded.
6. No unauthorized mint or active-reserve seizure.
7. Quote-asset policy cannot be bypassed.
8. Graduation executes at most once.
9. Secured graduation assets cannot disappear.
10. Destination failure remains safe/retryable.
11. Terminal graduation cannot silently reopen primary bonding.
12. Kuru integration cannot alter frozen bonding math.
13. Administrative/creator mutations obey authorization/timelocks/snapshot rules.
14. Read models/UI cannot redefine contract state.

Every invariant maps to a requirement and executable test/evidence before release.

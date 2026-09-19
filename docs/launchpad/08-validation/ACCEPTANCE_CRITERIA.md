# Acceptance Criteria

**Status:** ACTIVE  
**Owner:** Validation

P0 is releasable only when:

- V2 compiles within bytecode/initcode constraints.
- token supply and reserve/fee invariants pass.
- buy/sell quotes and onchain execution reconcile.
- quote-policy rejection/compatibility cases pass.
- threshold crossing and two-phase graduation pass.
- external venue failure is safe/retryable.
- Kuru handoff is demonstrated on the claimed environment.
- indexer can rebuild required read models and exposes freshness.
- browser create/buy/sell/graduation/post-graduation flows pass.
- current static/manual security findings are triaged with no unresolved release blocker.
- deployment/address/config documentation matches reality.
- no secrets are committed.
- golden demo is reproducible.

Verdict is PASS, CONDITIONAL_PASS or FAIL with named blockers.

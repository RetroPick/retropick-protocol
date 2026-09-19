---
id: LP-SC-INVARIANTS
type: normative_implementation
status: ready
owner: launchpad-security
product: launchpad
version: v2
---

# Contract Security Invariants

- LP-I-001 total minted supply follows token model.
- LP-I-002 real token/quote reserves reconcile transfers and explicit fees.
- LP-I-003 quote payout <= real withdrawable quote.
- LP-I-004 fee limits cannot be exceeded.
- LP-I-005 no unauthorized mint or reserve seizure.
- LP-I-006 graduation executes at most once.
- LP-I-007 secured graduation balances cannot disappear.
- LP-I-008 failed destination action remains safe/retryable.
- LP-I-009 graduated launch cannot resume ordinary bonding trading.
- LP-I-010 quote admission cannot be bypassed.
- LP-I-011 creator fee-recipient/admin changes obey authorization/timelocks.
- LP-I-012 V2 Kuru migration does not alter frozen bonding math.

Every invariant must map to a Foundry unit/fuzz/stateful test or a justified integration property.

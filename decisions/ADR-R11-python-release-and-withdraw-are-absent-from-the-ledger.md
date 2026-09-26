# ADR-R11: Python release and withdraw are absent from the ledger

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `CandidateReservationLedger.reserve`, `CandidateReservationLedger.deposit`, the Python `ReservationLedger.reserve` function, the Python `ReservationLedger.deposit` function, the Python `ReservationLedger.release` function, or the Python `ReservationLedger.withdraw` function. Neither implementation may be edited to add or remove `release` or `withdraw` until this ADR is explicitly accepted.

The recorded reserves of 50 after 60, of 40 by a second series, and of 40 by the same series are different witnesses. They are not this decision.

## Decision

Propose that the measured function lists stay recorded and that neither ledger is edited until a human accepts one rule. The open decision is whether Phase-1 must add `release` and `withdraw` to the ledger, or those operations stay outside the kernel. This proposal does not choose that winner and does not change code.

## Options

Leave both sides as measured. Python `ReservationLedger` declares `deposit`, `reserve`, `release`, and `withdraw`. `CandidateReservationLedger` declares `deposit` and `reserve`. It does not declare `release`. It does not declare `withdraw`.

Or, after acceptance, add `release` and `withdraw` to the Solidity ledger. This proposal does not choose that option.

Or, after acceptance, keep `release` and `withdraw` outside the kernel. This proposal does not choose that option.

## Evidence

`research/prism-model/reservation_ledger.py`.  
`research/contract-kernels/src/prism/CandidateReservationLedger.sol`.  
`evidence/research/prism/r-theorem-6-2026-09-26.json`.

Python state-changing names on `ReservationLedger` are `deposit`, `reserve`, `release`, and `withdraw`. `release` takes a series id and a mapping of releases. `withdraw` takes an asset and an amount.

Solidity state-changing names on `CandidateReservationLedger` are `deposit` and `reserve`. The contract does not declare `release`. The contract does not declare `withdraw`. No function was added.

`evidence/research/prism/r-theorem-6-2026-09-26.json` is the T-ALLOC-001 record, also named R-THEOREM-6. Z3 5.1.0 finds the negation of the reservation invariant unsat for `deposit`, `reserve`, `release`, and `withdraw` when other series are one nonnegative total. Classification of that record is PROVEN_UNDER_ASSUMPTIONS. That proof is not MATH-1 PASS. Canonical MATH-1 stays FAIL because the per-call settlement floor still fails. The proof does not declare `release` or `withdraw` on `CandidateReservationLedger`.

## Benchmark

Not a gas study. No Solidity call was added, so no gas was measured for `release` or `withdraw`.

## Security implications

Python can reduce a series bucket through `release` and can reduce an unreserved balance through `withdraw`. The Solidity ledger can only increase balance through `deposit` and increase a series bucket through `reserve`. A reserved amount on the kernel stays reserved. An unreserved balance on the kernel stays in the accounted balance. Adding either function before acceptance would replace that measured absence.

## Tradeoffs

The Python model includes `release` and `withdraw` in the T-ALLOC-001 transitions. The Solidity kernel omits both names. Matching the Python names requires an edit. Leaving both sides unchanged preserves the measured lists. The open decision stays open until a human accepts one rule.

## Recommendation

Do not edit `CandidateReservationLedger`. Do not edit `ReservationLedger.release` or `ReservationLedger.withdraw`. Do not add `release`. Do not add `withdraw`. Acceptance is not granted. The open decision stays open until a human accepts one of the two rules above.

## Confidence

High for this draft. The Python class declares `release` and `withdraw`. The Solidity contract source does not declare either name. That does not measure a later edit, and it does not rerun the Z3 proof.

## What would falsify this

A later reading of `CandidateReservationLedger` that declares `release` or `withdraw`. Or a later reading of `ReservationLedger` that no longer declares `release` and no longer declares `withdraw`. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.

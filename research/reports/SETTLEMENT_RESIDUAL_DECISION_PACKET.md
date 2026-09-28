# PRISM terminal settlement residual — decision packet

**Status:** PROPOSED research recommendation; no sweep, refund, archive transfer, or production contract is authorized. This packet is separate from ADR-R03's payout formula and holder-allocation decision.

## Accounting boundary

Let `F = ceil(S * payoutWad / D)` be the exact admission funding target and `P = floor(S * payoutWad / D)` be the proposed global-cursor aggregate payment after all `S` units redeem. If physical settlement balance at opening is exactly `F` and cannot change except through redemption, final residual is `F-P`, exactly 0 or 1 raw settlement unit. This is `PROVEN_UNDER_ASSUMPTIONS`; `evidence/research/prism/zero-supply-dust-2026-09-26.json` and `candidate-telescope-proof-2026-09-26.json` record the existing proof and regression.

For opening balance `F+X`, final balance is `F-P+X` only when no later external balance change occurs. `X` can contain an explicit overfund, a voluntary direct ERC20 transfer, or an accidental transfer. A post-opening balance decrease can make a payout revert even while `redeemable` remains true; existing rebasing tests exhibit that behavior. The current `CandidateCumulativeSettlement` has no `fundSettlement` ledger. It checks `balanceOf` and cannot distinguish those origins onchain. Therefore **the final token balance is not automatically rounding dust**. A sweep of all remaining balance is unsupported by the mathematical residual bound.

## Options

| Disposition after all liability units burn | Holder and ordering effect | Donation, security, and operations effect |
|---|---|---|
| A. Permanently locked | No actor captures residual; does not repair ADR-R03 holder-allocation drift | Simplest accounting, but overfunding and mistaken transfers can be stranded forever. No extraction surface. |
| B. Immutable dust sink | Transfers at most the accounted 0/1 residual after `supply=0` and `redeemedUnits=initialSupply`; no last-redeemer prize | Requires an explicit funding ledger and a separate rule for unassigned tokens. A sweep of the whole balance is unsafe. Fixed destination reduces discretionary control but adds an external transfer at archive. |
| C. Protocol treasury | Same payout semantics as B | Creates recurring protocol capture and governance custody questions. Must not count donations as fees without a separate rule. |
| D. Last redeemer | Raises aggregate holder payment from floor toward ceil by at most one raw unit under exact funding | Gives a visible ordering prize, encourages last-call competition, and complicates fragmented redemption/MEV. Does not solve larger holder carry shifts. |
| E. Series creator | Same holder effect as B | Incentivizes series proliferation or payout manipulation to collect residuals; creator must not claim external donations by default. |
| F. Identified funder refund | Leaves holder payment unchanged; returns the 0/1 funding overhang to the party that supplied it | Requires recorded funder shares and deterministic handling of multiple funders, third-party funding, and direct transfers. More storage and audit burden. |

The residual is no more than one **raw token unit** only under exact-ceil, non-rebasing, fee-free assumptions. It may be economically tiny for common decimals, but a repeated-series treasury or creator route still changes incentives. The current gas evidence is one local funding/open/redemption sample; no archive transfer exists to benchmark yet.

## Recommended Phase-1 rule for human review

Keep the current research kernel's **no-sweep behavior** while ADR-R03 and asset admission remain open. For an eventual production rule, prefer an immutable sink only for a separately accounted rounding residual after complete redemption; keep any direct-transfer surplus in a distinct, explicitly governed bucket. An explicit funding function should measure the actual token balance delta, credit no more than the remaining ceil liability to `accountedFunding`, and reject or return excess in the same transaction. `openRedemption` should require `accountedFunding >= F` as well as physical balance `>= F`. Unsolicited direct transfers should not increase `accountedFunding`; they remain unassigned surplus under a separate recovery policy. This prevents an accidental transfer from silently becoming either protocol funding or protocol-owned dust.

The proposed ledger is a design recommendation, not an implemented or accepted rule. It requires a full Python model, Solidity research kernel, transfer/fee/rebase adversarial tests, and multi-funder analysis before acceptance. If the human policy instead treats every token held at opening as funding, the accounting and eventual beneficiary must be specified explicitly. With only the current balance-based kernel, no provenance split can be proven.

## Required guards and falsifiers

- Disposition only after token liability supply is zero **and** the global redeemed cursor equals the frozen initial supply; a balance check alone is insufficient.
- Never allow the resolver, creator, admin, or dust destination to remove settlement assets while liability remains. Rejected cleanup calls must preserve state.
- Reject or conditionally isolate tokens whose balances can shrink externally, whose transfer delivers less than requested, or whose callbacks can reenter the series. `redeemable=true` is not durable proof of live funding.
- Reconcile credited funding, payouts, the bounded residual, and unassigned balance against physical `balanceOf` before any archive transfer. A mismatch stops cleanup and remains evidence of a broken assumption.
- A counterexample where an accepted transition transfers more than its explicitly owned bucket, or where an external balance change strands a holder after admission, falsifies the proposed policy and keeps MATH-1/CONTRACT-ARCH-1 blocked.

**Decision owner:** human protocol authority. Acceptance must specify the beneficiary, transfer path, treatment of direct donations and overfunding, and whether a funder's 0/1 raw unit is refundable. Until then, residual policy is `NOT_YET_VALIDATED`; PRISM MATH-1 remains FAIL.

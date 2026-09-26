# ADR-P18: Resolution spec timing differs between constructor and activate

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to the `PredictionMarket` constructor, `activate`, `resolve`, the Python `create_market` function, the Python `activate` function, or any payout formula. Neither implementation may be edited to move the spec write until this ADR is explicitly accepted.

ADR-P07 stays PROPOSED. It says freeze `resolutionSpecHash`, collateral id, and resolver at activation, and it says the kernel stores `bytes32 resolutionSpecHash` with no setter. It does not state that Solidity writes the hash in the constructor while the state is `DRAFT`, and it does not state that Python writes the spec only in `activate`. This file does not edit ADR-P07 and does not supersede it.

ADR-P04, ADR-P13, and ADR-P15 stay PROPOSED. This file does not edit them. The `resolve(YES_WIN)` reject while `DRAFT` stays `existing_rule`.

## Decision

Propose that the measured timing stay recorded and that neither side is edited until a human accepts one rule. The open decision is whether Phase-1 must leave the spec unset until `activate`, or the hash may be stored in the constructor while the state remains `DRAFT`. This proposal does not choose that winner and does not change code.

## Options

Leave both writes as measured. Python `create_market` leaves `spec` unset and the state `DRAFT`. Python `activate` assigns `spec` and sets the state to `OPEN` in the same call. Solidity stores `resolutionSpecHash` in the constructor and leaves the state `DRAFT`. Solidity `activate` does not write the hash.

Or, after acceptance, leave the spec unset until `activate` on both sides. This proposal does not choose that option.

Or, after acceptance, store the hash in the constructor while the state remains `DRAFT` on both sides. This proposal does not choose that option.

## Evidence

`evidence/research/prediction/draft-spec-presence-2026-09-26.json`.

Python `create_market` leaves `spec` unset and the state `DRAFT`. `activate` sets the spec to `draft-spec-presence` and moves the state to `OPEN` in the same call. Resolve is not called on that book.

Solidity stores `resolutionSpecHash` `0x64726166742d737065632d70726573656e636500000000000000000000000000` in the constructor while the state is `DRAFT`. `resolve(YES_WIN)` reverts `BadState`. The state stays `DRAFT`. The result stays `NONE`. Liability stays 0. Collateral locked stays 0. The hash is unchanged. `activate` does not write the hash and then moves the state to `OPEN`.

Classification of that resolve reject stays `existing_rule`. No `YES_WIN` is committed. The constructor, `activate`, and `resolve` were not edited. This is not a theorem pass. MATH-1 stays FAIL. S-P16 stays open.

## Benchmark

Not a gas study. The cited witness records forge gas 230152 for the constructor, the rejected resolve, and the later activate. No separate cost was measured for moving the hash write.

## Security implications

A caller can read `resolutionSpecHash` on a Solidity market that is still `DRAFT`. Python exposes no spec until `activate`, and that call has already left `DRAFT`. The rejected resolve does not commit `YES_WIN` and does not move liability or collateral locked. Editing either write before acceptance would erase the recorded timing. Reclassifying the resolve reject before acceptance would treat a storage-time difference as a committed result the witness does not show.

## Tradeoffs

ADR-P07 keeps the hash as the settlement input and records that the kernel has no setter. It does not decide when the hash is first stored. Matching the write to `activate`, or matching Python to the constructor, requires an edit. Leaving both sides unchanged preserves the witness. The open decision stays open until a human accepts one rule.

## Recommendation

Do not edit the constructor. Do not edit `activate` or `resolve`. Do not reclassify the resolve reject in `draft-spec-presence-2026-09-26.json`. Acceptance is not granted. This ADR does not supersede ADR-P07. The open decision stays open until a human accepts one of the rules above.

## Confidence

High for this draft. The cited witness already recorded the Python activate transition to `OPEN` and the Solidity constructor hash while `DRAFT`, including the rejected resolve. That does not choose which write Phase-1 must keep.

## What would falsify this

A later measurement where Solidity's constructor leaves `resolutionSpecHash` unset while the state is `DRAFT`. Or a later measurement where Python `activate` leaves the state `DRAFT` after assigning `spec`. Or a later `resolve(YES_WIN)` on the hash-present `DRAFT` book that commits `YES_WIN`. Or an explicit acceptance of one rule together with an edit of an implementation. Either result replaces this proposal. Silence does not accept it.

# ADR-P11: Uint256 split domain stays an open choice

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `PredictionMarket.split`, the Python `split` function, `merge`, or any payout formula. Neither implementation may be edited to implement a domain choice until this ADR is explicitly accepted.

No earlier ADR-P record cites this witness. ADR-P06 remains the proposal that Phase-1 collateral is one standard ERC-20. It does not decide whether a split quantity must fit in uint256. This record does not supersede ADR-P06.

## Decision

Propose that the uint256 split disagreement stays recorded and that neither split is edited until a human accepts one domain. The open decision is which domain is authoritative for Phase 1: the Python integer model may exceed `2**256`, or the reference model must reject a quantity that does not fit in uint256. This proposal does not choose that winner and does not change code.

## Options

Leave both splits as measured. Python `split(2**256-1)` then `split(1)` stores `2**256`. Solidity `split(type(uint256).max)` then `split(1)` reverts and leaves the books at `2**256-1`.

Or, after acceptance, make the Python model reject a quantity that does not fit in uint256. That would move the reference model toward the kernel.

Or, after acceptance, treat Python's unbounded integer as the Phase-1 domain and change the kernel. That would move the kernel toward a domain uint256 cannot store. This proposal does not choose that option.

## Evidence

`evidence/research/prediction/uint256-split-2026-09-26.json`.

Python can represent `2**256-1`. `split` of that amount leaves collateral, YES supply, and NO supply at `2**256-1`. A following `split(1)` succeeds and those three figures become `2**256`.

Solidity `split(type(uint256).max)` leaves the same three figures at `2**256-1`. A following `split(1)` reverts `Panic(0x11)`. After the revert those figures stay at `2**256-1` and do not wrap.

Classification `recorded_contradiction`. The contradiction stays open. This is not a theorem pass. MATH-1 stays FAIL. PRED-MATH-1 stays partial. PRED-CONTRACT-1 stays not_pass. Split was not changed. Default profile, forge 1.8.3, solc 0.8.26, optimizer 200, via IR off. The focused test passed 1 and failed 0, gas 711665.

## Benchmark

Not a gas study. The figure above is the recorded test gas for the maximum split and the reverting follow-up. No separate cost was measured for a domain check.

## Security implications

Python records a supply the uint256 kernel cannot store. The measured Solidity follow-up does not wrap YES supply, NO supply, or collateral. The panic rolls the call back and the three figures stay at the maximum. This witness does not show an insolvent mint. Choosing either domain before acceptance would erase one of the two measurements.

## Tradeoffs

Python integers are unbounded, and the current amount check allows `2**256-1` and a later `1`. Solidity `uint256` addition panics instead of wrapping. Matching the kernel requires a Python reject the model does not have. Matching Python requires a storage domain the kernel does not have. Leaving both sides unchanged preserves the witness. The contradiction stays open either way until a human accepts one domain.

## Recommendation

Do not edit `PredictionMarket.sol` or the Python split function. Do not choose a domain winner in code. Acceptance is not granted. The contradiction stays open until a human accepts one of the two domains above.

## Confidence

High for this pair of calls. One Python path and one Solidity path were measured at the maximum and at one unit past it. That does not classify every smaller amount near the bound.

## What would falsify this

A later measurement where Solidity `split(1)` after the maximum wraps a supply or leaves it smaller than `2**256-1`. Or a later measurement where Python `split(1)` reverts and leaves collateral, YES supply, and NO supply at `2**256-1`. Or an explicit acceptance of one domain together with an edit of the other side. Either result replaces this proposal. Silence does not accept it.

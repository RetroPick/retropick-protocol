# ADR-P19: Winner liability and redemption overflow before the uint256 supply limit

**Status:** PROPOSED
**Date:** 2026-09-28

Acceptance is not granted. This finding does not authorize a change to `PredictionMarket.liability`, `_redeem`, `split`, the Python model, or a production contract. ADR-P11's split-addition domain is separate: a **single** accepted split of `2^255` already triggers this finding.

## Decision question

Which integer domain and formula must define winner liability and payout? The current kernel accepts `split(2^255)` from a fully funded standard ERC-20, resolves YES_WIN or NO_WIN, then `liability()` and `openRedemption()` revert with `Panic(0x11)`. The Python oracle reaches REDEEMABLE on the same amount. The first failing supply is `2^255`; `2^255-1` opens redemption.

## Options

1. Accept only total supply at most `floor((2^256-1)/2)`. The bound must be enforced at issuance, including cumulative splits, and copied to the Python oracle. It discards half of the representable supply domain merely to accommodate an intermediate multiply.
2. Use branch-specific arithmetic after result commitment: YES_WIN liability is `yesSupply`, NO_WIN liability is `noSupply`, and winning redemption pays `amount` directly. INVALID retains its checked cumulative half-floor on each side. This retains the full `uint256` supply domain, subject to a separate audit of all remaining additions and token behavior.
3. Leave the present behavior and explicitly mark large fully funded markets as nonredeemable. This contradicts the product's full-collateral redemption promise and is not recommended.

## Evidence and derivation

`evidence/research/prediction/winner-liability-overflow-2026-09-28.json` records the exact boundary and both winner directions. `research/contract-kernels/test/prediction/WinnerLiabilityOverflow.t.sol` has three passing regression tests; two *pass by asserting the economic failure*. `research/prediction-model/tests/test_winner_liability_overflow.py` confirms that Python admits and opens both sides at the same amount.

For supply `C` before any redemption, `liability()` computes `(C * 2) / 2`; the multiplication fits only if `C <= floor(UINT256_MAX/2)`. When `C=2^255`, collateral balance and `collateralLocked` both equal `C`, both outcome supplies equal `C`, and the winning result is already committed. The checked multiply panics. `openRedemption()` calls `liability()`, so the state remains RESOLVED. No holder can redeem in that state. Even if only `liability()` were repaired, `_redeem` evaluates `(redeemed + amount) * 2` for the winner and can panic by the same boundary. A full repair must cover **both** paths. Algebraically, winner liability equals remaining winning supply and each winner payment equals the burned amount, so division and doubling are unnecessary in these branches.

The model's unbounded Python integers are useful to reveal this mismatch but cannot themselves set the Solidity domain. No post-resolution `merge` or other supply-reducing escape exists in the kernel. Donating more collateral does not repair an arithmetic panic.

## Recommendation and qualification

Recommend option 2, subject to human acceptance and a differential boundary campaign at `2^255-1`, `2^255`, `UINT256_MAX`, both winning outcomes, INVALID, partial and full redemption, and rejected-call state preservation. The current evidence is `COUNTEREXAMPLE_FOUND` for winner-redemption liveness in the nominal full `uint256` domain; it is not a claim of token theft or insolvency. Impact is total redemption lock for a reachable but extreme funded quantity. A production implementation must not inherit this expression without an accepted domain/formula decision.

If accepted, update the Python uint256-domain declaration, the research kernel, `docs/prediction/07_ROUNDING.md`, differential fixtures, invariant campaign, and PRED-MATH-1 gate; do not change only the `liability()` check. Compatibility concern: existing resolved markets at the boundary cannot be repaired in-place by a non-upgradeable market; Phase-1 deployment admission must prevent the broken code from being deployed. A later measurement where this exact funded split opens and fully redeems in the unchanged kernel would falsify the finding. Until acceptance, this ADR remains PROPOSED and `PRED-CONTRACT-1` remains NOT PASS.

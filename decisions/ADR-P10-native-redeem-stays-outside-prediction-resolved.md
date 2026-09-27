# ADR-P10: Native redeem stays outside prediction RESOLVED

**Status:** PROPOSED  
**Date:** 2026-09-26

Acceptance is not granted. This file does not authorize an edit to `research/prism-model/native_market.py`, `PredictionMarket.redeem`, the prediction lifecycle table, or the Solidity kernel. Neither redeem function may be edited to implement this recommendation until this ADR is explicitly accepted.

ADR-P04 remains the proposal that prediction RESOLVED and REDEEMABLE stay distinct. ADR-P04 does not cite the resolved-redeem witness and does not say that `native_market.py` must stay unrewritten. This record does not supersede ADR-P04.

## Decision

Propose that the prediction lifecycle keeps RESOLVED and REDEEMABLE separate, that `native_market.py` stays the reduced oracle, and that neither redeem function is edited until acceptance. The native market must not be rewritten to insert REDEEMABLE. The prediction kernel must not redeem inside RESOLVED.

## Options

Leave both functions as measured. `BinaryCompleteSetMarket.redeem` pays inside RESOLVED. `PredictionMarket.redeem` raises until REDEEMABLE.

Or, after acceptance, rewrite `native_market.py` so its redeem waits for a REDEEMABLE state. That would change the reduced oracle. This proposal does not choose that option.

Or, after acceptance, let the prediction kernel redeem inside RESOLVED. That would collapse the lifecycle split. This proposal does not choose that option.

## Evidence

`evidence/research/prediction/resolved-redeem-contradiction-2026-09-26.json`.

`BinaryCompleteSetMarket.redeem("YES", 1)` after `split(4)` and `resolve("YES")` pays 1 while the state stays RESOLVED. Collateral moves from 4 to 3. YES supply moves from 4 to 3. NO supply stays 4. The enum is ACTIVE, RESOLVED, ARCHIVED. There is no REDEEMABLE state.

`PredictionMarket.redeem` on a YES_WIN market in RESOLVED raises `redeem only while REDEEMABLE`. The state stays RESOLVED. Collateral stays 4. YES supply stays 4. `yes_redeemed` stays 0.

Classification `recorded_contradiction`. The contradiction stays open. This is not a theorem pass. MATH-1 stays FAIL. PRED-MATH-1 stays partial. PRED-CONTRACT-1 stays not_pass. Neither function was changed.

## Benchmark

Not a gas study. The witness is one Python regression. No Foundry gas was measured for this proposal.

## Security implications

The two models disagree on when a YES redemption may move collateral. Treating the native pay-inside-RESOLVED behavior as the prediction rule would skip the REDEEMABLE funding gate. Rewriting the native market to match prediction would change a reduced oracle that other PRISM checks still call. Until acceptance, both behaviors stay recorded and neither redeem is edited.

## Tradeoffs

ADR-P04 already proposes the prediction split and says not to treat `native_market.py` as the lifecycle oracle. It does not pin the measured pay of 1 against the measured refusal. Leaving the contradiction open preserves both measurements. Closing it by editing either redeem before acceptance would erase the witness.

## Recommendation

Keep the prediction lifecycle separation. Leave `native_market.py` as the reduced oracle. Do not edit either redeem until this ADR is accepted. Acceptance is not granted. The contradiction stays open.

## Confidence

High for the recorded divergence. One native redeem and one prediction redeem were measured on supply 4. That does not classify every later redemption quantity.

## What would falsify this

A later run of the same witness in which `BinaryCompleteSetMarket.redeem("YES", 1)` no longer pays inside RESOLVED, or `PredictionMarket.redeem` no longer raises `redeem only while REDEEMABLE` and no longer leaves collateral at 4. Or an explicit acceptance of another option, including a named edit to one of the two functions. Silence does not accept this proposal.

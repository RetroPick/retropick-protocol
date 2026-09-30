# ADR-021: Kuru Market Parameter Policy

**Status:** PROPOSED  
**Date:** 2026-09-20  
**Scope:** RetroPick Launchpad V2

## Proposal

RetroPick, not creators, owns validation/derivation of Kuru price/size precision, tick size, min/max size, maker/taker fee, AMM spread and initial liquidity/inventory.

Inputs may come from approved quote configuration, token decimals/supply, graduated reserve ratio and current Kuru-supported bounds.

## Blocker

Do not accept until the target Kuru deployment/API is pinned and representative launch sizes are tested.

## 2026-09-30 candidate packet (status remains PROPOSED)

The [exact profile matrix](../evidence/launchpad/kuru/parameter-profile-matrix-2026-09-30.json) covers five proposed supported launch profiles for each of MON and six-decimal USDC, plus the Factory one-token-supply-floor negative. It derives **terminal tracked token reserve** from original supply using the current Curve formula before applying `B=floor(TQ/(P+Q))`; the older abstract one-million-`T` fixture must not be mistaken for a one-million-token launch. The [real-Router fork fixture](../evidence/launchpad/kuru/fork-deploy-seed-2026-09-30.md) deployed and funded the candidate native and two USDC-symbol markets on block `66752717` and corrected the research oracle's first-bid denominator to `10,000/(10,000+spread)`.

The research-only tuple is size/price precisions `10^8`, tick `1`, min size `10^6`, max size `10^16`, maker `0` bps, taker `30` bps and spread `100` bps. It is **not accepted**. Within the proposed profile envelope, a combined seed-plus-limit-tick cap of 5 bps is recommended: the observed maximum ask tick-floor error is about 1.315 bps and the simple one-tick upper bound is about 2.63 bps at the lowest proposed ask. The cap, profile lower/upper bounds, anti-spam min size, fee/spread choices, exact stable quote address and behavior outside the envelope require explicit human economic acceptance. Complete phase-2 gas, retry and live usability evidence remain open. Any changed tuple or envelope must rerun the matrix and real fork before acceptance.

### Admission correction — trading-history-dependent terminal quote

The [one-shot counterexample](../evidence/launchpad/kuru/prelaunch-q-threshold-counterexample-2026-09-30.md) establishes `Q != threshold`. The independent [ten-round-trip witness](../evidence/launchpad/kuru/prelaunch-round-trip-witness-2026-09-30.md) establishes that `threshold+2` is not a universal replacement: the same launch inputs yield `threshold+22` raw quote units after valid buy/sell history. The token reserve returns to its starting value before the final crossing, so token allocation alone does not determine `Q`. Neither witness proves the complete reachable domain.

The owner decision must therefore choose either a proven all-history admission envelope under existing Core semantics or an explicit accepted Core rule that constrains future trading/reserves. A phase-2 check of actual `Q` remains mandatory but cannot be the **only** qualification: otherwise an already bonded Kuru-bound launch may be permanently unseedable under the proposed no-rescue/no-fallback rule. The [batch decision packet](../development/launchpad/integrations/DEV4_BATCH_OWNER_DECISION_PACKET.md) records options and consequences. Status stays **PROPOSED**.

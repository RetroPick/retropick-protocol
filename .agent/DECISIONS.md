# Working Decisions

Accepted ADRs under `decisions/` are authoritative. This file is the agent-readable summary.

## Locked decisions

- **D-001:** Protocol development is math-first. Production Solidity remains blocked until `MATH-1` and `CONTRACT-ARCH-1`.
- **D-002:** PRISM Metropolis MVP supports non-negative exact replication, not arbitrary nonlinear payoff creation.
- **D-003:** Canonical feasible payoff set is `C = {Gx | x >= 0}`.
- **D-004:** Exact basket mode may supply `x` directly and compute `h=Gx`; payoff mode solves exact `Gx=h, x>=0` or rejects.
- **D-005:** Component-wise backing `B_i >= S*x_i` is the primary runtime active-series invariant.
- **D-006:** Exact replication is established at admission; Solidity mint does not enumerate every terminal world.
- **D-007:** Same-chain Monad backing is authoritative in the PRISM vault/accounting. No Phase-1 `BackingMirror`.
- **D-008:** Native prediction-market creation and PRISM-series creation are separate pipelines.
- **D-009:** Retail PRISM BUY is a secondary Kuru trade; primary PRISM CREATE is separate issuance.
- **D-010:** Backing collateral, LP inventory, market-maker inventory, fees and settlement funds are separate accounting domains.
- **D-011:** `RESOLVED` means final payout known; `REDEEMABLE` additionally requires full settlement funding.
- **D-012:** Canonical `pFEDBTC = 0.6 FED_YES + 0.4 BTC_NO` payoff vector is `[0.4, 0, 1.0, 0.6]` in the documented world order.
- **D-013:** Complete-set open interest does not sum YES+NO. In the simple canonical binary model, OI equals one side/locked collateral quantity.
- **D-014:** Market convergence, liquidity and MM profitability are empirical claims, never solvency invariants.
- **D-015:** Cross-chain wrapped outcomes, custom bridge, BackingMirror, approximate replication and StatePool/SLE are deferred from Phase 1.
- **D-016:** Vendor-derived V2 launchpad baseline established in `contracts/` as experimental foundation. Does not authorize production or supersede math-first gates.

## Escalation rule

If a task needs to contradict any locked decision:
1. stop;
2. identify the changed assumption/evidence;
3. write a new ADR that supersedes the old one;
4. update the reference model/spec;
5. re-run the affected gate.

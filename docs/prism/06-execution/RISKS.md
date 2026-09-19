# Risk Register

Risks are grouped by layer so accounting safety is not mixed with market or delivery uncertainty.

## R1 Protocol solvency risks

### R1.1 Unbacked mint

Failure:
`B_i < S*x_i` becomes reachable.

Severity: critical.

Mitigation:
back-first mint ordering, series-scoped accounting, stateful invariant tests.

### R1.2 Double allocation

Failure:
the same reserved component units satisfy two outstanding liabilities.

Severity: critical.

Mitigation:
series-scoped allocation/accounting; no ambiguous shared `backedSupply` counters.

### R1.3 Over-redemption

Failure:
user receives more than proportional/final entitlement.

Severity: critical.

Mitigation:
liability-first burn, exact reference fixtures, reentrancy-safe transfers.

### R1.4 Underfunded final settlement

Failure:
series becomes `REDEEMABLE` while `SettlementBalance < Supply*FinalPayout`.

Severity: critical.

Mitigation:
separate `RESOLVED` and `REDEEMABLE` states and enforce funding gate.

## R2 Mathematical/model risks

### R2.1 False replicability

Failure:
admission accepts a payoff outside `C={Gx | x>=0}`.

Severity: critical.

Mitigation:
exact arithmetic, deterministic solver semantics, non-replicable fixtures.

### R2.2 Narrative/model drift

Failure:
docs/examples disagree with executable model, such as the historical incorrect pFEDBTC terminal payout.

Severity: high.

Mitigation:
canonical fixtures generated from the model; reconciliation doc; ADRs.

### R2.3 Fixed-point leakage

Failure:
Solidity rounding creates repeatable extraction or underbacking.

Severity: critical/high.

Mitigation:
precision phase before Solidity, round-up backing, explicit dust policy, adversarial repetition tests.

## R3 Resolution risks

### R3.1 Ambiguous event semantics

Failure:
the resolver cannot deterministically decide the outcome.

Severity: critical for market integrity.

Mitigation:
immutable `ResolutionSpec`, source hierarchy, time window, tie/invalid handling.

### R3.2 Resolver outage

Failure:
final settlement delayed.

Impact:
trading/in-kind exit may still be possible; final cash redemption may be blocked.

Do not claim oracle outage leaves all redemption paths unaffected.

### R3.3 Incorrect partial transformation

Failure:
resolved component converted to cash without preserving remaining payoff.

Mitigation:
transformation fixtures and equivalence checks before enabling generic transforms.

## R4 Exchange/microstructure risks

### R4.1 Insufficient Kuru depth

Effect:
large spread/slippage, weak retail UX, wide arbitrage band.

This is a market risk, not protocol insolvency.

### R4.2 Resolution jump / stale orders

Effect:
market makers can be picked off when event information causes discrete repricing.

Mitigation:
MM cancel/requote automation, maturity-aware spreads, explicit demo assumptions.

### R4.3 Arbitrage does not close deviations quickly

Causes:
capital constraints, latency, fees, inventory risk, no active arbitrageur.

Mitigation:
simulation/live evidence; never treat NAV convergence as an invariant.

## R5 Integration risks

### R5.1 Sponsor API assumptions

Failure:
docs rely on invented/changed SDK methods.

Mitigation:
verify current official SDK before implementation. Pseudocode must be labelled pseudocode.

### R5.2 Integration becomes accounting authority

Failure:
Envio/CRE/backend state is treated as canonical backing.

Mitigation:
contract state remains authoritative for same-chain financial accounting.

### R5.3 Cross-chain scope creep

Failure:
custom bridge/custody work consumes hackathon schedule and weakens safety story.

Mitigation:
defer external wrapped outcomes until native system is proven.

## R6 Product risks

### R6.1 Retail flow exposes AP complexity

Failure:
normal user must acquire each component to buy PRISM.

Mitigation:
secondary Kuru BUY is normal retail path; CREATE is advanced/AP path.

### R6.2 Product becomes bounty checklist

Failure:
integrations distort core architecture.

Mitigation:
P0 product path first; cut P1/P2 integrations before financial correctness.

## R7 Legal/operational uncertainty

Prediction-market treatment depends on jurisdiction and product structure.

Repository docs must not infer exemptions, KYC sufficiency, or legal identity from passkeys.

Hackathon posture:
- curated market launch policy;
- prohibited-category policy;
- immutable resolution definitions;
- jurisdiction-specific production review before real-money launch.

## R8 Delivery risk

The largest schedule risk is implementing Solidity/integrations before MATH-1 closes and then rewriting them after discovering accounting/precision defects.

Mitigation:
phase gates are mandatory. Parallel work may use mocks/interfaces but cannot define financial semantics ahead of the canonical model.

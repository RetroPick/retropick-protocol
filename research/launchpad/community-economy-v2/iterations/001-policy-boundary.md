# Iteration 001 — rights reproductions and noncustodial policy boundary

Question: can delayed future policy be expressed without rewriting historical policy or introducing custody?
Hypothesis: immutable bounds, one pending nonce and a fixed checkpoint dependency can enforce policy lifecycle, while actual accrued-right protection remains an integration proof.
Source evidence: canonical Factory recipient handoff, Curve aggregate fee buckets and BuybackVault mutable beneficiary. BaselineRightsConflict.t.sol explicitly imports canonical reference fixtures to demonstrate those intended authorities; these are not new exploits.
Formal properties: exact BPS total, bounded creator/treasury allocations, immutable dependencies, monotone history, no replay, failed checkpoint atomicity, and no stale-controller activation.
Decision: implement and test registry-only boundary. Do not claim source checkpoint correctness from a mock. Full G0/G1/G2 and M2–M9 remain pending.

# Iteration003 current state
Base fetched main6d9ac546d856f021d9e597f6e625a134b8ab8bcd. Isolated branch research/community-treasury-v2-20261102, worktree /tmp/retropick-community-treasury-v2-20261102. Original checkout three untracked input paths preserved. V3 reference only. No source drift in canonicalV1/V2, originaltests, V3 or existing CEcore.

Fresh source-scoped financial33tests PASS; three10000caseproperties, stateful256x128=32768calls, seed0xce02. New real-controller6tests PASS including10000cases at0xce03. Fresh source-only build and compiler identity gate PASS: Factory24486B, curve13805B, router6487B; historicalheadroom90B remains measured. Four protection checker regression tests pass.

Canonical frozen-source reference materialized from28a4744 using git archive, libs linked to current pinned dependencies. Failed setup attempts omitted remappings and imported deployscript; preserved logs. Final canonical local run64PASS/0FAIL/10fork skips; no fork PASS. No missing-RPC test counts as pass; fork unavailable.

G1 exact candidate owner-accepted research-only; independent review discovered G2 unique-binding flaw. Gate cannot advance to custody based on owner approval alone. See CE003-001. No financial implementation/import before correction. New helper-precondition test is source-risk reproduction, not a deployed exploit proof.

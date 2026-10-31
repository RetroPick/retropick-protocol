# Remaining-work ledger

Overall status: PARTIAL. No community module is implemented. This is the handoff ledger required by the campaign, not a replacement for Beads when an active Beads workspace becomes available.

| Order | Work | Acceptance / dependency |
|---|---|---|
| 1 | Finish Phase 0 manual review | Compiler ABI reconciliation; exhaustive powers/assets/transitions/math inventory; current test coverage classification; independent source review |
| 2 | Demand and competitor evidence | Resolve report citations into dated primary sources; compare Pump.fun/Zora and original Reddit anecdotes without population claims |
| 3 | Adversarial grill | All requested questions, severities, preconditions and reproducible tests; separate demonstrated defects from hypotheses |
| 4 | Accounting spec and candidate ADRs | Immutable bounds; settlement checkpoint completeness; frozen trader rates; all BPS denominators; old-right preservation |
| 5 | Policy registry and router | Accrued assets settle to old epoch atomically; authentic actual funding; bounded allocation; no rescue/admin bypass |
| 6 | Splitter, treasury, rewards | Independent claims; transfer-only treasury timelock; fixed-period rewards with bounded checkpoint work and no dust-extension attack |
| 7 | Controller/recovery | Accepted three-day handoff, seven-day guardian recovery; explicit cancellation/priority; no accrued-right confiscation |
| 8 | Buyback adapters | Allocation isolation, valid authorization, five-year vest/burn/treasury custody, independent price reference and MEV guards |
| 9 | Venue integrations | Supported curve/v4 only; Kuru rights BLOCKED_EXTERNAL_CAPABILITY; no LP withdrawal escape |
| 10 | Qualification and simulations | LP-I-001–012 / CE-I-001–018, differential tests, 10k fuzz cases, 256×128 invariant campaign, gas/size/static analysis, four archetypes |
| 11 | Final package | All fifteen requested artifacts, complete architecture diagrams, A–J status report and explicit blockers |

Do not promote any component before its dependencies pass. Do not alter canonical sources or historical evidence to make tests green. Keep research outputs labeled as proposed, measured, inferred or blocked.

Resolved at this checkpoint: canonical graduation artifact selection. Use --contracts src/v2 with a fresh output/cache directory, rather than --skip v2-research-experiment. Full canonical-suite reproduction remains pending.

## Iteration 001 progress

Two new canonical-reference tests reproduce unswept-fee and unreleased-vest redirection. Noncustodial CommunityPolicyRegistryV2 prototype and dedicated tests now exist. Full G0/G1/G2 remain open; this is not passed M1. Next: complete source authority evidence and real checkpoint design/adversarial tests before enabling any fee routing. Resolve category-cap disclosure and qualify module implementations. M2–M9 remain pending.

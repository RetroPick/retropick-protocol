# Remaining-work ledger

## Current dependency after iteration 002

The older baseline/M1 queue below is historical. A real experimental factory/curve/router/controller vertical slice now exists; independent multi-recipient claims are integrated in the router rather than a second custody contract. See qualification evidence and invariant map for actual scope. Full G0/G1/G2 and M9 are not closed by a curve-only result.

Next executable development unit: qualify a treasury-only timelock module and wire the fixed treasury recipient to that module in new test launches. The vendored OpenZeppelin subset lacks governance/TimelockController and AccessControl; importing a pinned, license-verified dependency subset requires an explicitly scoped dependency/ADR change before that implementation. Do not substitute an unaudited timelock merely to claim M4 complete. Current EOA treasury makes no timelock promise.

Before later custody: complete controller recovery priority/cancellation/deadline sequences, a full old-beneficiary ghost ledger, policy-boundary fuzz, long-history gas, and all LP/CE property gaps listed in INVARIANT_TEST_MAP.md. Then real-fee-funded rewards with no-staker/late-staker handling, buybacks with independent execution bounds, actual venue adapters and fork qualification. Keep legacy buyback off in CE mode; unexecuted budgets retain their published beneficiary. Kuru remains BLOCKED_EXTERNAL_CAPABILITY. Factory runtime headroom is only 90 bytes; move future deployment work to helpers.

Remaining research: source-backed demand/competitor matrix, complete product grill, calibrated four-archetype simulations, deployed venue identity/rights, and independent external audit. Current deterministic scenarios are illustrative, not economic qualification. No deployment is authorized.

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

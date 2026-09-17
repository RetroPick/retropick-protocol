# Agent Workflow

Canonical hackathon-wide workflow:
`docs/05-hackathon/RETROPICK_METROPOLIS_AGENT_DEVELOPMENT_WORKFLOW.md`.

Phase 1 narrows that workflow to:

```text
DISCOVER
  -> DEFINE
  -> SPEC
  -> MODEL
  -> FALSIFY
  -> PROVE / EXHAUST
  -> DERIVE CONTRACT REQUIREMENTS
  -> MATH-1 GATE
```

Only after MATH-1:

```text
CONTRACT DESIGN
  -> SOLIDITY
  -> DIFFERENTIAL TESTS
  -> INVARIANT TESTS
  -> INTEGRATIONS
  -> DEPLOY
  -> EVIDENCE
```

## Per-goal execution

1. Read `CURRENT_GOAL.md`.
2. Inspect source-of-truth docs.
3. Check accepted ADRs.
4. Define assumptions and acceptance criteria.
5. Implement within owned files.
6. Run tests.
7. Write evidence.
8. Record architecture changes.
9. Handoff or close only when acceptance criteria pass.

## Anti-patterns

- implementation-first protocol design;
- silently changing payoff semantics;
- calling simulation a proof;
- marking a sponsor integration complete without live evidence;
- treating exchange liquidity as automatic;
- mixing backing collateral and trading capital.

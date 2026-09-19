# RetroPick Agent Bootstrap

All engineering agents, regardless of harness, use the shared control plane under:

```text
.agent/
```

Read [`AGENT_GUIDE.md`](AGENT_GUIDE.md) first for the repository map and authority model.

Then read, in order:

1. `.agent/README.md`
2. `.agent/STATE.json`
3. `.agent/CURRENT_GOAL.md`
4. `.agent/ROUTING.md`
5. relevant files under `.agent/steering/`
6. the canonical product/protocol docs for your task
7. the relevant `development/` implementation lane
8. the nearest local `AGENTS.md`, if present
9. relevant accepted/proposed ADRs

Do not read or modify unrelated product lanes by default.

## Products

- Launchpad V2: `docs/launchpad/` + `development/launchpad/`
- Prediction + PRISM: `docs/prism/` + `research/prism-model/`

## Global rules

- accepted ADRs and canonical specs outrank implementation;
- code does not silently redefine protocol semantics;
- backend/indexer are not economic authority;
- normal user economic writes are wallet -> chain;
- onchain integer values use exact integer/bigint representations;
- external mutable integrations require current-source verification;
- every completed task requires verification, evidence and explicit handoff where applicable;
- no agent may self-authorize unrestricted mainnet deployment.

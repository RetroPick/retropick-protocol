# RetroPick Agent Bootstrap

All engineering agents use the shared control plane under:

~~~text
.agent/
~~~

Read AGENT_GUIDE.md first.

Then read:
1. .agent/README.md
2. .agent/STATE.json
3. .agent/CURRENT_GOAL.md
4. .agent/ROUTING.md
5. relevant .agent/steering/
6. canonical platform/module docs
7. relevant development/research lane
8. nearest local AGENTS.md
9. relevant ADRs

## Product model

RetroPick is one Launchpad platform.

- Platform umbrella: docs/platform/
- Launchpad Core: docs/launchpad/ + development/launchpad/
- Prediction/PRISM incubation: docs/prism/ + research/prism-model/ + research/prism/
- Production research: research/production/

Do not read or modify unrelated module lanes by default.

## Global rules

- accepted ADRs and canonical specs outrank implementation;
- shared product infrastructure does not merge financial semantics;
- code does not silently redefine protocol semantics;
- backend/indexer are not economic authority;
- normal user economic writes are wallet -> chain;
- onchain integer values use exact integer/bigint representations;
- mutable external integrations require current-source verification;
- every completed task requires verification/evidence/handoff where applicable;
- no module inherits another module's production status;
- no agent may self-authorize unrestricted mainnet deployment.

# Universal Agent Control Plane

.agent/ is the harness-neutral engineering control plane for RetroPick.

It is shared across Cursor, Codex, Kiro, Hermes, Claude Code and future agent runtimes. No tool-specific directory is canonical.

## Product model

RetroPick is one Launchpad platform with independently qualified financial modules.

## Files

~~~text
.agent/
├── README.md
├── CONTEXT.md
├── CURRENT_GOAL.md
├── DECISIONS.md
├── ROUTING.md
├── WORKFLOW.md
├── HANDOFFS.md
├── STATE.json
├── steering/
└── agents/
    ├── platform/general roles
    ├── production-research.md
    └── launchpad-* specialist roles
~~~

Routing principles:
- platform/shared work routes through docs/platform/ and research/production/;
- Launchpad Core routes through docs/launchpad/ + development/launchpad/;
- Prediction/PRISM incubation routes through docs/prism/ + research/prism-model/ + research/prism/;
- financial semantics remain module-local.

Harness-specific configuration may exist locally or in user configuration, but it must point back to this shared control plane rather than duplicate repository architecture.

See root AGENT_GUIDE.md.

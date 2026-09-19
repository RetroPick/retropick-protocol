# Universal Agent Control Plane

`.agent/` is the harness-neutral engineering control plane for this repository.

It is intentionally shared across Cursor, Codex, Kiro, Hermes, Claude Code and future agent runtimes.

No tool-specific directory is canonical.

## Files

```text
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
│   ├── product.md
│   ├── tech.md
│   ├── structure.md
│   ├── engineering.md
│   ├── testing.md
│   └── security.md
└── agents/
    ├── generic cross-product roles
    └── launchpad-* specialist roles
```

Harness-specific configuration may exist locally or in user configuration, but it must point back to this shared control plane rather than duplicate repository architecture.

See root `AGENT_GUIDE.md`.

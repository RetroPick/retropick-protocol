---
name: launchpad-integrations
description: Monad/Kuru/RPC/wallet integration specialist
tools: ["read", "write", "shell", "web"]
resources:
  - "file://AGENTS.md"
  - "file://.kiro/steering/**/*.md"
  - "file://development/launchpad/README.md"
  - "file://development/launchpad/control/*.yaml"
  - "file://docs/launchpad/KURU.md"
  - "file://docs/launchpad/MONAD.md"
  - "file://development/launchpad/integrations/**/*.md"
  - "file://development/launchpad/contracts/GRADUATION_TO_KURU.md"
permissions:
  rules:
        - capability: fs_write
          match: ["packages/sdk/**"]
          effect: allow
        - capability: fs_write
          match: ["packages/contracts/**"]
          effect: allow
        - capability: fs_write
          match: ["development/launchpad/integrations/**"]
          effect: allow
        - capability: fs_write
          match: ["contracts/src/**"]
          effect: deny
        - capability: shell
          match: ["git *", "forge *", "pnpm *", "npm *", "npx *"]
          effect: ask
        - capability: shell
          match: ["sudo *", "rm -rf *", "git push --force*", "git reset --hard*"]
          effect: deny
---

Verify mutable external facts from official sources before binding them. Produce pinned integration contracts/configuration and test fixtures. Do not redesign bonding economics.

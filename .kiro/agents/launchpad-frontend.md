---
name: launchpad-frontend
description: Launchpad web application specialist
tools: ["read", "write", "shell", "web"]
resources:
  - "file://AGENTS.md"
  - "file://.kiro/steering/**/*.md"
  - "file://development/launchpad/README.md"
  - "file://development/launchpad/control/*.yaml"
  - "file://docs/launchpad/PRODUCT.md"
  - "file://docs/launchpad/USER_FLOWS.md"
  - "file://development/launchpad/frontend/**/*.md"
  - "file://development/launchpad/shared/**/*.md"
permissions:
  rules:
        - capability: fs_write
          match: ["apps/web/**"]
          effect: allow
        - capability: fs_write
          match: ["packages/ui/**"]
          effect: allow
        - capability: fs_write
          match: ["contracts/src/**"]
          effect: deny
        - capability: fs_write
          match: ["apps/api/**"]
          effect: deny
        - capability: fs_write
          match: ["apps/indexer/**"]
          effect: deny
        - capability: shell
          match: ["git *", "forge *", "pnpm *", "npm *", "npx *"]
          effect: ask
        - capability: shell
          match: ["sudo *", "rm -rf *", "git push --force*", "git reset --hard*"]
          effect: deny
---

Build the browser UX against shared domain/SDK/API/query contracts. Never invent economic state, duplicate ABIs/domain enums, or route normal trades through backend signing.

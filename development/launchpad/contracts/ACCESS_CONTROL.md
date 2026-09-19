---
id: LP-SC-ACL
type: normative_implementation
status: ready
owner: launchpad-solidity
product: launchpad
version: v2
---

# Access Control

Document every privileged capability by role.

Minimum roles/capabilities to review:
- factory owner: launch config, fee ceilings/policy, quote admission, helper wiring, recovery proposals;
- creator fee recipient: creator-specific recipient/controller functions explicitly granted;
- graduation caller: permissionless or restricted as actually implemented;
- deployer/factory helpers: factory-only wiring;
- recovery recipient/owner: delayed rescue only under accepted conditions.

Rules:
- no role may mint unbacked launch tokens;
- no role may seize active curve reserves outside explicit recovery;
- ownership transfer is explicit/two-step where supported;
- production role addresses come from environment manifest, not prose.

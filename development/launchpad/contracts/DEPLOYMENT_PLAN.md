---
id: LP-SC-DEPLOY
type: normative_implementation
status: ready
owner: launchpad-devops
product: launchpad
version: v2
---

# Contract Deployment Plan

Deployment order is derived from actual constructors after the Kuru architecture is accepted.

Every deployment records:
- source commit and forge profile;
- constructor args;
- CREATE2 salt/predictions where applicable;
- deployer and owner/admin roles;
- transaction hashes;
- runtime code hashes;
- quote-asset/Kuru policy configuration;
- post-deploy smoke tests.

Do not reuse V4 deployment wiring for Kuru by assumption.

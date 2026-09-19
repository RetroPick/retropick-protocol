---
id: LP-CODE-DEPLOY
type: generated_current_state
product: launchpad
version: v2
status: active
source: contracts/src/v2
---

# Current Deployment Reference

The current V2 Factory constructor requires V4-specific dependencies including PoolManager, PositionManager, Permit2, locker, hook, fee escrow and buyback vault, then wires graduation executor/deployer/forwarder helpers.

Therefore:
- current V2 deployment recipe is not the final Kuru deployment recipe;
- do not publish Kuru addresses/config into current V4 constructor documentation;
- target deployment order must be regenerated from the accepted Kuru architecture;
- every environment records source commit, constructor args, deployer/owner roles, tx hashes, code hashes and post-deploy configuration.

Generated environment/deployment manifests will eventually be consumed by packages/contracts/config and indexer/web runtimes.

# Contract Deployment

**Status:** DRAFT  
**Owner:** Smart Contracts + Release

Deployment order must be derived from actual V2 constructor/runtime dependencies before LP-DEPLOY-1. Expected categories are shared libraries/infrastructure, fee/buyback components, graduation components, factory/deployer, configuration and Kuru integration.

Record for each deployed component:
- source commit/build profile;
- constructor arguments;
- CREATE2 salt/predicted address where used;
- deployer;
- owner/admin/fee/recovery roles;
- transaction hash;
- runtime code hash;
- post-deploy configuration;
- verification status;
- smoke test.

Never infer production readiness from a successful deployment alone.

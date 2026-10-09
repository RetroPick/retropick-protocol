# Metropolis qualification evidence

This folder records the current repository campaign independently of historical deployed V2 evidence.

Fresh campaign: **145 passed, 0 failed, 0 skipped**, fork **69,549,163**. `format.log`, `oracle.log`, `tests.log`, `sizes.log`, `runtime-sizes.log` all passed; dependencies were built separately. Factory runtime **23,423**, Coordinator **14,026**, Kuru executor **16,457** bytes. `qualification.json` includes all deployable size gates and independent canonical custody/residual checks. Initial campaign ran with uncommitted formatting/frontend/docs changes; the report explicitly records that limitation. Final release/tag requires committed-source confirmation.

Canonical live state was re-read at block **69,550,941**: GRADUATED, ledger conserved, protected balances matched, Coordinator native quote balance/liability zero, executor unexplained assets and vault allowances zero. `environment.json` records Router/Margin/code/public getter/proxy identities; historical deployment evidence remains unchanged.

Frontend source candidate: `030ab8794688f99f4b8cda336d9f6160b485eebd`. Typecheck, production build, 20 tests, changed-file ESLint and 21st review passed. Browser reads showed real canonical GRADUATED state, protected balances and Kuru best bid/ask. These reads do **not** establish a full wallet E2E run. Public deployment and wallet checks are recorded separately in `frontend-release.json`.

Reproduce contract campaign without modifying historical manifests:

```sh
python3 contracts/script/qualify_metropolis.py --env-file /path/to/authorized-external.env
```

The runner never broadcasts. RPC is mandatory; zero failures and zero skips are required. Keys remain external. Original V2 candidate: `../../launchpad/v2-monad-testnet/`; source SHA `f0363249f4b74e58dde37d1241742ca5a92bcfe3`. No audit/mainnet claim.

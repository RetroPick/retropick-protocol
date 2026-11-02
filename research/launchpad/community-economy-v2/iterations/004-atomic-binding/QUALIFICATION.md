# Iteration 004 qualification

Status: PARTIAL / EXPERIMENTAL LOCAL EVIDENCE. Canonical V2, V1, V3, deployment manifests and historical evidence unchanged. No deployment, broadcast, live multisig qualification or external audit. Base origin/main is `7bad742b67e2fa58ebf680eadbfa6194d5bbf0c3`.

## Implementation and gates

| Gate | Result | Boundary |
|---|---|---|
| G0 source/security reconciliation | PARTIAL | Prior financial authority findings retained; new source/ABI/size identities measured; no full external audit |
| G1 treasury architecture | COMPLETE for selected experimental scope | Atomic actual-address binding replaces unsafe counterfactual finalizer; independent read-only amended-spec/source review |
| G2 custody/governance specification | COMPLETE for selected experimental scope | Immutable Router/token/asset identity, earned-fund-only accounting, fixed72h delay, inclusive7day window; ADR-CE02 owner-accepted for scoped canonical implementation subject to qualification |
| G3 experimental implementation | IMPLEMENTED / TESTED | Real TreasuryLaunchBuilder, Deployer, Vault and pinned-OZ Timelock; no added Factory runtime code |
| G4 adversarial local qualification | PARTIAL | Unit/fuzz/native stateful coverage passes; actual multisig, fork, full treasury graduation lifecycle and further static/audit review remain |
| Canonical development | AUTHORIZED / PENDING IMPLEMENTATION | Owner explicitly accepted ADR-CE02 for canonical implementation subject to qualification; no release/deployment approval |

CE003-001's shared-destination mechanism is resolved in the new atomic implementation: two launches by the same creator create distinct real Vaults, Timelocks and Routers. Actual constructor failure and later Registry rejection revert all deployment nonces/maps/code; retry creates the correct modules and earns/claims real fees. This is not a statement about deployed historical contracts. Binding-probe tests remain separately labeled noncustodial seams.

## Tests

`combined-tests.log`: 84 PASS, 0 FAIL, 0 SKIP across12suites, including prior financial/Registry/controller/binding regression, eight new binding tests,22governance tests,13treasury integration tests and the treasury stateful property. `treasury-final-tests.log`:17PASS/0FAIL/0SKIP, comprising16unit/integration tests and1stateful property; the three additional cases test one-unit MON/USDC spending, invalid spend fields and batch rollback. **87 distinct tests** across these overlapping runs; do not add84+17. Latest treasury source/tests are covered by its final run.

The combined campaign ran eight targeted fuzz properties at10,000cases each, seed`0xce04` (80,000cases). Two stateful properties each ran256runs×128depth=32,768calls, zero outer handler reverts (65,536calls total). Caught economic failures are distinct from outer reverts. These are bounded local campaigns, not proofs over all histories or complete LP/CE closure.

Final treasury handler distribution: claim4130, claimOther3964, donate4121, execute4084, schedule4124, settle4106, trade4076, unauthorized4163. All8selectors exercised. Deterministic seeding ensures successful real trades/claims/spends and rejected payout/unauthorized branches are reached. Final sequence snapshot, including seed:16successful trades,18settlements,11treasury claims,11other claims,24schedules,6successful executions,12caught failed executions,20donations,19unauthorized attempts. This snapshot is not aggregate campaign success totals. Native-only stateful scope; USDC has scenario/negative tests, not a separate stateful campaign.

Real MON and locally modeled approved-address six-decimal USDC flows execute experimental buy/sell, settle protocol escrow/community Router, independently claim contributor and Treasury credit, then schedule and execute Treasury spending. Policy/controller transitions preserve old credits and do not transfer governance. Tests cover wrong authority/duplicate deployment, constructor/lateRegistry rollback, canceled/expired/replayed operations, failed recipient, reentry, false/inexact transfer and issuer balance destruction. Unsupported assets fail closed; negative balances are not insured. No fork PASS is claimed.

## Accounting evidence

For each immutable quote asset, `claimed = spent + held`, physical balance covers held, and Router funded income reconciles paid+liability. Vault receipt extinguishes its corresponding Router credit exactly once. Donations increase surplus without creating earned rights. New claims cannot hide an existing deficit. Both native and exact-transfer token payouts reconcile balances. No controller, owner rescue, generic Vault call or surplus spending path exists. Existing curve reserves/math and protocol entitlement paths are unchanged.

## Sizes and tooling

Solidity0.8.26, Cancun, optimizer200, viaIR; test chain10143. Source-only build exit0 with metadata targets verified. Runtime bytes: Vault4606; TreasuryDeployer16453; Timelock5842; TreasuryLaunchBuilder20644; existing Factory24486; existing Router6487. All measured deployable runtimes satisfy EIP170; Factory retains90bytes headroom. Creation sizes and source targets recorded in final-artifact-sizes.json; all new initcodes plus fixed constructor arguments satisfy EIP3860. Harness size allowance is not a deployment size waiver.

Global `forge fmt --check` passes. Exact upstream dependency bytes are preserved using one version-specific formatter exclusion; compiler/remappings are unchanged. Baseline checker and its4regression tests pass. All12approved OZ5.4.0 source hashes/license were revalidated; upstream advisory inventory/dispositions retained.

Governance Slither:26findings; Vault/transitive Slither:75findings; exit255 indicates findings, not clean analysis. Semgrep:2governance and10treasury INFO/performance findings, zero parse errors. Raw results and contextual dispositions retained. New high reentrancy-balance labels correspond to guarded exact post-call checks exercised by callback/rollback tests; no demonstrated exploit. Transitive medium/low findings are not all externally closed. Static analysis and internal review are not an audit. Extended scan raw logs survived a worker limit; exact extended invocation was not fully handed off, a reproducibility limitation. Core build/test commands are recorded separately.

## Remaining release blockers

A separate qualified canonical promotion diff under the now-accepted ADR-CE02; full relevant canonical regression/ABI/event qualification after promotion; actual community multisig identity/threshold and operational policy; real Monad fork with verified deployments; treasury across complete graduation destination/retry lifecycle; USDC stateful extension; complete independent detector/audit closure; long-history and deployment gas qualification. Lost final proposer can permanently stop new scheduling. Donations remain intentionally stranded surplus. No emergency bypass exists.

Kuru continuous community revenue remains BLOCKED_EXTERNAL_CAPABILITY. Existing Uniswap v4 community registration disables unsupported hook/creator revenue; no new pool/hook right is claimed. Product retention, sustainable low-volume economics and reward/buyback value remain unproven; this iteration proves bounded fee custody/governance behavior, not yield or market demand. Rewards/buybacks remain deferred.

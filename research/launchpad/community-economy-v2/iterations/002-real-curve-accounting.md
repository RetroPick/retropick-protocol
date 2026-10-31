# Iteration 002 — scoped curve accounting authority

Scope: opt-in native MON and chain-10143 Circle-address six-decimal exact-transfer quotes. Canonical code remains read-only. G0/G1/G2 are resolved for this narrowly defined implementation boundary by prior compiler reconciliation, canonical rights reproducers and the explicit decisions below; broader venue/strategy gates remain open.

## Financial authority
Factory authenticates the new token/curve record; owner wires a builder once, prospective launches only. Curve holds trading reserves and accumulated F/T; only its code can fund its bound router. Existing protocol escrow owns protocol claim custody. Per-launch router holds community liabilities and has no owner rescue. Registry owns policy history; controller owns only bounded future administration. Real controller generation changes cannot change credits. GraduationCoordinator owns secured reserves, never community claims. Token creator attribution remains unchanged.

## Equations and integer vectors
Each buy fee uses actual spent quote (after clamp/refund), sell fee uses gross output: F_i=floor(gross_i*baseBps/10000), T_i=floor(gross_i*taxBps/10000). Aggregate pending F/T retain existing arithmetic. On settlement P=floor(F*protocolShareBps/10000); C=F-P+T. Protocol credit remains in original escrow; only pre-separated C enters router. Legacy source buyback is forbidden in CE mode. New strategy budgets remain ordinary fixed module credits, not executed here.

Vectors at base=100bps, tax=50bps, protocol share=3000bps: MON gross=1e18 => F=1e16,T=5e15,P=3e15,C=12e15; USDC gross=1e6 => F=10000,T=5000,P=3000,C=12000. With 60/40 split: MON creator=72e14,treasury=48e14; USDC creator=7200,treasury=4800. At F=1,T=0 => P=0,C=1; floored allocation residual goes to fixed treasury. No additional trader fee or second protocol share.

## Fee state machine
UNWIRED -> atomically factory-created WIRED (no prior trade, fee or buyback) -> ACCRUING -> SETTLING -> FUNDED/CREDITED -> PARTIALLY_CLAIMED -> CLAIMED. Settlement sequence advances only on a funded transfer. Router verifies fixed curve/token/asset, epoch, next sequence and exact funding. Curve clears fee state and decrements trackedQuote before funding; failure reverts all effects. Real reserves exclude F/T before and after settlement. Donations are unaccounted surplus, never attributed income.

Policy: PROPOSED -> DELAYED -> checkpoint old epoch -> ACTIVATED; failure leaves proposal and old liabilities unchanged. Router checkpoint itself has no shared deposit guard; the curve always enters its trade guard and router funding has its own guard. Thus funding callbacks are allowed while activation callbacks into a trading source fail. Only registry can checkpoint; anyone may request ordinary quote-only settlement. No operator dependence or conversion in this slice.

Per router/asset identity: totalFunded = totalPaid + totalLiability. Physical balance >= totalLiability. Every claim debits the original beneficiary credit first; controller/policy updates cannot rewrite it. Failed payout restores credit. Independent direct pull claims avoid duplicating escrow liabilities; protocol escrow remains separate. Source graduation sweeps community fees first and hands only net real reserves to coordinator. After graduation router claims and empty curve checkpoints continue; CE v4 pool fees are BLOCKED pending a separate adapter and protected from legacy redirection.

Factory uses existing deployer, then a separate builder deploys controller/router/registry and seals router binding. Factory seals curve binding before return. Configure rejects any prior tracked reserve/fee or buyback activity; any reentry from launch-fee payment forces full rollback, never partial launch. Caller pins normal economics and builder/config commitment. No circular public initialization, no mutable source override.

Declared creator-category caps do not identify beneficial ownership. Treasury is a disclosed recipient in this slice, not a timelocked treasury vault. No rewards/buyback execution or continuous venue revenue claim is made.

## Completed implementation and decision

Implemented real factory-bound builder/controller/registry/router and experimental curve settlement; new CE launches explicitly select v4, whose unsupported community hook fee path is disabled. Independent claims implement bounded splitter behavior without a second custody ledger. See candidate ADR-CE01, PROPOSED only.

Final results: combined slice 22 passed/0 failed/0 skipped; separate registry 11 passed/0 failed/0 skipped; 30,000 fuzz cases across three properties; integrated stateful property 256×128=32,768 calls. Source-only runtime gate, global formatting and four protection regressions pass. Frozen canonical local run: 64 passed/0 failed/10 fork skips, after a full reference run retained two missing-RPC setup failures. No deployed or fork evidence.

Preserved failed attempts: builder interface compile error; callback-prank fixture error; broad run artifact ambiguity and inherited seeded-fixture unit assertions; Foundry static importer missing output JSON. Fixed test scaffolding by separating abstract reusable fixture from test contracts; no financial semantics were changed to make tests pass. Direct-solc Slither completed with 49 individually triaged results; Semgrep 123 performance suggestions. Source identities and raw commands/results are in evidence/launchpad/community-economy-v2/2026-10-31-authenticated-curve/.

Decision: locally validated experimental curve slice, full campaign PARTIAL and production promotion BLOCKED. Next dependency is a qualified timelocked treasury module using pinned approved primitives; vendored subset currently lacks the governance/access-control implementations. Controller races, full temporal ghost ledger, maximum-history/recipient gas, rewards/strategies and actual venue rights/forks remain explicitly open.

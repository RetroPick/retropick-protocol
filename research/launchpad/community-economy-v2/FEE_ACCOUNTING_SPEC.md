# Candidate accounting specification

## Iteration 002 — implemented curve boundary

The earlier M1-only discussion below is historical context, superseded for the experimental curve path by iterations/002-real-curve-accounting.md and V2_EXPERIMENT_ARCHITECTURE.md. Candidate ADR-CE01 remains PROPOSED. Broader G0/G1/G2, venue conversion and production economics authority are not declared complete.

Entitlement accrues on each successful actual trade as F_i/T_i in the curve. These buckets can aggregate while the policy remains unchanged. The router receives only pre-separated C=F-floor(F*protocolShareBps/10000)+T; protocol P settles once to the original escrow. Trade fee BPS and allocation BPS are different denominators. Quote reserves exclude F/T both before and after settlement.

Allocation at a settlement floors each bounded recipient share and credits all residual to the immutable treasury recipient. Claiming has no rounding. This preserves existing aggregate protocol rounding; it does not round protocol share separately for each trade. Every policy activation calls the real router checkpoint, which calls the immutable factory-registered curve under its operation guard, including apparent zero-pending states. It funds old epoch credits, then requires actual source pending zero. Any asset-transfer failure, controller-generation change or incomplete checkpoint reverts activation and all transfers. No arbitrary actor sets pending to zero.

Source/launch/asset/epoch/sequence are validated; sequence advances only for nonzero funded settlements. Native msg.value must exactly match amount. ERC-20 sender and receiver deltas must exactly match. A donated surplus creates no attributed revenue or claim. Per-launch physical backing is checked before and after allocation/claim. Negative rebases fail closed; they are unsupported, not insured. There is no owner rescue, cross-launch subsidy or router-to-community-escrow duplication.

Per asset: totalFunded=totalPaid+totalLiability; sum(original beneficiary credits)=totalLiability; balance>=totalLiability. totalFunded counts C only; P belongs to the separate protocol ledger. Pending source C is explicit unsettled allocation until funded; a funded claim remains payable after graduation or controller rotation. Zero pending settlement is a no-op, not a new settlement ID. Independent partial claims and claimTo retain claimant ownership. Failed recipient code rolls back only that transaction. No-staker/reward/strategy execution is outside this slice; unused earmarks cannot be redirected by a router owner because no such role exists.

Factory seals CE mode and authentic source identity before returning launch. Creator administrative legacy paths cannot redirect CE funds. Operator downtime does not stop permissionless settlement or claims. Graduation first settles F/T and secures only net reserves. Subsequent empty settlement and outstanding claims continue; no unsupported venue revenue is invented.

## Historical M1 boundary

PROPOSED. Registry-only implementation is noncustodial; it does not close the full-system G2 gate or authorize a fee router integration.

For supported exact-transfer quote assets, F is accumulated base fees, T accumulated creator tax, P=floor(F*protocolShareBps/10000), C=F-P+T. Protocol arithmetic and fee bases remain unchanged. Community mode will disable source legacy buyback earmarking; buyback budgets are allocated exactly once from C. Donations, launch fees and graduation residuals are separate from trading revenue.

For each asset: authenticated received = paid + outstanding claims + assigned rounding balances. A source transfer reduces its liability only when exact delivery succeeds. Router-to-escrow movement must reduce router liability while increasing escrow liability; never count both as income.

Selected future integration: atomic old-policy checkpoint. Before changing epoch, enter source operation guards even when buckets appear zero, settle all current curve or registered pool buckets, and require zero remaining base/tax/buyback/conversion amounts. Failures roll back the entire activation. Fixed source adapter must preserve old policy during deposits and reject activation during accrual. The registry cannot independently prove that an arbitrary adapter is truthful: construction/wiring and real-source tests are mandatory integration gates.

M1 policy: at most ten unique nonzero beneficiaries, positive BPS totaling 10000, aggregate creator cap, fixed treasury floor, launch-fixed module addresses for strategy categories. Fee rate is immutable and bounded at construction. One pending policy, three-day-or-longer minimum delay, seven-day execution window, monotonically increasing proposal nonce and policy epoch. Proposal binds chain, registry, token, epoch, nonce, controller and allocations. Cancellation does not reuse a nonce. Changed controller invalidates pending execution. Old policy histories are immutable; activation makes no payment and changes no claim ledger.

M1 cannot collect assets, move accrued rights, recover funds, update constitution/source bindings or upgrade code. Its controller provider and checkpoint adapter are trusted immutable dependencies. Current tests use explicit mocks; real factory/curve/hook integration remains BLOCKED pending full G0/G1/G2 completion.

## Independent review limitations

maxCreatorBps bounds only entries declared as creator category, not the beneficial ownership of contributor wallets. An address controlled by the creator can be labeled contributor; onchain code cannot identify undisclosed common ownership. No total-beneficial-owner extraction cap is established. Pinned module addresses likewise do not prove timelocks or safe implementations; an EOA treasury is accepted in this isolated policy model. Factory admission and module implementation qualification remain required.

The pending proposal hash is domain-separated by registry/chain/token/current epoch/nonce/controller. Historical policyHash is the allocation-content hash, so these values intentionally differ. The controller provider must maintain a monotonically increasing generation counter on every transition, including when control returns to an earlier address.

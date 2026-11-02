# CE003-001 — ambiguous counterfactual vault binding
Severity: HIGH design risk. Classification: CONFIRMED_SOURCE preconditions; PROPOSED integration failure, not a verified deployed exploit.
Independent reviewer: /root/g0_authority_review, read-only.

Existing Registry validates module[2] as a fixed per-launch address, but does not enforce uniqueness across launches. Builder creates a separate router for every launch. Therefore one creator may create two otherwise-valid launches with the same helper-predicted treasury beneficiary. Factory/creator/asset/proposer/module checks alone accept both routers. With permissionless finalize(router), an external actor can choose either and consume the helper's sole CREATE. The vault then binds permanently to that router; other credited launch rights have no supported withdrawal route.

No custody code/import was implemented. Owner acceptance of the initial dependency candidate does not resolve this finding. G2/G3/G4 are BLOCKED for the selected design until reviewed.

Required next design decision: bind a unique intended launch/router before third parties can finalize. Evaluate authenticated one-time creator selection (vault remains constructor-immutable) versus a prelaunch commitment validated atomically with launch. Analyze stale selections, creator loss, replay, multiple launches and existing accrued credits; ordinary factory salt is not CREATE2 and does not solve this. Do not change Factory, guess its nonce, or silently add a trusted mutable Vault initializer. Write the smallest real two-launch reproducer and independent-reviewed amended specification before implementation. Do not claim duplicate beneficiary acceptance is an existing protocol exploit; the unsafe helper is proposed.

Executable source-precondition reproducer now passes: testCETwoLaunchesCanCreditSamePlannedTreasury performs two actual launches, real trades and real router settlement, demonstrating both routers credit the identical treasury beneficiary. This proves the source precondition, not a nonexistent helper exploit.

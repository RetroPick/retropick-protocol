# Treasury accounting and API specification
Status: PROPOSED; existing router semantics unchanged.

Helper API: predictedVault(), deploy(router), immutable factory/creator/asset/proposer/chain and once-only deployment event. Validate real token.deployer attribution (deployer()), factory.communitySource(token), curve.communityRouter(), router.ready/factory/source/feeAsset and registry.module(2). No arbitrary caller can supply a different governance configuration during finalization.

Vault API: claimFromRouter(amount), spend(asset,recipient,amount,spendId), immutable identity getters, claimed/spent/held, actualBalance/surplus/deficit and claimableRouterCredit views. Constructor deploys timelock, exposes its address. Events: TreasuryInitialized, RevenueClaimed, RevenueSpent; indexed router/recipient/spend ID. Errors distinguish Unauthorized, InvalidBinding, WrongAsset, InvalidAmount, AlreadySpent, BackingDeficit and transfer failure. No fallback arbitrary execution.

Claim preconditions: initialized, positive amount within own credit, existing backing solvent. Read credit and physical balance, call router.claimTo(self,amount), verify own-credit reduction and exact receipt, then increase claimed and held. Router paid increases and liability decreases; vault does not mint a second fee entitlement. Failed transfers roll back all effects.

Spend: only timelock; nonreentrant; check balance>=held and amount<=held; consume spendId and debit held/credit spent before transfer. Failure rolls back vault and timelock completion. Amount paid contains no new rounding. Native recipients may forward value: success plus exact vault debit proves delivery, not retained recipient balance. Token sender and receiver deltas must both be exact.

Identity: claimed=spent+held; surplus=max(balance-held,0), deficit=max(held-balance,0). Donations never increase claimed or spendable held. Unexpected unrelated assets have no recovery path. One community cannot cover another. Source F/T, protocol escrow P, curve reserves, LP principal and graduation assets stay outside vault accounting.

Operation lifecycle: unset -> waiting >=72h -> ready -> done; cancellation removes permission. Ready until timestamp+7days inclusive, expired after. Completed operations cannot replay; cancellation/requeue follows upstream rules and must restart the full delay. New attempts use fresh salts. Vault spend IDs additionally prohibit a successful transfer being repeated under another operation hash. No scheduling-time reservation of treasury revenue; insufficient balance fails without consuming operation, retry only within window.

Example per 1 MON gross at base100bps/tax50bps/protocolShare3000bps: F=.01,T=.005,P=.003,C=.012; 60/40 gives creator .0072 and treasury .0048. In six-decimal quote units per 1 quote: F10000,T5000,P3000,C12000; creator7200,treasury4800. Claim half then spend half records claimed2400/spent1200/held1200, router still owes remaining2400 treasury credit. Donations remain separate. Example settings are not production defaults.

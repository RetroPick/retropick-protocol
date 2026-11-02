# CommunityTimelockV2 capability and authority matrix

Status: NEW_EXPERIMENT / locally unit-and-fuzz tested governance primitive. No Treasury Vault custody qualification or actual Safe threshold qualification. Solidity0.8.26, Cancun, viaIR, optimizer200.

| Surface | Authority / enforced behavior | Executable evidence |
|---|---|---|
| Constructor | Fixed min72hours; one nonzero proposer/canceller; reject self/deploying caller; executor address0; only self default admin | BootstrapRolesAndFixedDelay, RejectsInvalidProposers |
| schedule / scheduleBatch | Upstream proposer role, >=72h; full upstream hash includes target/value/data/predecessor/salt | Unauthorized keeper, insufficient delay, predecessor and batch tests |
| execute / executeBatch | Ready execution open; wrapper rejects later than readyAt+7days; upstream before/after guards intact | ExactReadinessAndDeadline, BatchExactDeadlineAndReplay, ExpirySeparateFromUpstreamReady, BatchExpiryAndAtomicFailure |
| cancel | Proposer's canceller role; upstream unset/waiting/ready rules unchanged; no arbitrary keeper cancellation | CancelRequeueRestartsFullDelay |
| grantRole / revokeRole | Only nonzero proposer/canceller membership may change, authorized by upstream self-admin | MembershipRequiresSelfCallAndRejectsZero, AtomicProposerReplacement |
| Default admin / executor | No external default-admin grant; no self-admin removal; zero executor stays open | GovernedAdminExecutorAndRenounceBypassesRejected |
| renounceRole | Always reverts; no immediate self-renunciation path | ImmutableAdminExecutorAndRenunciation |
| updateDelay | Always reverts, including scheduled self-call or batch | DirectAndGovernedDelayChangeAlwaysFails, BatchExpiryAndAtomicFailure |
| Generic target calls | Execute only exact authorized data/value after delay; called target cannot impersonate timelock on a later call | CallbackCannotEscalateRole, FixedNativeValueAndTargetAuthority |
| Reentry / rollback | Upstream state checks reject duplicate same-operation reentry; target failure leaves ready operation retryable | SameOperationReentryRollsBack, TargetFailureRetryAndIndependentOperation |
| Clock views | isExpired and isReadyWithinWindow distinct from inherited scheduler-only Ready; no claim of predecessor/target success | HugeFutureTimestampDoesNotOverflowViews and expiry tests |

Seven-day deadline is inclusive. Expiry arithmetic uses subtraction only after now>eta and ignores unset/done sentinels; no eta+window overflow. Done operation IDs cannot replay. Cancellation permits explicit rescheduling under upstream rules after another full delay. Vault spend IDs are still required to prevent reauthorized duplicate payouts across hashes; the Vault is not implemented by this primitive.

Role replacement can be an atomic batch granting new proposer/canceller and removing old. Delayed revocation of the last proposer is allowed: without another proposer or already-queued restoration, new proposals become impossible. No emergency bypass is introduced. A compromised proposer may still approve spending after the delay; time visibility is not an independent veto. Open executor cannot create new operations.

The timelock has upstream generic calls and NFT receiver helpers. These are not fee receipts or a grant of custody over curve/router/LP assets. Future Vault must be non-upgradeable, bind the qualified timelock immutably, expose only narrow spending, validate tokens/amounts and exact deltas, and have no arbitrary-call/approval/rescue surface. Timelock generic-call success does not interpret arbitrary ERC20 bool-return semantics.

Dependency: isolated OpenZeppelin v5.4.0 c64a1edb67b6e3f4a15cca8909c9482ad33a02b0; all twelve Solidity files plus LICENSE verify against approved PR44 manifest. No upstream edits. Fresh public upstream advisory inventory contains20entries. Historical critical Timelock advisory affects older3.x/4.x, outside v5.4.0; current low Bytes.lastIndexOf package warning includes v5.4 but Bytes.sol is absent from this exact closure. Raw inventory and individual dispositions retained. This is not an independent audit or a whole-package security guarantee.

Slither26findings individually triaged, including governed arbitrary-send high label; Semgrep2performance suggestions/0parse errors. No stateful governance/Vault campaign, real Safe signature proof, fork or deployment is claimed.

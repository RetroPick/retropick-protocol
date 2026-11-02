# Treasury dependency and governance candidate
Status: OWNER-ACCEPTED FOR EXPERIMENTAL SCOPE; DESIGN BLOCKED BY INDEPENDENT REVIEW CE003-001. Not an accepted production ADR.

Scope: V2 experiment only. V3, existing core CE contracts and historical evidence stay unchanged. No deployment.

Import only OpenZeppelin v5.4.0 commit c64a1edb67b6e3f4a15cca8909c9482ad33a02b0, MIT license, isolated beneath the experimental vendor directory, with unchanged relative imports and per-file hashes. The closure is TimelockController, AccessControl, IAccessControl, Context, ERC165, IERC165, Address, Errors, ERC721Holder, IERC721Receiver, ERC1155Holder and IERC1155Receiver. Do not replace global OpenZeppelin or change remappings/compiler. Check current upstream advisories and audit scope before adoption; a release tag alone is not qualification.

Selected authority: fixed 72-hour minimum; reject updateDelay even from self. Seven-day inclusive execution window after readiness, enforced for execute and executeBatch using upstream timestamps. Proposer/canceller is the disclosed community multisig; ready execution open; self-admin only, no external default-admin grants or self-admin removal. No controller/guardian spending or automatic emergency recovery. Role changes require governed self-calls. Lost proposer access may lock funds; a compromised proposer can spend after the review delay. Local proposer mocks do not qualify actual Safe signatures/deployment.

Deploy a single-use helper with immutable factory, creator, asset and proposer. Its constructor creates no contracts. Publish its first CREATE address for Config.modules[0]. Permissionless finalize validates actual factory token record/deployer, curve/router identity, quote, chain and registry module(2); deploys vault once at that address. Vault constructor sets immutable bindings and deploys the qualified policy timelock. No mutable post-deployment binding. Duplicate/mismatched finalization fails atomically. Bootstrap-incomplete state is disclosed; accrued credit stays in Router until deployment. Test predeployment native prefunding and constructor failure/retry.

Vault claims only its own Router credit through claimTo(self, amount). Only the timelock may spend accounted earned revenue; asset must match, spend identifier nonzero and unused, recipient nonzero and not self, amount positive and covered. No approvals, arbitrary calls, rescue, surplus spending or source override. Donations remain quarantined. Native success/exact vault debit; exact ERC20 sender/receiver deltas. Deficit fails closed before claiming more income. Claimed=spent+held; physical balance covers held for supported assets. Unsupported issuer destruction is not insured.

Alternatives: direct Safe custody lacks enforced delay; Zodiac module delay can be bypassed through direct owner routes; a custom scheduler adds unjustified risk. Retain upstream scheduler and limit changes to explicit reviewed policy overrides.

Acceptance requested: this exact isolated dependency closure and governance/deployment design, research implementation only. No accepted protocol ADR or deployment authority is changed. Owner acceptance is recorded separately. G3/G4 remain BLOCKED by CE003-001 and incomplete qualification; continue independent source/test/research work.

Sources: https://github.com/OpenZeppelin/openzeppelin-contracts/tree/c64a1edb67b6e3f4a15cca8909c9482ad33a02b0 ; https://contracts.openzeppelin.com/security ; https://docs.zodiac.eco/developers/delay .

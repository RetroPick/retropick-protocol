# Bounded canonical Treasury and Router static review

Status: COMPLETED_BOUNDED_REVIEW; not an audit or release qualification.

Slither 0.11.6 compiled the canonical Treasury import closure (41 contract/interface/library/abstract declarations) with Solidity 0.8.26, optimizer 200, viaIR and Cancun. Twelve explicitly selected detectors produced 18 reports; exit 255 reflects findings, not failed compilation. Entry-point printer output is a separate run. No financial source changes were made.

## Findings

| ID | Tool check | Tool impact | Disposition |
|---|---|---|---|
| STATIC-CE-007-001 | arbitrary-send-eth | High | INTENDED_AUTHORITY |
| STATIC-CE-007-002 | divide-before-multiply | Medium | ALGORITHMIC_PATTERN_NOT_CONFIRMED_DEFECT |
| STATIC-CE-007-003 | divide-before-multiply | Medium | ALGORITHMIC_PATTERN_NOT_CONFIRMED_DEFECT |
| STATIC-CE-007-004 | divide-before-multiply | Medium | ALGORITHMIC_PATTERN_NOT_CONFIRMED_DEFECT |
| STATIC-CE-007-005 | divide-before-multiply | Medium | INFORMATIONAL_UNREACHABLE_FROM_REVIEWED_FIRST_PARTY_PATH |
| STATIC-CE-007-006 | divide-before-multiply | Medium | ALGORITHMIC_PATTERN_NOT_CONFIRMED_DEFECT |
| STATIC-CE-007-007 | divide-before-multiply | Medium | ALGORITHMIC_PATTERN_NOT_CONFIRMED_DEFECT |
| STATIC-CE-007-008 | divide-before-multiply | Medium | ALGORITHMIC_PATTERN_NOT_CONFIRMED_DEFECT |
| STATIC-CE-007-009 | divide-before-multiply | Medium | ALGORITHMIC_PATTERN_NOT_CONFIRMED_DEFECT |
| STATIC-CE-007-010 | divide-before-multiply | Medium | ALGORITHMIC_PATTERN_NOT_CONFIRMED_DEFECT |
| STATIC-CE-007-011 | reentrancy-no-eth | Medium | GUARDED_PATTERN_NO_EXPLOIT_DEMONSTRATED |
| STATIC-CE-007-012 | reentrancy-no-eth | Medium | GUARDED_PATTERN_NO_EXPLOIT_DEMONSTRATED |
| STATIC-CE-007-013 | arbitrary-send-erc20 | High | FALSE_POSITIVE_IN_REVIEWED_CALL_PATH |
| STATIC-CE-007-014 | reentrancy-events | Low | INFORMATIONAL_EVENT_ORDER |
| STATIC-CE-007-015 | reentrancy-events | Low | INFORMATIONAL_EVENT_ORDER |
| STATIC-CE-007-016 | reentrancy-benign | Low | GUARDED_PATTERN_NO_EXPLOIT_DEMONSTRATED |
| STATIC-CE-007-017 | incorrect-equality | Medium | FALSE_POSITIVE_SENTINEL_COMPARISON |
| STATIC-CE-007-018 | incorrect-equality | Medium | FALSE_POSITIVE_SENTINEL_COMPARISON |

## STATIC-CE-007-001

Upstream _execute is internal. CommunityTimelock.execute/executeBatch enforce the seven-day window then upstream executor-role/open-executor, scheduled operation hash, readiness and predecessor checks. Proposal scheduling requires PROPOSER_ROLE. Vault.spend separately requires immutable timelock, supported asset, earned held amount, nonreentrancy and spend-ID uniqueness. Generic authorized target calls remain disclosed governance power; no permissionless drain demonstrated.

Source: CommunityTimelockV2.sol:54-90; vendor/openzeppelin-v5.4.0/contracts/governance/TimelockController.sol:357-441; CommunityTreasuryVaultV2.sol:113-138.

## STATIC-CE-007-002

mulDiv removes the product remainder before power-of-two factorization, normalizes a 512-bit product, and multiplies by the odd-denominator modular inverse using Newton-Raphson iterations. These flagged operations are deliberate exact/modular steps, not an economic division followed by accidental scale restoration. This is source reasoning, not a fresh formal proof or compiler-bug exclusion.

Source: lib/openzeppelin-contracts/contracts/utils/math/Math.sol:206-277,317-363; CommunityFeeRouterV2.sol:113.

## STATIC-CE-007-003

mulDiv removes the product remainder before power-of-two factorization, normalizes a 512-bit product, and multiplies by the odd-denominator modular inverse using Newton-Raphson iterations. These flagged operations are deliberate exact/modular steps, not an economic division followed by accidental scale restoration. This is source reasoning, not a fresh formal proof or compiler-bug exclusion.

Source: lib/openzeppelin-contracts/contracts/utils/math/Math.sol:206-277,317-363; CommunityFeeRouterV2.sol:113.

## STATIC-CE-007-004

mulDiv removes the product remainder before power-of-two factorization, normalizes a 512-bit product, and multiplies by the odd-denominator modular inverse using Newton-Raphson iterations. These flagged operations are deliberate exact/modular steps, not an economic division followed by accidental scale restoration. This is source reasoning, not a fresh formal proof or compiler-bug exclusion.

Source: lib/openzeppelin-contracts/contracts/utils/math/Math.sol:206-277,317-363; CommunityFeeRouterV2.sol:113.

## STATIC-CE-007-005

Imported invMod uses Euclidean quotient/remainder updates; reviewed Router/Registry/Treasury/Timelock source calls mulDiv, not invMod. No reachable first-party invMod call found in this bounded closure.

Source: lib/openzeppelin-contracts/contracts/utils/math/Math.sol:206-277,317-363; CommunityFeeRouterV2.sol:113.

## STATIC-CE-007-006

mulDiv removes the product remainder before power-of-two factorization, normalizes a 512-bit product, and multiplies by the odd-denominator modular inverse using Newton-Raphson iterations. These flagged operations are deliberate exact/modular steps, not an economic division followed by accidental scale restoration. This is source reasoning, not a fresh formal proof or compiler-bug exclusion.

Source: lib/openzeppelin-contracts/contracts/utils/math/Math.sol:206-277,317-363; CommunityFeeRouterV2.sol:113.

## STATIC-CE-007-007

mulDiv removes the product remainder before power-of-two factorization, normalizes a 512-bit product, and multiplies by the odd-denominator modular inverse using Newton-Raphson iterations. These flagged operations are deliberate exact/modular steps, not an economic division followed by accidental scale restoration. This is source reasoning, not a fresh formal proof or compiler-bug exclusion.

Source: lib/openzeppelin-contracts/contracts/utils/math/Math.sol:206-277,317-363; CommunityFeeRouterV2.sol:113.

## STATIC-CE-007-008

mulDiv removes the product remainder before power-of-two factorization, normalizes a 512-bit product, and multiplies by the odd-denominator modular inverse using Newton-Raphson iterations. These flagged operations are deliberate exact/modular steps, not an economic division followed by accidental scale restoration. This is source reasoning, not a fresh formal proof or compiler-bug exclusion.

Source: lib/openzeppelin-contracts/contracts/utils/math/Math.sol:206-277,317-363; CommunityFeeRouterV2.sol:113.

## STATIC-CE-007-009

mulDiv removes the product remainder before power-of-two factorization, normalizes a 512-bit product, and multiplies by the odd-denominator modular inverse using Newton-Raphson iterations. These flagged operations are deliberate exact/modular steps, not an economic division followed by accidental scale restoration. This is source reasoning, not a fresh formal proof or compiler-bug exclusion.

Source: lib/openzeppelin-contracts/contracts/utils/math/Math.sol:206-277,317-363; CommunityFeeRouterV2.sol:113.

## STATIC-CE-007-010

mulDiv removes the product remainder before power-of-two factorization, normalizes a 512-bit product, and multiplies by the odd-denominator modular inverse using Newton-Raphson iterations. These flagged operations are deliberate exact/modular steps, not an economic division followed by accidental scale restoration. This is source reasoning, not a fresh formal proof or compiler-bug exclusion.

Source: lib/openzeppelin-contracts/contracts/utils/math/Math.sol:206-277,317-363; CommunityFeeRouterV2.sol:113.

## STATIC-CE-007-011

activatePolicy, proposePolicy and cancelPolicy share nonReentrant protection. Checkpoint intentionally runs while old epoch remains active, then checks pending == 0 and rechecks controller identity/generation before epoch advancement. Flagged writes-after-checkpoint implement required old-right settlement, not independently proven corruption. Controller/checkpoint failure sequences still require the broader campaign.

Source: CommunityPolicyRegistryV2.sol:112-165; CommunityFeeRouterV2.sol:76-80.

## STATIC-CE-007-012

claimFromRouter and spend share nonReentrant protection. The immutable bound Router sends only this Vault credit to this Vault; exact credit reduction and physical receipt are verified before incrementing claimed. A callback can observe transient views, but cannot reenter either financial mutator; no reviewed consumer spends using an unguarded transient-view oracle. Fresh hostile-token/Treasury testing remains separate.

Source: CommunityTreasuryVaultV2.sol:97-138.

## STATIC-CE-007-013

ExactAssetV2.pull is internal, not an externally callable arbitrary-from spender. In the reviewed closure Router.fund first requires msg.sender == immutable source, validates launch/asset/epoch/sequence, and passes that same msg.sender as from. No externally supplied victim from parameter reaches this call. Source and destination balance deltas are checked. This disposition covers this closure, not every other protocol use of ExactAssetV2.

Source: libraries/ExactAssetV2.sol:10-18; CommunityFeeRouterV2.sol:88-105.

## STATIC-CE-007-014

Timelock intentionally invokes authorized targets before CallExecuted. _beforeCall checks readiness/predecessor and _afterCall rechecks readiness then marks done; reentry of the same completed operation makes outer execution revert atomically. Cross-operation execution remains subject to independently scheduled authorization. Log ordering requires truthful indexing; no asset-loss exploit demonstrated.

Source: vendor/openzeppelin-v5.4.0/contracts/governance/TimelockController.sol:357-441.

## STATIC-CE-007-015

Timelock intentionally invokes authorized targets before CallExecuted. _beforeCall checks readiness/predecessor and _afterCall rechecks readiness then marks done; reentry of the same completed operation makes outer execution revert atomically. Cross-operation execution remains subject to independently scheduled authorization. Log ordering requires truthful indexing; no asset-loss exploit demonstrated.

Source: vendor/openzeppelin-v5.4.0/contracts/governance/TimelockController.sol:357-441.

## STATIC-CE-007-016

activatePolicy, proposePolicy and cancelPolicy share nonReentrant protection. Checkpoint intentionally runs while old epoch remains active, then checks pending == 0 and rechecks controller identity/generation before epoch advancement. Flagged writes-after-checkpoint implement required old-right settlement, not independently proven corruption. Controller/checkpoint failure sequences still require the broader campaign.

Source: CommunityPolicyRegistryV2.sol:112-165; CommunityFeeRouterV2.sol:76-80.

## STATIC-CE-007-017

Comparisons distinguish stored operation sentinels (0 unset, 1 done), not equality to current block time or an external token balance. Upstream state machine requires these exact sentinel distinctions.

Source: vendor/openzeppelin-v5.4.0/contracts/governance/TimelockController.sol:198-217.

## STATIC-CE-007-018

Comparisons distinguish stored operation sentinels (0 unset, 1 done), not equality to current block time or an external token balance. Upstream state machine requires these exact sentinel distinctions.

Source: vendor/openzeppelin-v5.4.0/contracts/governance/TimelockController.sol:198-217.

## Coverage limits

This covers the canonical Treasury import closure and twelve selected detectors only. It does not close historical 75-finding triage, all canonical V2 contracts, experimental M6, genuine V4, forks, Safe, adversarial runtime testing, or the official Solidity known-bug investigation. Imported algorithm source reasoning does not rule out miscompilation. The two high detector reports have scoped source-based authority/call-path dispositions, not a blanket dependency exemption. No confirmed exploit or full-security PASS is claimed.

The initial printer invocation selected only entry-point output despite --detect; it is retained as inventory evidence, never as a zero-findings detector pass. A separate detectors-only run produced the reports above.

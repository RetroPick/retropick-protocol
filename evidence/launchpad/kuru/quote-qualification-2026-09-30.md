# Monad Testnet stable-quote identity and fork behavior — 2026-09-30

**Classification:** `RECORDED_CONTRADICTION`; KURU-B2-QUOTE remains `DECISION_REQUIRED`. Native MON is the default no-issuer quote candidate. No stable ERC-20 is admitted by this research packet.

Two primary sources currently disagree on what the testnet `USDC` label identifies: [Kuru's testnet token list](https://docs.kuru.io/contracts/Contract-addresses) names `0x3bA3d39AFcf8bb994f7964B3e0171Ea2Ba361570`; [Circle's USDC contract list](https://developers.circle.com/stablecoins/usdc-contract-addresses) names `0x534b2f3A21130d7a60830c2Df862319e593943A3` for Monad Testnet. Both contracts exist at block `66752717`, advertise six decimals and symbol `USDC`, but have different runtime hashes and token names. Symbol/decimals do not establish issuer or economic identity.

| Candidate | Block-pinned observation | Research classification |
| --- | --- | --- |
| Native MON | No ERC-20 transfer semantics or issuer controls; real Kuru type-2 market and native vault seed passed on fork | Candidate P0 quote; full phase-2/live gates remain open |
| Circle-listed `0x534b…43A3` | Name `USDC`; 1,798 runtime bytes, hash `0x96215e…1b5a78`; owner/pauser/blacklister/master-minter getters exist, `paused=false`; real type-0 Kuru deploy and exact 97-USDC fork seed passed | Recommended named stable quote **conditional** on ADR-011 acceptance and issuer-risk disclosure |
| Kuru-listed `0x3bA3…1570` | Name `USD Coin`; 1,737 runtime bytes, hash `0xefd650…d719e`; Circle-style role getters were unavailable/reverted; real type-0 Kuru deploy and exact 97-unit fork seed passed | Not the Circle-listed token; reject the label “canonical Circle USDC” for this address unless new issuer evidence disproves the distinction |

The [environment manifest](environment-manifest-2026-09-30.json) contains full addresses/hashes. The [fork record](fork-deploy-seed-2026-09-30.md) covers exact-transfer and allowance behavior in the required vault path at the pinned block. It does not prove that either contract can never pause, blacklist, rebase or change implementation. Circle-listed USDC visibly grants pause/blacklist/mint authority; these are external trust risks for a stable quote, not bugs that a RetroPick transfer test can remove. The current Factory's owner can approve an unsupported token, so scoped Core qualification relies on the protocol-owner admission trust assumption and preserves the surcharge/rebase counterexamples.

**Recommendation for ADR-011:** name the Circle-listed `0x534b…43A3` if P0 is meant to use issuer-recognized testnet USDC. Treat the Kuru-listed `0x3bA3…1570` as a distinct venue-compatible token requiring its own provenance and risk decision; never substitute it by matching `symbol()`. Confirm Circle token availability and pause/blacklist state at live execution. Actors A/B held zero of either contract at inspection, so the first live smoke can use native MON without purporting to validate live USDC funding.

The protocol owner must explicitly choose the address/trust policy. B2 stays `DECISION_REQUIRED`, and `KURU_TARGET_FROZEN` stays blocked until the choice and all other gates close.

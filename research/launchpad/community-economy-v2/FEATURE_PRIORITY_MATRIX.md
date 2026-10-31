# Feature priorities

Scores are qualitative engineering judgments, not a numeric safety rating. Pain evidence is classified in PRODUCT_DEMAND_EVIDENCE.md; adoption remains a hypothesis.

| User job / feature | Benefit and alternatives | Attack surface / effort | Decision |
|---|---|---|---|
| Multiple creator/contributor wallets | Enforce payment without manual bookkeeping; competitors already provide splits | Exact funding, rounding, beneficiary rights; moderate | P0 BUILD NOW: integrated router claims locally tested |
| Transparent policy and immutable bounds | Verify future authority before trading; alternative frozen split | Timelock/epoch/checkpoint correctness; high | P0 BUILD NOW: real curve checkpoint tested |
| Standard ERC-20 and exit compatibility | Preserve existing trade paths; alternative transfer taxes | Avoid transfer-path complexity | P0 PRESERVE: legacy differential tests |
| Treasury custody | Recurring shared budget; alternative disclosed multisig recipient | Timelock/roles/spend scope; moderate | P1 BUILD AFTER DEPENDENCY: pinned proven primitives and qualification |
| Stake-to-earn | Optional funded staker allocation; alternative direct treasury spend | Timing capture, principal custody, precision; high | P1 BUILD AFTER DEPENDENCY: streaming/eligibility and real-deposit proof |
| Controller handoff/recovery | Separate future administration from old claims | Compromised keys, races, authority generation; moderate | P0 implementation PARTIAL: more sequence qualification |
| Buyback lock/burn/hold | Explicit budget/custody choice; alternative leave budget escrowed | Price manipulation/MEV/oracles; high | P2 RESEARCH: execution disabled |
| LP reinvestment | Potential deeper exit liquidity | Venue rights, slippage and custody; high | P2 RESEARCH: no auto-LP implementation |
| Referral distribution | Attribute acquisition costs | Sybil farming, fee circularity; moderate | P2 RESEARCH: allocation category only, no referral attribution |
| Creator vesting | Potential commitment | Supply-to-curve deviation and accrued vest rights; high | DEFERRED: preserve existing supply model and legacy vest reference |
| Fair-launch/anti-snipe | Entry fairness | Existing exemption is a stub; auctions need separate economics | RESEARCH: do not advertise current enforcement |
| Reputation/governance | Discovery and continuity | Sybil identity, capture and legal assumptions; high | RESEARCH: no automatic takeover or score |
| Transfer taxes/reflections/rebases/blacklists | No proved incremental benefit for this job | Compatibility and custody risk | REJECT |
| External-business revenue/guaranteed yield | Separate financial/legal product | Unverified funding rights and regulatory complexity | REJECT FROM THIS EXPERIMENT |

Low genuine volume can make distributions uneconomic; higher fees do not establish retention. No feature bypasses its accounting gates simply because it exists elsewhere. Contributor cap enforcement concerns declared categories only, not hidden common ownership.

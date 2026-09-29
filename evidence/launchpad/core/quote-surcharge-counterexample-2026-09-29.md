# Core V2 quote sender-surcharge counterexample — 2026-09-29

**Classification:** `COUNTEREXAMPLE_FOUND` to the proposition that Factory approval alone guarantees exact-transfer quote backing. **Scope:** current Core V2 source and a deliberately nonstandard test ERC20; this does not say a genuinely exact-transfer token fails.

The Factory checks contract code, readable/matching six-decimal metadata, and configured phantom/threshold economics. It does not establish transfer semantics. `contracts/test/v2/integration/RetroPickFactoryLaunchV2Qualification.t.sol::testApprovedSenderSurchargeQuoteCanDeficitCurveAfterSell` uses a token that debits the sender by the requested transfer amount plus `floor(amount / 10)` (the excess is burned). Its `decimals()` returns 6 and Factory approval succeeds.

Sequence: the creator buys with `10e6` quote units. The Curve's inbound balance-delta measurement credits precisely the amount received, so `physicalBalance == trackedQuote` immediately after the buy. The creator then sells half the acquired launch tokens. The Curve computes and sends a quote payout `p`, reducing `trackedQuote` by `p`; the token actually debits the Curve by `p + floor(p/10)`. The executable assertion is:

```text
trackedQuote - physicalBalance == floor(p / 10) > 0
```

This is a real accounting deficit caused by an admitted nonstandard quote asset. Future payouts or fee transfers may fail even though tracked accounting says funds exist. The separate asset policy in `development/launchpad/contracts/QUOTE_ASSETS.md` already requires exact-transfer and excludes fee-on-transfer/rebasing/callback-dependent assets in P0. The counterexample shows why approval must be backed by asset-specific qualification and governance controls; the current metadata checks cannot enforce that policy on their own.

**Reproduction:** `cd contracts && forge test --match-test testApprovedSenderSurchargeQuoteCanDeficitCurveAfterSell -vv` — pass; the test is a negative control whose asserted deficit is the finding. Source-file SHA-256: `46b4c37f1ee29f1b38c74c9c7025ede33a0796fed40e9a436697d760293f6655`. No production contract change or gate upgrade follows. Suggested next evidence: exact-transfer quote fixture, outbound delta check design study, token rebase/external-loss tests, and an explicit deployment allowlist review for each quote asset.

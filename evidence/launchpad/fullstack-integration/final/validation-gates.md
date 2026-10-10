# V2 Fullstack Integration — Validation Gates (2026-10-10)

Baseline: 41df325 · Integration branch: codex/v2-fullstack-integration · Chain: Monad Testnet 10143
Live actors: A 0xB505cBaab3ACdF287af1366b9B1229404757913b (keystore monad-testnet), B 0x101212C52620ca00540ee04D1515E714e6368Fcd (monad-testnet-actor-b); credentials in ~/.config/retropick/e2e (never in repo).

## Gate 1 — Static conformance: PASS
- ABI catalog regen deterministic, counts 27/517/147/325, 100% disposition coverage (abi-capabilities.json).
- SDK typecheck PASS; retro-ui typecheck+build PASS; indexer typecheck PASS.
- Overload regression: SDK suite asserts launchToken venue overload selector ≠ 3-arg overload; cast-calldata fixtures pin buy/deposit/withdraw/addBuyOrder/batchCancelOrders(NoRevert)/claimToken/batchWithdrawMaxTokens.

## Gate 2 — SDK conformance: PASS
- 19/19 offline tests (encoding vs cast ground truth, Kuru grid math incl. real-market scale, event/error decode, salt entropy).
- 2/2 network tests: canonical launch tx replay decodes TokenLaunched → demo token/curve; SDK read model reports GRADUATED phase 2 + custody for 0x43e7…c18f15.

## Gate 3 — Read-only browser E2E: PASS
- Live discovery lists on-chain launches (see live-reads/ screenshots); canonical token renders authentic state (P4 evidence).

## Gate 4 — Simulated write flows: SUPERSEDED_BY_LIVE
- Every flow below was executed as REAL testnet transactions through apps/retro-ui (stronger than fork simulation). Failure paths exercised live: insufficient-balance and grid-precision rejections decoded via the SDK error path; user-rejection path covered by pipeline classification (classifyError tests).

## Gate 5 — Live Monad Testnet E2E through apps/retro-ui: PASS
All via the session EIP-1193 bridge (scripts/e2e/wallet-bridge.mjs + retro-ui session-bridge) — transactions originate in the app's real pipeline (prepare → simulate → sign → receipt → decode).
- FLOW A Create: token 0x30CcB65006665022Dfc97bB5c1985610503Fd1cf (RTL916), tx 0x34bb210c5953ca80f24f5596becb9c795b7df08ec6682ac551fe2d80f38476b5 (TokenLaunched decoded; UI redirected to the token page).
- FLOW B Curve buy/sell: buy tx 0x146c5bb379dbb77fa448a780187c397599ed8fe6e73f21cc40bff475ee5a9ee9 (CurveBuy), sell tx 0xafd47a96702bd8c6dfc867a4f0f7a615035cb4726d67b138b0574285d2eef828 (CurveSell) on RPAPP 0xd7B2…d609; terminal purchase with refund completed the fresh curve (reserve hit terminal 2.000000000000000002 exactly).
- FLOW C Graduation: factory.graduate txs 0xa2370b6fdc3736d2b59693e2d4a5a66be9ec6074c3ccab2786679dcfef35dad0 / 0x67b1bc93e9b131a4a5bf94a6c9db91ac0d1d400d910688494c39f3db32e57ac8; coordinator completion via UI retry → GRADUATED; Kuru market 0x43390884daa59872b3ee658aa535df4282f5e47a, vault 0x7402dee487b1517764a220946b99255fab9d1206.
- FLOW D Kuru: deposits 0x9d7637…ad42 / 0xbf8446…032c / 0x80ba07…c4f6 / 0xf3075b…78ff; limit order 0x1af3b92d9325e7aa70a1298b6699948377a4275e17c7b89e0a7a9f660f63dd23 (OrderCreated id 3); cancel 0xe7e64e521dc04e3f2cee1c5810ea34d4a272a0bfa4acc7132a236333c1460015; withdraw 0x88bd2ea9bff3fb580983bf4e2e3e10165d715b78edd2cca2a7e4584b14c5f4cd.
- FLOW E/F surfaces live-read escrow credit, buyback releasable, margin and wallet balances (claims execution wired; no balance present for actor A at freeze → claim buttons render only with credit > 0, fail-closed).

## Gate 6 — Three-way consistency: PASS
- Chain ledger phase 2 (GRADUATED) for RTL916 = indexer phase GRADUATED (journal-derived, lag 8 = confirmation buffer only, error none) = UI lifecycle display. Balances/order state re-read from chain after every tx by the pipeline.

## Gate 7 — Browser QA: PASS (gstack/playwright; cookie-authenticated external sites remain BLOCKED)
- Desktop + mobile final screenshots in final/; zero console errors on all live routes; mock mode preserved (17/17 domain tests; demo modules unchanged and separately gated).

## Gates NOT covered here
- Foundry fork re-run of write flows (superseded by live); authenticated-browser tests (BLOCKED: cookie import requires user interaction).

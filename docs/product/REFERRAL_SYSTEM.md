# RetroPick V1 referrals and Testnet funding

Status: implemented attribution candidate for Monad Testnet, chain 10143. Referral earnings and fiat funding are not enabled. The deployed V2 contracts, creator fee recipients, creator tax, FeeEscrow credits and BuybackVault accounting are unchanged.

`REFERRAL_PAYOUT_REQUIRES_PROTOCOL_CHANGE = TRUE`

## Attribution contract

Every connected wallet can immediately share `https://<application-host>/r/<wallet>`. Retro-ui also accepts a `ref` query hint where its router captures it. V1 codes are normalized EVM wallet addresses; custom codes are not supported. The first valid link is held locally for 30 days. New link visits cannot replace it during that window. The link is an attribution hint, never economic authority.

Association is explicit: the user signs a server-issued challenge containing the exact application domain and URI, wallet, chain 10143, unique nonce, five-minute expiry, referrer and attribution-only purpose. The backend checks wallet ownership, rejects self referrals and consumes the nonce once. The first verified wallet association is immutable. An expired or bad signature cannot associate a wallet. Signing authorizes neither transactions nor payouts.

The backend anchors association to a fresh chain head. Only qualifying activity in blocks **strictly after** that association block counts. Browser first-seen time is bounded analytics metadata and never controls eligibility. The trusted configured indexer's confirmed event stream is the source of observed activity:

- `TokenLaunched`: the deployer is the attributed actor; creator fee recipient is not used as a substitute.
- `CurveBuy` / `CurveSell`: the executed actor qualifies; quote amount is fee-exclusive executed quote volume.
- Kuru `Trade`: only the indexed taker qualifies. Passive makers do not become referred users because another actor traded against them.

Wallets and transaction/log identities are deduplicated. Multiple executed trade logs in one transaction remain distinct real fills, while duplicate ingestion cannot increase volume. Launches add launch count, not trade volume. Volume remains exact integer strings grouped by quote address; it is never summed across assets or presented as testnet USD. Summary status is `ASSOCIATED` until a confirmed qualifying event exists, then `QUALIFIED`.

## Backend, authentication and reorg behavior

`apps/referral-service` is a focused Node 24 SQLite service. It is separate from the GET-only indexer and cannot custody funds, sign user trades or set contract state. Browser traffic uses the same-origin `/api/referrals` proxy. POST requests require the configured exact Origin. The server uses bounded JSON input, parameterized SQLite statements and a 60-request/minute per-peer limit. Production requires HTTPS.

Verification sets a one-hour `HttpOnly; SameSite=Strict` cookie, with `Secure` in production/HTTPS. Session identifiers are stored only as hashes. Authenticated summaries are derived from the cookie's wallet; request parameters cannot select another wallet. Account changes revoke the previous attribution session and clear displayed results. Logout revokes the server session. Cookies and signatures never appear in application logs; signatures are verified in memory and discarded.

The worker polls `/v1/activity` every 15 seconds, accepts only the chain-10143 confirmed freshness envelope, and atomically applies a complete paginated canonical window. Failed pages or expired cursors cannot partially replace analytics. It rescans 512 blocks on ordinary updates, replays from the earliest association whenever reorg revision changes or indexed height rewinds, and removes orphaned activities above a rewound tip. Qualification, launch count and per-quote volume are computed from that canonical journal and therefore roll back with removed events. Attribution may lag the confirmation buffer; it never blocks economic transactions.

The Earn surface retains last confirmed results with a syncing notice on worker failures and displays indexer freshness. Referral payout remains “Not enabled”; attribution is not a promise of a reward.

## Anti-abuse and privacy

Self referral, replayed challenges, forged ownership and replacement of an existing verified referrer are rejected. A query parameter alone cannot qualify a wallet or transaction. The service stores wallet associations, first-seen/association times, confirmed transaction references and per-asset observed volume. It collects no bank/card data, private keys or wallet signatures. There is no device fingerprinting or cross-site tracking.

Local first touch expires after 30 days. Expired challenges and sessions are deleted during requests. Associations and indexed attribution history remain until the operator applies the deployment's documented retention policy; deletion requests must be handled before offering this candidate as a public production service. No reward payouts exist, so V1 does not claim comprehensive Sybil resistance. Before monetization, qualify campaign funding, eligibility, reward accounting, dispute/reorg rules, retention and anti-Sybil controls; do not reinterpret creator fees as referral revenue.

Divvi was the closest SDK examined for wallet/onchain attribution, but its package is deprecated and the official repository is archived. Generic affiliate SDKs would still need RetroPick's ownership and confirmed-event adapter. The focused internal module avoids that extra dependency. [Divvi repository](https://github.com/divvi-xyz/divvi-referral-sdk), [package status](https://www.npmjs.com/package/@divvi/referral-sdk).

## Funding and future payouts

The `FiatProvider` boundary exposes `capabilities`, `buy` and `sell` without coupling the UI to one provider. All four researched adapters fail closed for Testnet 10143:

| Provider | Testnet qualification |
| --- | --- |
| MoonPay | Published sandbox delivery networks omit Monad. ERC20 sandbox delivery is MoonPayToken on Sepolia. [Official sandbox](https://dev.moonpay.com/widget/sandbox-testing) |
| Transak | Published sandbox delivery networks omit Monad; unsupported chains can show a dummy order without asset delivery. [Official sandbox](https://docs.transak.com/guides/sandbox-credentials) |
| Ramp | Demo network and asset lists omit Monad. [Official testing environment](https://docs.rampnetwork.com/testing-environment) |
| Coinbase Onramp | No official confirmation of Monad Testnet MON/USDC delivery was found for this integration. [Official sandbox](https://docs.cdp.coinbase.com/onramp/additional-resources/sandbox-testing) |

Mainnet support does not qualify a testnet, and a provider's support for another USDC contract does not qualify RetroPick's deployed quote token. Enabling funding later requires exact network, asset contract, environment, country, payment flow and partner capability verification. No provider SDK or keys are installed for this testnet campaign. The UI links to the [official Monad Testnet faucet](https://faucet.monad.xyz), listed in [Monad network information](https://docs.monad.xyz/developer-essentials/testnet).

Same-chain “Send to wallet” is independent wallet-to-chain execution. The user must verify that the recipient supports the asset on Monad; no automatic bridge is part of this campaign. Creator fee claims settle to the user's wallet first. Bank/card off-ramping would be a separate qualified provider flow, not “Claim to bank”.

A future referral payout primitive requires a separately reviewed protocol change and funded reward mechanism. Stop before changing Solidity or redeploying contracts; human authorization is required for deployment. Attribution totals alone are never payout authority.

## Verification

Run `pnpm --filter @retropick/referral-service test` and `typecheck`. Tests cover real signature ownership, tampering, expiry/concurrent replay, immutable referrers, invalid/self referral, strict post-association eligibility, exact per-quote volume, duplicate logs, failed pagination, unconfirmed data, shallow/deep reorg removal, Origin/session/logout isolation, 30-day first touch and all provider fail-closed paths. Final integration must also validate the same-origin proxy and signed referral flow in the actual retro-ui with its current wallet provider.

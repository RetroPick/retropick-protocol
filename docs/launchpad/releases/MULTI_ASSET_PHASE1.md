# Multi-asset quote candidate — Phase 1

## Deployed-source audit

Production `https://retropick.xyz/release.json` identifies source `e7188395db7ce84ab1fcae29df017b74f6582f9e`, chain 10143. Production alias was independently checked against Vercel deployment `dpl_87KN562TwXxRh87dBPe4Y1AS15h6`. The candidate branch `codex/multi-asset-quotes-phase1` starts at that source. The original dirty `codex/metropolis-p0-recovery` checkout and its branding work are preserved. Main differs from production and was not used as the baseline.

Reviewed AGENT_GUIDE and the shared control plane, canonical launchpad/platform specifications and quote policy, ADR-011, SDK registry/prepare/model/Kuru reads, V2 quote registry/factory, indexer query/sync, deployment manifests, runtime rewrites and existing browser/test infrastructure. The deployed V2 registry remains the authority. ADR-011 is proposed, and per-asset security/economics/graduation qualification remains required.

Before this change, the SDK discovered three hardcoded addresses and read ERC-20 decimals before checking admission. The wizard used a native HTML quote dropdown and silently chose the first admitted quote or venue when the selected value was absent. Discovery retained quote addresses/symbols but lacked artwork. Financial rows were already mostly quote-denominated, with the table price missing its unit. The indexer groups financial sorts by quote denomination and has paginated snapshot-bound cursors. It does not index `QuoteAssetConfigured`. Fixtures are separate DEMO surfaces, not chain launches.

## Implementation

- A shared Zod-validated catalog holds 83 stable identities: 35 crypto, 24 issuer-metadata-verified stock/ETF references, eight private-company references, ten currency tokens, six commodities. Custom references are created locally, so their initial catalog count is zero. Status counts: two `LIVE_TESTNET`, one `TESTNET_REPRESENTATION`, 80 `REFERENCE_ONLY`, zero `DISABLED`.
- Catalog entries do not confer permission. Stock issuer metadata is sourced directly from Backed/xStocks; no Monad deployment, verified mint, issuer partnership or provider integration is inferred. Private references confer no equity exposure. Contract addresses and verified decimals are populated only for the three existing Monad identities. Artwork sources/licenses/attribution are recorded per entry; retained license files accompany local assets. Missing artwork uses a fixed-size text fallback.
- SDK discovery unions catalog addresses, the registry's Circle address, and optional indexed/custom address hints. One-block reads check chain, enabled configuration, code, decimals, policy version/hash, exact admission and venue mask. Unadmitted contracts need no token metadata read. Unexpected reverts and RPC failures propagate. The prepare path explicitly discovers its requested quote and rejects changed reviewed economics.
- The picker uses searchable, keyboard-selectable cards, counts, source/chain identity, explicit status and preview behavior, persistent category/search state, and bounded rendering. MON is an explicit default; no quote/venue substitution occurs. Unavailable selections save a local preview with null economics and no wallet request. Creator metadata/media/economics/wallet controls remain in place.
- Dual artwork preserves launched-token images beside catalog quote logos in discovery, wizard, terminal headers and desktop/mobile trade tickets. Price units are explicit; USD equivalents remain unavailable for all testnet quotes.
- Discovery fetches all indexed pages into a consistent cached snapshot, retries a changed cursor once, and never publishes partial counts. Category, address, text, lifecycle and layout filters compose. Rankings use exact integer amounts only within a quote denomination. Pagination cursors bind to the snapshot and query; expired cursors display the first page with notice.
- Bonding progress bars show percentages and each launch's immutable quote-denominated graduation goal. Detail progress uses current onchain real reserve; discovery uses indexed real reserve and the committed packet goal. Existing lifecycle filters retain indexer semantics. Kuru orderbook UI reads real SDK depth, including empty/stale/error states. AMM graduates have an explicit venue explanation. ERC-20 Kuru enrichment now binds the quote identity and reads that quote's margin balance; write preparation retains its independent fresh validation.

## Release guards

No deployed contract source, registry permission, economic parameter, domain/DNS, VPS, Yubie deployment or indexer backend changed. No signing or transaction broadcast is part of these tests or release preparation. Candidate deployment uses the existing `--candidate` helper with `--prod --skip-domain`, then verifies the source SHA, backend readiness and unchanged alias. Promotion requires the user's explicit approval.

## Current onchain evidence

See `multi-asset-onchain-evidence.json` for block 70,709,403. MON and Circle-listed USDC (`0x534b2f3A21130d7a60830c2Df862319e593943A3`, six decimals) are admitted on both venues, policy version 1, phantom and threshold one quote unit, ceiling 50 quote units. This is permission evidence, not USDC wallet funding, transfer-risk or real graduation proof. Circle testnet tokens have no implied USD value.

The existing wrapper `0xff437B117Ec17a79a3b24Da4B5047dca4da9D0a2` has 18 decimals, nonempty code, `Wrapped Ether`/`WETH` metadata and disabled version-zero registry config. Its source wraps native MON; it is not an ETH-backed asset. A local-fork test exercises wrapping/unwrapping, exact transfers/approval, curve completion, real Kuru graduation, permanent locks, custody and replay protection using newly deployed local fixture contracts. Live admission remains blocked pending operator review and explicit transaction approval.

A separate unbacked `rpTestWBTC` proposal remains **not deployed**, with no address assigned. Suggested test-only identity: "RetroPick Test Bitcoin representation", symbol `rpWBTC`, fixed transparent mint policy; no Bitcoin reserves, redemption, issuer backing or official WBTC affiliation. The unchanged deployed Kuru policy accepts only six or 18 decimals, supply 1,000 tokens, phantom = threshold = one quote unit, and ceiling = 50 quote units. An eight-decimal representation fails that policy. A clearly unbacked 18-decimal representation could be investigated without changing the policy, but has no qualification evidence yet. Before admission: review exact runtime/issuance powers, transfer/approve compatibility and freeze/rebase/fee behavior; qualify phantom/threshold/ceiling and both requested venues on a pinned fork; prove Kuru grid/seed/fill compatibility, LP/excess locks, creator fees and two-actor trading; fund operator/test wallets; estimate gas against then-current RPC gas price. No permission or financial parameters are proposed as approved by this report.

## Demo narratives and limitations

1. MON: discover a real indexed native launch, show goal/progress and graduate-market SDK orderbook; actual new launch signing remains a user action.
2. USDC: select the verified Circle address and review admitted economics. Wallet funding and a fresh live USDC launch/graduation must be separately evidenced; prior qualification reports marked funding blocked.
3. WMON: explain native wrapper identity and preview while permission is absent. Only after operator approval and complete compatibility evidence may it become executable. `rpTestWBTC` is a distinct later proposal, not a replacement or alias for this wrapper.

## Verified candidate release

Candidate: https://retropick-metropolis-retro-ui-staging-icq0n7tne-asyams-projects.vercel.app (existing Vercel access protection applies).

Exact deployed and browser-tested source: `ea031e58428b9ddfee313de597928f0465a1bc5b`. Subsequent branch commits record evidence and test assertions only. Candidate is unpromoted. Production release was reread after testing and still identifies `e7188395db7ce84ab1fcae29df017b74f6582f9e`; the existing staging alias also remained on deployment `dpl_87KN562TwXxRh87dBPe4Y1AS15h6`. No deployment protection settings were changed. Browser authentication used the existing automation credential in memory, scoped to the candidate origin; secret-bearing traces were disabled.

### Validation

| Check | Result |
| --- | --- |
| Latest candidate Playwright, desktop and mobile | 32 passed, no retries |
| SDK unit suite | 62 passed; two network cases intentionally skipped |
| SDK read-only Monad network replay | Both network cases passed separately |
| SDK/frontend typechecks and UI production build | Passed |
| Frontend / product / terminal unit suites | 17 / 3 / 14 passed |
| Media / indexed-record / vault regression suites | 5 / 6 / 7 passed |
| Existing fixture browser matrix | 91 passed directly, one passed on retry, ten intentional device skips |
| Bonding lifecycle assertions, both themes and viewports | 16 passed |
| Registry contract unit tests | Four passed |
| Pinned-fork WMON wrap/transfer/Kuru graduation qualification | One passed |
| Pinned-fork native MON and Circle USDC graduation | Two passed |
| UI review | Four files reviewed, zero findings |

All fork actions used local fixture contracts at block 70,709,403; no live transactions were broadcast. The candidate browser suite covers real indexed Monad listings (11 MON-paired launches at inspection), quote identity and review economics, reference previews without signing, independent logos/fallbacks, filters, SDK orderbook, responsive layouts, wallet picker, Mera/Earn, referral routing and console/overflow checks. Error recovery uses explicitly routed test responses; no fixture launch is inserted into live discovery.

Evidence and [changed-file inventory](../../../evidence/platform/frontend/browser-validation/20261013-multi-asset-candidate/CHANGED_FILES.txt) are retained under `evidence/platform/frontend/browser-validation/20261013-multi-asset-candidate/`. Representative screenshots: [desktop picker](../../../evidence/platform/frontend/browser-validation/20261013-multi-asset-candidate/screenshots/staging-desktop-1440-quote-picker.png), [mobile picker](../../../evidence/platform/frontend/browser-validation/20261013-multi-asset-candidate/screenshots/staging-mobile-390-quote-picker.png), [discovery](../../../evidence/platform/frontend/browser-validation/20261013-multi-asset-candidate/screenshots/staging-desktop-1440-discovery.png), [USDC review](../../../evidence/platform/frontend/browser-validation/20261013-multi-asset-candidate/screenshots/staging-desktop-1440-usdc-review.png), [graduated orderbook](../../../evidence/platform/frontend/browser-validation/20261013-multi-asset-candidate/screenshots/staging-desktop-1440-graduated-orderbook.png), [mobile trading ticket](../../../evidence/platform/frontend/browser-validation/20261013-multi-asset-candidate/screenshots/staging-mobile-390-mobile-ticket.png).

### Metadata evidence and limits

The catalog has 66 sourced logo slots (WMON shares the native logo) and 17 stable text fallbacks. The source-check log records 73 HTTP successes and ten transport/access failures across 83 source requests; all 24 stock metadata requests succeeded. A successful source fetch verifies reference identity, not a token deployment or integration. Supplemental primary sources for affected references include [ARB](https://docs.arbitrum.foundation/concepts/arb-token), [AAVE](https://www.aave.com/docs/ecosystem/aave), [OpenAI](https://openai.com/about), [Polymarket](https://help.polymarket.com/en/articles/13364060-what-is-polymarket), [Kalshi](https://kalshi.com/about), [EURC](https://www.circle.com/eurc), [GUSD](https://www.gemini.com/dollar) and [PAXG](https://docs.paxos.com/guides/stablecoin/paxg). Reference contracts/mints, decimals and quote/USD feeds remain unverified unless explicitly populated. Custom addresses are unverified reference metadata until independent contract-backed admission succeeds.

### Proposed onchain next steps — approval required

[WMON_UNSIGNED_PROPOSAL.json](WMON_UNSIGNED_PROPOSAL.json) contains a read-only estimate for a **Kuru-only** admission proposal at block 70,715,398. Proposed version-one policy uses 18 decimals, phantom/threshold one unit and ceiling 50 units, retaining the existing 1,000-token profile. The estimate was 161,279 gas at 102 gwei, approximately **0.016450458 MON**; it is time-bound and must be refreshed. The manifest/registry operator wallet held approximately 9.236 MON and zero Circle USDC at that block. Wallet funding evidence covers that wallet only. WMON can be funded by wrapping native MON after separate approval; no wrapping or funding action occurred here.

Remaining WMON gates: two-actor trading, creator-fee/buyback variants, fresh identity/version and funding checks, and operator review of the final transaction. Uniswap V4 remains unqualified for WMON, so no two-venue permission is proposed. Existing fork results support the minimum Kuru profile, not comprehensive security certification. Local fork test gas (including assertions) is not a live transaction estimate.

The third onchain demo remains blocked by these qualification gates and explicit approval. USDC is admitted, but funding and a new signed live USDC demo remain pending. Stock/private/company/commodity references have no executable Monad support. No quote/USD source is configured; financial values retain their quote units. Promotion of this candidate and any registry/token transaction require separate explicit user approval.

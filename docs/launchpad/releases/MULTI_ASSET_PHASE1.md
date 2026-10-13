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

A separate unbacked `rpTestWBTC` proposal remains **not deployed**, with no address assigned. Suggested test-only identity: "RetroPick Test Bitcoin representation", symbol `rpWBTC`, eight decimals, fixed transparent mint policy; no Bitcoin reserves, redemption, issuer backing or official WBTC affiliation. Before admission: review exact runtime/issuance powers, transfer/approve compatibility and freeze/rebase/fee behavior; qualify phantom/threshold/ceiling and both requested venues on a pinned fork; prove Kuru grid/seed/fill compatibility, LP/excess locks, creator fees and two-actor trading; fund operator/test wallets; estimate gas against then-current RPC gas price. No permission or financial parameters are proposed as approved by this report.

## Demo narratives and limitations

1. MON: discover a real indexed native launch, show goal/progress and graduate-market SDK orderbook; actual new launch signing remains a user action.
2. USDC: select the verified Circle address and review admitted economics. Wallet funding and a fresh live USDC launch/graduation must be separately evidenced; prior qualification reports marked funding blocked.
3. WMON: explain native wrapper identity and preview while permission is absent. Only after operator approval and complete compatibility evidence may it become executable. `rpTestWBTC` is a distinct later proposal, not a replacement or alias for this wrapper.

Validation results, candidate URL/SHA, screenshots and remaining blockers are appended after candidate testing.

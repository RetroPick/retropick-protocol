# Envio Market Quality Radar

RetroPick uses Envio HyperSync on Monad Testnet (chain 10143) to power the Market Quality Radar in the canonical `apps/retro-ui` token terminal. The public product is https://retropick.xyz. This integration is a standalone package; installing its dependencies does not alter the legacy frontend.

The Radar joins launch, commitment, protected-graduation and Kuru orderbook events. It turns those logs into lifecycle phase, graduation latency, time to first Kuru trade, historical filled base amount, gross MON trading volume, created orders, deduplicated cancellations and last-trade age. These measures help a trader distinguish a graduated market from a recently active market. They are historical observations; live executable orderbook depth comes from direct verified contract reads.

## Current qualification

Verified 2026-10-14 GMT+7: the existing public Envio pipeline is live, but its old aggregation has incorrect Kuru unit normalization and double-counts overlapping cancellation events. The corrected aggregation version 4 passed **35/35 tests** and an isolated real HyperSync catch-up with **lag 0, canonical anchor verified**. Production backend upgrade is **PENDING_ACCESS**, because the configured VPS SSH routes reject their keys. Do not represent the corrected backend as already deployed.

Evidence is under `evidence/hackathon/metropolis/submission-20261014/radar-correction/`: `live-candidate.json`, `live-candidate-health.json`, `apex-before-upgrade.json` and `envio-redeploy-readiness.json`. Current production responses are available through `/api/radar/health` and `/api/radar/radar` on the public product. Verify `aggregationVersion: 4` before relying on normalized amounts. The matching frontend correction treats legacy or unverified amounts as unavailable.

## Correctness and recovery

- Exact integer arithmetic uses the market's verified `sizePrecision`, token decimals and native MON quote. Market parameters, Router registration and Kuru environment validation are read at the same block; unavailable or unsupported parameters leave amounts **null**, never invented zero.
- Gross quote volume is `sum(price × filledSize) / sizePrecision`; base units are `sum(filledSize) × 10^baseDecimals / sizePrecision`. It is gross traded amount, not guaranteed net settlement or fee-adjusted proceeds.
- Raw logs are journaled durably. Version 3 snapshots migrate through preserved raw-journal replay to schema 4. Cursor advancement, crash recovery, delivery deduplication, cancellation semantic deduplication, canonical anchors and reorg replay are tested.
- Pipeline freshness and market activity freshness are separate. A current cursor can coexist with a market whose last trade was days ago. These testnet events do not prove organic users or production liquidity.
- The service has no signing key or financial write method. Indexer data never replaces onchain economic authority.

## Run and validate

```sh
cd integrations/envio-market-radar
npm ci
npm test
# Supply ENVIO_API_TOKEN through the existing protected environment file.
node --experimental-strip-types src/server.ts
```

Node 24+ is required. The HTTP server binds loopback port 8791. Configure `RADAR_CHAIN_ID`, `RADAR_FACTORY`, `RADAR_COORDINATOR`, `RADAR_FROM_BLOCK`, `RADAR_STATE_DIR` and read-only `RADAR_RPC_URL` to match the deployed release. An optional `RADAR_MARKET_TOKENS` mapping bootstraps historical markets; `GraduationCompleted` supplies authoritative lifecycle joins. Preserve protected credentials and the existing raw journal during upgrades. The endpoint is token-gated and free-plan request limits can delay catch-up; no credentials are returned by the API.

This project uses the **HyperSync client** path allowed by the Envio bounty, rather than claiming a HyperIndex deployment. The public client code and event aggregation are `src/stream.ts`, `src/radar.ts`, `src/journal.ts` and `src/market-params.ts`. The frontend consumer is `apps/retro-ui/src/lib/live/radar-client.ts` and `apps/retro-ui/src/features/launchpad/terminal/market-radar.tsx`.

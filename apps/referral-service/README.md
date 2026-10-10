# Referral attribution service

Node 24 SQLite service for offchain referral ownership and confirmed-event attribution. It holds no keys or funds and does not sign transactions. The indexer remains a separate GET-only history service.

Run `pnpm --filter @retropick/referral-service start`. Configure the values in `.env.example` in the process environment. `REFERRAL_ORIGIN` must equal the browser's exact application origin. Proxy `/api/referrals` from retro-ui to `http://127.0.0.1:8788` without rewriting the path. Production requires HTTPS; deploy the service behind that same-origin proxy and protect the SQLite file as personal application data.

POST `/api/referrals/challenge` takes `{wallet,referrer?,firstSeenAt?}`. POST `/api/referrals/verify` takes `{challengeId,signature}` and sets a one-hour HttpOnly SameSite=Strict session cookie. GET `/api/referrals/summary` returns only that authenticated wallet's attribution. POST `/api/referrals/logout` revokes its cookie. All POST requests require the configured Origin; all responses use `no-store`. Signatures are verified transiently and never stored or logged. Health is GET `/api/referrals/health`.

The 15-second worker consumes only confirmed `/v1/activity` windows from the trusted configured indexer. A window is applied atomically after every page succeeds. Cursor changes leave the previous projection intact until retry. Every poll rescans 512 blocks, and a changed reorg revision triggers replay from the earliest association. Orphaned qualifications and quote volume are removed when the canonical window changes. Failures appear as `syncError`; displayed analytics carry the last successful freshness envelope.

`pnpm --filter @retropick/referral-service test` covers signature ownership/replay, immutable association, invalid input, cookie/Origin boundaries, confirmed activities and reorg rollback. See `docs/product/REFERRAL_SYSTEM.md` for the product and privacy contract.

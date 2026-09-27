# RetroPick Launchpad frontend handoff

## Goal and phase

This is the PRODUCT-1-facing UI prototype for RetroPick + PRISM. It is a `SUPPORTED_BY_SIMULATION` frontend artifact, not a protocol deployment or a claim that integration gates are complete. The controlling dependency order remains `SPEC-1 -> MATH-1 -> CONTRACT-ARCH-1 -> CONTRACT-1 -> INTEGRATION-1 / PRODUCT-1 -> E2E-1 -> SUBMISSION-1`.

## Commands and evidence

Run from the repository root with Node 22.13+ and pnpm 11.25.0:

```sh
pnpm install --frozen-lockfile
pnpm typecheck:web
pnpm lint:web
pnpm test:web
pnpm build:web
```

The application packages bounded math tests in `apps/web/tests/domain.test.mjs` and instrument normalization, taxonomy, registry, dispatch and duplicate-prevention tests in `apps/web/tests/launchpad-taxonomy.test.mjs`. Browser QA should cover the single mixed Token Feed, URL filters, separate YES/NO detail routing and the existing responsive table overflow.

## Boundaries that may not change

- Native complete set: 1 collateral unit ⇄ 1 YES + 1 NO; do not report OI as YES supply + NO supply.
- Native and PRISM lifecycle vocabulary must remain separate.
- PRISM v1 remains a nonnegative exact-backed basket: `h = Gx`, `x >= 0`, `B_i >= S*x_i`.
- Retail PRISM purchase is secondary trading; it cannot mint or change backing.
- `RESOLVED` is not `REDEEMABLE`; payout must also be funded.
- Protocol backing, order reservations, LP inventory, fees and settlement funds are distinct domains.

## Live integration checklist

Before replacing mock mode, a reviewed integration must provide admitted deployment configuration, immutable market `ResolutionSpec` commitments, verified wallet/chain checks, actual venue quote freshness, receipt/indexer reconciliation, exact vault/supply backing state, final settlement funding, and evidence IDs. Do not manufacture addresses, hashes, transaction receipts, balances or a best-route claim. Kuru is presented as the future execution venue; Uniswap v4 and Polymarket remain explicitly planned, separate sources.

## Residual risks

The browser session is a presentation ledger only. It is reset on reload, uses illustrative pricing and cannot serve as financial accounting, a proof, an oracle, a wallet integration or a settlement system. The local normalized basket builder is intentionally not a general nonlinear payoff solver.

## Launchpad extension

The main product route is now `/launchpad?type=all|prediction|crypto|stocks`.
It is a typed presentation extension, not a protocol deployment. Prediction,
normal token and illustrative PRISM entries normalize to `LaunchInstrument` and
share one Token Feed. Instrument kind is separate from reference class, pair,
chain and contract family. A BTC-referenced prediction can appear under Crypto
and Prediction while remaining one prediction instrument with the same ID.
Prediction topic, such as `Crypto`, is used only in the topic selector; USDC
collateral does not turn every prediction into a crypto reference.

Stock-paired items are normal token-launch fixtures. Their quote assets,
market data and lifecycle are all `DEMO`; a stock-paired token never represents
equity in the named company. `GRADUATED · Kuru` means a target lifecycle in the
demo, not an available Kuru execution route.

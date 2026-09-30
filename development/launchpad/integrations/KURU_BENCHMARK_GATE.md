# Kuru benchmark gate — incremental research status

This document defines the detailed B1–B12 qualification rows for Launchpad Core V2 → Kuru. The current [machine-readable row record](../../../evidence/launchpad/kuru/kuru-benchmark-gates-2026-09-30.yaml) is subordinate to the Launchpad [control-plane summary](../control/status.yaml); it does not independently authorize a production executor. `PASS`, `FAIL`, `BLOCKED_EXTERNAL`, `DECISION_REQUIRED`, and `NOT_RUN` are the only benchmark-row statuses.

| Row | Acceptance evidence | Current status |
| --- | --- | --- |
| B1 environment | Official source pins, chain ID, live Router/MarginAccount/implementation getters and block-pinned runtime code hashes | PASS at recorded block; must recheck drift |
| B2 quote | Named MON/Circle-USDC assets, exact transfer/allowance path, Kuru compatibility and issuer controls | DECISION_REQUIRED: pinned Circle fork path passes one profile; issuer risk, remaining profiles and ADR-011 remain |
| B3 parameters | Exact tuple derivation for supported profiles; real Router deployment; accepted ADR-021 | DECISION_REQUIRED |
| B4 seed | Exact floor/tick bounds and accepted cap; real vault opening readback | DECISION_REQUIRED |
| B5 fork deploy | Real `deployProxy`, expected deterministic market/vault, independent state readback | PASS for pinned research fixture |
| B6 vault seed | Real first deposit, physical balances, LP arithmetic, bid/ask and order sizes | PASS for pinned research fixture |
| B7 custody | Protected LP/excess-token lock with negative authority tests and accepted ADR-022 | NOT_RUN as a complete gate; partial no-exit fixture passed |
| B8 retry | Atomic failure, unchanged secured assets, same-launch retry and replay rejection; accepted ADR-023 | NOT_RUN as a complete gate; five injected reversions, forced Router revert, false registry, retry and replay passed |
| B9 drift | Implementation, code-hash, MarginAccount, Router and observable pause mismatches stop new completion | NOT_RUN as a complete gate; OrderBook/vault-code and MarginAccount variants passed |
| B10 gas | Full phase-2 MON/USDC small/medium/large fork distributions and target-chain headroom | NOT_RUN as a complete gate; one native research delta measured |
| B11 live testnet | Approved tiny research graduation with block, receipts and independent state | NOT_RUN |
| B12 usability | Two controlled actors create/fill/cancel orders and record book/events | NOT_RUN |

The B3/B4 [candidate matrix](../../../evidence/launchpad/kuru/parameter-profile-matrix-2026-09-30.json) is exact-integer model evidence, now challenged by [real-Router fork results](../../../evidence/launchpad/kuru/fork-deploy-seed-2026-09-30.md). The fork caught and corrected the model's first-bid denominator. [Quote identity research](../../../evidence/launchpad/kuru/quote-qualification-2026-09-30.md) records that Kuru-listed and Circle-listed testnet USDC are distinct contracts; the owner selected the Circle address for P0, not the Kuru compatibility fixture. No accepted market tuple, qualified Circle/Kuru path or five-bps seed/tick cap is asserted. `KURU_TARGET_FROZEN` can become `PASS` only when every material row passes and ADR-009/011/021/022/023 are explicitly accepted by the protocol owner. If technical rows pass but an economic choice remains open, report `KURU_TECHNICAL_BENCHMARK = PASS` and `KURU_TARGET_FROZEN = DECISION_REQUIRED`.

The supplied Actor A/B keystore environment is available for later B11/B12, but it is not a reason to skip fork qualification. No live transaction has been sent by this packet. `CORE_BASELINE_QUALIFIED` and `READY_FOR_DEV4_KURU_EXECUTOR` remain independently blocked. Do not create normative `docs/smart-contract/*` or production Kuru Solidity until the three gates genuinely pass.

The [Circle custody fork increment](../../../evidence/launchpad/kuru/circle-custody-fork-increment-2026-09-30.md) confirms that Circle quote is physically forwarded to Kuru `MarginAccount`, rather than retained as an ERC20 balance in the vault. This is one pinned research profile, not the completed B2/B10 or live usability gate.

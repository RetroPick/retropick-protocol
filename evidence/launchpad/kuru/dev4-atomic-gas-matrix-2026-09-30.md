# Candidate atomic phase-2 fork gas matrix — 2026-09-30

**Classification:** research-only, pinned Monad Testnet fork block `66752717`; not production executor gas. Baseline `ef53422c8a5b96baf28e718bb9211733f08e2372`, Forge 1.8.3, solc 0.8.26, optimizer 200, viaIR. Run `set -a; source .env.local; set +a; forge test --match-path test/v2/integration/KuruAtomicResearch.t.sol --match-test testCandidateAtomicGasMatrixNativeAndCircle -vv` from `contracts/`. Result: **1/1 PASS**, six distinct profile/quote combinations, no broadcast. Fork block gas limit reported `150,000,000`.

The research coordinator's atomic `complete` validates chain/Router getters and implementation hashes, derives CREATE2 identities, calls the real Kuru Router `deployProxy`, verifies Router/market/vault state, approves exact base/quote amounts, calls the real vault first deposit, checks LP receiver/shares, vault accounting, nonzero bid/ask order sizes, candidate 5-bps opening-price cap, exact remaining balances and (for Circle) exact MarginAccount physical quote increase, locks excess launch tokens, then records `GRADUATED` last. It is **not** the Core Factory, the final DEV-4 executor or an accepted price policy. Its protected receiver is the research no-exit lock, which is not yet B7-qualified.

All gas figures are single in-test `gasleft()` deltas; they are not p50/p95, receipts or a production SLO. The failure column injects a revert immediately after real Router deployment; the successful column retries the same durably secured launch; replay is rejected after success.

| Quote | Profile | Original supply | P / Q (nominal quote) | Failed attempt | Successful retry | Replay rejection |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| MON | small | 100,000 | 10 / 11 | 1,182,043 | 1,617,207 | 51,128 |
| MON | medium | 1,000,000 | 100 / 97 | 1,182,043 | 1,617,207 | 51,128 |
| MON | large | 100,000,000 | 1,000 / 1,001 | 1,182,043 | 1,617,255 | 51,128 |
| Circle USDC | small | 100,000 | 10 / 11 | 1,354,979 | 1,894,857 | 51,128 |
| Circle USDC | medium | 1,000,000 | 100 / 97 | 1,354,979 | 1,877,887 | 51,128 |
| Circle USDC | large | 100,000,000 | 1,000 / 1,001 | 1,354,964 | 1,877,906 | 51,115 |

The largest measured candidate delta is `1,894,857`, approximately **1.27%** of the fork block gas limit. This is broad block-limit headroom for the sketch, **not** a proof of operational feasibility for an integrated Factory/coordinator/executor transaction, per-transaction RPC policy or future Kuru implementations. The loop shares one fork/test transaction and gas warmness can differ by row; independent repeated fresh-fork runs and gas receipts remain desirable. The `failed` and `replay` deltas also include Foundry `expectRevert` test instrumentation.

**Remaining B10 work:** measure the accepted final architecture with Factory phase-1/phase-2 wiring and protected lock, repeated fresh-fork samples, explicit failure-boundary and finalization costs, current Monad transaction/block constraints, and the accepted min/max launch envelope. Therefore KURU-B10 and `KURU_TARGET_DEV_FROZEN` remain **NOT PASS**.

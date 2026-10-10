# Metropolis Integration Handbook — agent navigation
**Research refresh:** 2026-10-11. **Repo target:** `RetroPick/retropick-protocol` on Monad Testnet (10143). **Track:** Onchain Finance & Trading. **Deadline:** 2026-10-14 10:59 Asia/Jakarta (recheck authenticated portal). **Status:** architecture/research; no integration proven merely by documentation.

## Read order
1. [00 Master Plan](00-MASTER-PLAN.md): delivery, scope and priority.
2. [10 Verified Sources & Corrections](10-VERIFIED-SOURCES.md): first-party exact API/CLI references, chain constraints, version and known false assumptions.
3. [11 Integration Execution Protocol](11-EXECUTION-RUNBOOK.md): agent discovery, branch isolation, state machine, tests, release gates and evidence packet.
4. [12 Sponsor Innovation & Scoring](12-SPONSOR-INNOVATION.md): product differentiation, judge demonstrations and sponsor-by-sponsor strategies.
5. [09 Agent Handoff](09-AGENTS-HANDOFF.md): security, chain, read-only RPC, custody.
6. Choose ONE of the eight [01 Aurora](01-AURORA-ALLINONE.md), [02 Kuru New Assets](02-KURU-NEW-ASSETS-ALLINONE.md), [03 Mera PRF](03-MERA-PRF-ALLINONE.md), [04 MetaMask](04-METAMASK-AGENT-ALLINONE.md), [05 Envio](05-ENVIO-ALLINONE.md), [06 Kuru Consumer](06-KURU-CONSUMER-ALLINONE.md), [07 CRE](07-CHAINLINK-CRE-ALLINONE.md), [08 Nansen](08-NANSEN-ALLINONE.md).

## Key repo reality
- **Deployed V2** token launch → bonding curve → Graduation Coordinator → Kuru spot orderbook, real testnet receipts, no audit/mainnet clearance.
- **Existing research prototypes**: `research/contract-kernels/src/hackathon/PredictionFactoryP0.sol`, `PredictionMarketP0.sol`, `research/contract-kernels/test/hackathon/PredictionP0.t.sol`, `research/hackathon-p0/PRISM_P0_SPEC.md`. They are **not** evidence that P0/PRISM contracts are on Monad. Qualify and reuse kernels rather than writing another factory.
- `apps/web/features/create-market/wizard.tsx` saves a **local demo draft**, and `apps/web/features/prism/prism.tsx` labels values as **illustrative**. Never advertise those UI paths as deployed market creation or live PRISM.
- `apps/web/lib/live/wallet.tsx` and `apps/web/features/live/kuru.tsx` run wallet-mediated V2 testnet Kuru actions. Existing `apps/indexer/src/project.ts` is a non-Envio TypeScript projection.
- `apps/web/README.md` describes older simulated frontend semantics and may be stale relative to the V2 live README. Examine the **current entry route and package scripts** before assigning frontend patches; don't promote a stale README above code.
- Do not modify current V2 factory or permanent liquidity lock to bolt on sponsor demos.

## Delivery discipline
For each sponsor: **capability spike → verified small proof → API/contract adapter → user flow → adversarial tests → evidence → honest submission.** Stop early if no compatible network/token, license, SDK or wallet policy. Use `[VERIFIED_SOURCE]`, `[VERIFIED_LOCAL]`, `[UNVERIFIED]`, `[BLOCKED]` labels in PRs. Release evidence remains authoritative, not slideware.

## Suggested agent parallel ownership
**A** Kuru consumer & E2E, **B** Envio event index, **C** Mera vault, **D** MetaMask CLI plugin, **E** Aurora 4-hour go/no-go, **F** research kernel P0 qualification (independent security gate). CRE and Nansen are opt-in only after gates clear. One integrator owns frontend collision handling and PR merges.

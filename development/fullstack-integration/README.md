# V2 Fullstack Integration Campaign

Owner lane for goal `RETROPICK-V2-FULLSTACK-INTEGRATION` (see `goals/active/RETROPICK-V2-FULLSTACK-INTEGRATION.md`).

Objective: operate the deployed Monad Testnet V2 launchpad (chain 10143) through the canonical frontend `apps/retro-ui` — Discover → Connect Wallet → Create Token → Bonding-Curve Buy/Sell → Graduation → Kuru Trading → Portfolio/Creator Claims — with every financial write contract-correct and on a security-approved allowlist.

Baseline: `41df325` on `codex/v2-abi-catalog-verification`; integration branch `codex/v2-fullstack-integration`.

## Artifacts

| Artifact | Path | Phase | Status |
|---|---|---|---|
| ABI capability map (human) | `docs/contracts/V2_APPLICATION_CAPABILITY_MAP.md` | P1 | DONE |
| ABI capabilities (machine) | `development/fullstack-integration/abi-capabilities.json` | P1/P7 | DONE |
| Frontend reverse map | `docs/frontend/RETRO_UI_REVERSE_MAP.md` | P2 | DONE (8d8650a, H2) |
| Create-form ABI map | `docs/frontend/CREATE_FORM_ABI_MAP.md` | P2 | DONE (8d8650a, H2) |
| ABI screen map | `docs/frontend/ABI_SCREEN_MAP.md` | P2 | DONE (8d8650a, H2) |
| Frontend write allowlist (security) | `development/fullstack-integration/write-allowlist.md` | P3/P7 | P3 DONE (H3: 17 APPROVED / 3 APPROVED-WITH-CONDITIONS / 0 REJECTED; SDK conditions C-1..C-9); P7 re-verify PENDING |
| Specialist handoffs | `development/fullstack-integration/handoffs/` | all | PENDING |
| Final campaign report | `development/fullstack-integration/FINAL_REPORT.md` | P9 | PENDING |

Evidence lives in `evidence/launchpad/fullstack-integration/`.

## Capability matrix (tracked to completion)

| CAPABILITY | SELECTED SKILL | AGENT | TASK | EVIDENCE | STATUS |
|---|---|---|---|---|---|
| MONAD_DEVELOPMENT | chain-monad | orchestrator | chain 10143 config, RPC identity, receipts | readiness.json | PENDING |
| SOLIDITY_FOUNDRY | evm-foundry, solidity-foundry, contract-verification | CONTRACT_AGENT | ABI semantics, overload regression, fork sim | P1/P7/P8 | PENDING |
| SMART_CONTRACT_SECURITY | smart-contract-security, evm-security | SECURITY_AGENT | write allowlist, trust boundaries | H3 + write-allowlist.md | IN_PROGRESS — P3 allowlist decision done vs deployed source pin f0363249 (17/3/0 verdicts, exclusion list, max-payable/approval matrix, SDK defects C-1 prepare.ts:218-220 & C-6 decode.ts:77); PASS awaits P7 gate-close re-verification |
| FULLSTACK_SDK | backend-engineering-edho-ferdian | SDK_AGENT | write boundary + tx engine | P3/P5 | PENDING |
| REACT_FRONTEND | frontend-engineering-edho-ferdian | FRONTEND_AGENT | live reads + flows | P4/P6 | IN_PROGRESS — P2 reverse-mapping/ABI maps + baselines done (H2); PASS awaits P4/P6 |
| RADIX_ACCESSIBILITY | frontend-engineering-edho-ferdian | FRONTEND_AGENT | dialog/select/sheet correctness | P6/P8 | IN_PROGRESS — P2 inventory of Radix surfaces done (H2); PASS awaits P6/P8 |
| INDEXER_ENGINEERING | backend-engineering-edho-ferdian | INDEXER_AGENT | API coverage + live wiring | P4 | PENDING |
| GSTACK_BROWSER_QA | gstack (browse) | QA_AGENT | baselines, E2E, regression | P2/P8 | PENDING |
| FOUNDRY_TESTING | evm-foundry | QA_AGENT | fork-simulated write flows | P8 | PENDING |
| WEB3_WALLET_INTEGRATION | chain-monad + viem EIP-6963/1193 | SDK_AGENT/FRONTEND_AGENT | wallet + live testnet txs | P5/P8 | PENDING |

Status vocabulary: PASS | BLOCKED | UNAVAILABLE (+ explanation). A capability is only marked PASS with evidence that it was exercised in its actual implementation phase.

## Constraints (binding)

Inherited from the goal file: no UI redesign, no Solidity edits/redeploys, no PRISM/Prediction, no new dependencies (viem only), 10 tsc-compiled retro-ui domain files stay workspace-free, ABI single-source, exact bigint, fail-closed mock/live, secrets never in-repo, no mainnet, no auto-merge.

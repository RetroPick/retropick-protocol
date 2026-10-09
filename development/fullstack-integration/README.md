# V2 Fullstack Integration Campaign

Owner lane for goal `RETROPICK-V2-FULLSTACK-INTEGRATION` (see `goals/active/RETROPICK-V2-FULLSTACK-INTEGRATION.md`).

Objective: operate the deployed Monad Testnet V2 launchpad (chain 10143) through the canonical frontend `apps/retro-ui` — Discover → Connect Wallet → Create Token → Bonding-Curve Buy/Sell → Graduation → Kuru Trading → Portfolio/Creator Claims — with every financial write contract-correct and on a security-approved allowlist.

Baseline: `41df325` on `codex/v2-abi-catalog-verification`; integration branch `codex/v2-fullstack-integration`.

## Artifacts

| Artifact | Path | Phase | Status |
|---|---|---|---|
| ABI capability map (human) | `docs/contracts/V2_APPLICATION_CAPABILITY_MAP.md` | P1 | PENDING |
| ABI capabilities (machine) | `development/fullstack-integration/abi-capabilities.json` | P1/P7 | PENDING |
| Frontend reverse map | `docs/frontend/RETRO_UI_REVERSE_MAP.md` | P2 | PENDING |
| Create-form ABI map | `docs/frontend/CREATE_FORM_ABI_MAP.md` | P2 | PENDING |
| ABI screen map | `docs/frontend/ABI_SCREEN_MAP.md` | P2 | PENDING |
| Frontend write allowlist (security) | `development/fullstack-integration/write-allowlist.md` | P3/P7 | PENDING |
| Specialist handoffs | `development/fullstack-integration/handoffs/` | all | PENDING |
| Final campaign report | `development/fullstack-integration/FINAL_REPORT.md` | P9 | PENDING |

Evidence lives in `evidence/launchpad/fullstack-integration/`.

## Capability matrix (tracked to completion)

| CAPABILITY | SELECTED SKILL | AGENT | TASK | EVIDENCE | STATUS |
|---|---|---|---|---|---|
| MONAD_DEVELOPMENT | chain-monad | orchestrator | chain 10143 config, RPC identity, receipts | readiness.json | PENDING |
| SOLIDITY_FOUNDRY | evm-foundry, solidity-foundry, contract-verification | CONTRACT_AGENT | ABI semantics, overload regression, fork sim | P1/P7/P8 | PENDING |
| SMART_CONTRACT_SECURITY | smart-contract-security, evm-security | SECURITY_AGENT | write allowlist, trust boundaries | P3/P7 | PENDING |
| FULLSTACK_SDK | backend-engineering-edho-ferdian | SDK_AGENT | write boundary + tx engine | P3/P5 | PENDING |
| REACT_FRONTEND | frontend-engineering-edho-ferdian | FRONTEND_AGENT | live reads + flows | P4/P6 | PENDING |
| RADIX_ACCESSIBILITY | frontend-engineering-edho-ferdian | FRONTEND_AGENT | dialog/select/sheet correctness | P6/P8 | PENDING |
| INDEXER_ENGINEERING | backend-engineering-edho-ferdian | INDEXER_AGENT | API coverage + live wiring | P4 | PENDING |
| GSTACK_BROWSER_QA | gstack (browse) | QA_AGENT | baselines, E2E, regression | P2/P8 | PENDING |
| FOUNDRY_TESTING | evm-foundry | QA_AGENT | fork-simulated write flows | P8 | PENDING |
| WEB3_WALLET_INTEGRATION | chain-monad + viem EIP-6963/1193 | SDK_AGENT/FRONTEND_AGENT | wallet + live testnet txs | P5/P8 | PENDING |

Status vocabulary: PASS | BLOCKED | UNAVAILABLE (+ explanation). A capability is only marked PASS with evidence that it was exercised in its actual implementation phase.

## Constraints (binding)

Inherited from the goal file: no UI redesign, no Solidity edits/redeploys, no PRISM/Prediction, no new dependencies (viem only), 10 tsc-compiled retro-ui domain files stay workspace-free, ABI single-source, exact bigint, fail-closed mock/live, secrets never in-repo, no mainnet, no auto-merge.

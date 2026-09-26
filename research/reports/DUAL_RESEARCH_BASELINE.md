# Dual Research Baseline

**Status:** live baseline recorded before new financial-model code or Solidity  
**Recorded at:** 2026-09-26  
**Classification of this document:** MEASURED_LOCAL observations plus INFERRED readings of repository authority  
**Base commit:** `73d5f1e72b65cc5cdad0d940782c192aa331f5ed`  
**Working branch created after this measurement:** `cursor/finance-qualification-bbd4` (no code delta at measurement time)

This file is the Phase-0 record for the Prediction Token / Market kernel and PRISM. It does not promote either module.

## Repository HEAD

| Field | Value |
|---|---|
| Remote | `origin` = `https://github.com/RetroPick/retropick-protocol` |
| Default branch | `origin/HEAD` -> `origin/main` |
| Local branch at fetch | `main` |
| HEAD | `73d5f1e72b65cc5cdad0d940782c192aa331f5ed` |
| `origin/main` | same SHA after `git fetch origin` |
| Ahead/behind | none |
| HEAD subject | `fix(web): allow managed responsive preview host` |
| Working tree | clean (`git status --porcelain` empty) |
| Git identity | `Cursor Agent <cursoragent@cursor.com>` (existing config, not overridden) |

Other remote branches present at fetch:

- `origin/main`
- `origin/cursor/setup-dev-environment-1971`
- `origin/feat/retropick-launchpad-web`

No prediction or PRISM implementation branch was the live HEAD.

## Product ontology (verified against live authority)

Live authority agrees on one platform and three financial modules:

```text
RETROPICK PLATFORM
  = Launchpad Core
    + Prediction Module
    + PRISM Module
```

Sources read: `AGENT_GUIDE.md`, `AGENTS.md`, `.agent/README.md`, `.agent/STATE.json`, `.agent/CURRENT_GOAL.md`, `.agent/ROUTING.md`, `.agent/DECISIONS.md`, `.agent/WORKFLOW.md`, `docs/platform/README.md`, `docs/platform/MODULE_MODEL.md`, `docs/platform/ASSET_TAXONOMY.md`, `docs/platform/MODULE_PROMOTION.md`, `docs/README.md`, `docs/prism/README.md`.

| Module | What it is | What it is not |
|---|---|---|
| Launchpad Core | fixed/capped launch ERC-20, bonding primary, graduation, Kuru as target mature venue | prediction outcome token; PRISM series token |
| Prediction Module | event -> fully collateralized outcome assets -> ERC-20 YES/NO -> secondary trading | launch token; PRISM replication |
| PRISM | supported source assets -> exact non-negative replication -> backing first -> PRISM ERC-20 series -> secondary trading | a second copy of the prediction market; Kuru inventory |

Accepted separation already in `.agent/DECISIONS.md`: native prediction-market creation and PRISM-series creation are separate pipelines (D-007). Backing, LP inventory, market-maker inventory, fees, and settlement funds are separate accounting domains (D-008). `RESOLVED` and `REDEEMABLE` are distinct (D-006 / ADR-006).

`contracts/src/v2/RetroPickLauncherTokenV2.sol` is the Launchpad launch token. It is not a prediction outcome token and is not a PRISM series token.

## Current branches

Local branch at the start of this program: `main` tracking `origin/main`.

Feature branch for this program: `cursor/finance-qualification-bbd4`, created from that same commit before any file in this program was written.

## Current gates

### Launchpad Core

Source: `development/launchpad/control/status.yaml`.

| Gate | Status |
|---|---|
| control plane | pass, validated_commit `7c24e20e88cfaa1c6e71d953a949670f64392d31` |
| DEVELOPMENT_READY | in_progress |
| HACKATHON_READY | blocked |
| STAGING_READY | blocked |
| MAINNET_CANDIDATE | blocked |
| MAINNET_AUTHORIZED | blocked |

Blockers recorded there: `BLOCK-CONTRACT-TESTS`, `BLOCK-KURU-TARGET`, `BLOCK-ARCH-ADRS`, `BLOCK-FULLSTACK`.

Launchpad release status does not transfer to Prediction or PRISM.

### Prediction

`.agent/STATE.json` records `state: RESEARCH`, `production_track: false`, `qualification: MODULE_SPECIFIC`.

There is no `docs/prediction/` tree and no prediction-specific gate file. Canonical prediction lifecycle text currently lives inside `docs/prism/protocol/STATE_MACHINE.md` and `docs/prism/protocol/INVARIANTS.md` (`INV-N01`..`INV-N05`).

No PRED-RESEARCH / PRED-SPEC / PRED-CONTRACT gate has a machine-readable pass in this commit.

### PRISM

| Item | Live value |
|---|---|
| Module state | RESEARCH |
| Production track | false |
| Current goal | `METROPOLIS-P1-MATH-1` (`goals/active/METROPOLIS-P1-MATH-1.md`) |
| Current gate | MATH-1, `math_gate: IN_PROGRESS` |
| Production Solidity authorized | false |
| Protocol mode | exact-backed long-only replication |
| Phase control | `docs/prism/05-hackathon/PHASE_GATES.md` |
| Accepted ADRs | ADR-001 through ADR-007 |

`docs/platform/MODULE_PROMOTION.md` path: RESEARCH -> SPEC -> MATH-1 -> MARKET-THESIS VALIDATION -> CONTRACT-ARCH-1 -> CONTRACT-1 -> MODULE-ADMISSION-PRISM-1 -> PLATFORM-INTEGRATION-1. None of the post-MATH gates are closed.

ADR-001 and ADR-007 block production Solidity until MATH-1, and CONTRACT-ARCH-1 must follow. `contracts/src/v2/` contains no PRISM or prediction kernel.

## Current implemented modules

Implemented in `contracts/src/` on this commit:

- Launchpad V1 reference contracts under `contracts/src/v1/`.
- Launchpad V2 development contracts under `contracts/src/v2/`: factory, deployer, launcher token, bonding curve, buyback vault, launch locker, graduation guard/executor, doorway, meme hook, math libraries.
- `contracts/README.md` states the committed graduation destination is still Uniswap-V4-oriented. Kuru is the target architecture and is not implemented.
- `apps/web/` exists as a Launchpad frontend workspace. `apps/` has no `api` or `indexer`. `packages/` contains only `README.md`.

Not implemented:

- Prediction market, outcome token, complete-set vault, or resolution contracts.
- PRISM series, backing vault, mint controller, or settlement contracts.
- Any file under `contracts/src/v2/prediction/` or `contracts/src/v2/prism/`.

Committed Foundry tests (`contracts/test/`) are Doorway-only: unit, fuzz, invariant, integration. `contracts/README.md` warns that these tests do not qualify Factory/Token/Curve/Graduation.

## Current research-only modules

| Path | Role |
|---|---|
| `docs/prism/` | canonical incubating Prediction + PRISM specification, math, architecture, phase gates |
| `research/prism-model/` | executable PRISM semantic oracle, including a reduced native complete-set model |
| `research/prism/` | incubation program, promotion gates, open questions, kill criteria, status notes |
| `contracts/docs/prism/` | implementation-facing requirements, not authorized production code |
| `research/production/` | Launchpad/platform production research. Out of this program's write scope except where ontology must stay consistent |
| `evidence/latest/` | 2026-09-17 PRISM reference-model notes |

`docs/prediction/` does not exist. `research/prediction-model/` does not exist. `research/contract-kernels/` does not exist.

## Current tests

Environment measured on this machine before new model code:

| Tool | At first probe | Later, still before new model code |
|---|---|---|
| Python | 3.12.3 | unchanged |
| Node | v22.14.0 | unchanged |
| pnpm | 11.25.0 | unchanged |
| forge | absent | installed Foundry 1.8.3 (`cae51ad458`, 2026-09-15) so the documented Foundry command could actually run |
| slither, echidna, medusa, halmos, mythril, semgrep, solhint | absent | still absent at baseline |
| sympy / z3 | absent | installed afterwards for later MATH-1E work; not used to claim any baseline pass |
| `node_modules` | absent at repo root and `apps/web` | web suite not run |

### PRISM reference model

Command, from `research/prism-model/`:

```bash
python3 -m unittest discover -s tests -v
```

Result: `Ran 55 tests in 0.031s` / `OK`. Exit 0.

Log: `evidence/research/baseline/prism-model-unittest-2026-09-26.txt`.

Classification: MEASURED_LOCAL. Domain: the tests that exist in this commit. This is not a MATH-1 pass.

```bash
python3 adversarial.py
```

Result matched the JSON already printed in `evidence/latest/MATH1_EXECUTABLE_GAPS_VALIDATION_2026-09-17.md`:

- fixed-point seed `20260917`, 5000 steps, 2961 mints, 2039 redeems, 20000 terminal checks
- reservation seed `20260917`, 5000 steps, 2800 reserves, 2196 releases, 4 rejected over-allocations, total reserved 9857

Classification: MEASURED_LOCAL. The historical adversarial counts were reproduced. They remain a bounded stress result, not a universal proof.

```bash
python3 scenarios.py
```

Exit 0. Includes the non-replicable AND counterexample (`AND replication: None`). Log: `evidence/research/baseline/prism-scenarios-2026-09-26.txt`.

Dependencies: the model imports only the Python standard library (`Fraction`, `unittest`, `random`). No `requirements.txt` or `pyproject.toml` is committed. Classification of "stdlib only": MEASURED_LOCAL by import inspection.

### Foundry

Documented command in `contracts/README.md`: `forge test` (also fmt, build, fuzz-runs).

First attempt with `--offline` failed: `can't install missing solc 0.8.26 in offline mode`. Classification: BLOCKED for that invocation only.

Second attempt, after Foundry 1.8.3 downloaded solc 0.8.26, from `contracts/`:

```bash
forge test -vv
```

Result: `45 tests passed, 0 failed, 0 skipped`. Suites: Doorway lifecycle, request, base, fuzz, invariant, e2e. Exit 0. Summary: `evidence/research/baseline/forge-doorway-summary-2026-09-26.txt`.

Classification: MEASURED_LOCAL. These tests exercise Doorway, not Launchpad V2 economics and not Prediction or PRISM. `contracts/README.md` already says this. A green Doorway suite is not module admission.

The run populated `contracts/lib/forge-std` content already pinned at `bf647bd6046f2f7da30d0c2bf435e5c76a780c1b` and did not leave a dirty git status.

### Web

`package.json` defines `test:web`. `apps/web` has no installed `node_modules`. The web suite was not run.

Classification: BLOCKED. Reason: dependencies are not installed in this workspace, and the web app is Launchpad UI rather than the financial oracle. No pass is invented.

## Current contradictions

These are recorded. They are not silently resolved by this baseline.

1. **Stale executable-test count.** `evidence/latest/MATH1_EXECUTABLE_GAPS_VALIDATION_2026-09-17.md` says `Ran 51 tests` / `OK`. Fresh discovery on this HEAD reports 55 tests / OK. The adversarial JSON in that note matches the fresh `adversarial.py` output. Classification of the "51 tests" sentence: STALE relative to HEAD `73d5f1e`. The underlying accounting tests that still exist were not shown false by this rerun.

2. **Native oracle is narrower than the canonical prediction state machine.** `docs/prism/protocol/STATE_MACHINE.md` specifies DRAFT, OPEN, LOCKED, RESOLUTION_PENDING, RESOLVED, REDEEMABLE, ARCHIVED, and separates result finality from redemption. `research/prism-model/native_market.py` implements only ACTIVE, RESOLVED, ARCHIVED. `resolve()` moves directly to a state in which `redeem()` is legal. That collapses canonical RESOLVED and REDEEMABLE for the native market. ADR-006 requires the split for PRISM settlement funding. The native oracle therefore does not implement the canonical prediction lifecycle. Classification: CONTRADICTION between canonical state machine and the executable native oracle. Affected implementation must not pretend those states already exist.

3. **Prediction lifecycle names are not unified.** Canonical native names are OPEN / LOCKED. The task program uses ACTIVE / MINT_CLOSED. PRISM uses ACTIVE / MINT_PAUSED (`research/prism-model/lifecycle.py`). These are different machines. Mapping ACTIVE->OPEN and MINT_CLOSED->LOCKED is a documentation alias, not an accepted rename. No ADR authorizes renaming the canonical native machine.

4. **CompleteSetVault is drawn as architecture and is not ADR-frozen as a separate contract.** `docs/prism/protocol/PRISM_PROTOCOL_SPEC.md` and `docs/prism/README.md` show a separate `CompleteSetVault`. `docs/prism/math/16_INVARIANTS.md` names `CompleteSetVault.split` as the future Solidity target. No accepted ADR decides separate vault versus market-as-controller. Treating the diagram as an immutable contract split would skip the required measurement. Treating the diagram as already deleted would overwrite canonical docs. Classification: unresolved canonical assumption. Implementation of a different split must be a proposed ADR, not a silent spec edit.

5. **Invalid / void is unspecified in the executable native model.** `docs/prism/math/17_THEOREMS.md` `T-NATIVE-002` says invalid/void policy must be specified separately. `BinaryCompleteSetMarket.resolve` rejects any winner other than YES or NO. A 1/2, 1/2 payout is not implemented and is not an automatic rule. Classification: NOT_YET_VALIDATED.

6. **Launchpad control status is behind the tree.** `development/launchpad/control/status.yaml` `validated_commit` is `7c24e20`, not HEAD `73d5f1e`. `BLOCK-FULLSTACK` says `apps/web`, `apps/api`, `apps/indexer`, and shared runtime packages are not implemented. `apps/web/` is present on this HEAD. `apps/api`, `apps/indexer`, and shared packages are still absent. Classification: STALE control-plane text for the web clause. This program does not edit the Launchpad lane to "fix" that sentence.

7. **Integer prediction redemption is not in the native oracle.** `native_market.py` uses `Fraction` and pays the winner 1:1 with no rounding residue. Collateral decimals, Kuru precision, and invalid dust are outside that file. `research/prism-model/README.md` fixed-point policy applies to PRISM series scale, not to a prediction integer kernel.

8. **Claim vocabularies differ by lane.** `docs/prism/math/17_THEOREMS.md` uses `PROVEN_UNDER_ASSUMPTIONS`, `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN`, `SUPPORTED_BY_SIMULATION`, `SUPPORTED_BY_LIVE_EVIDENCE`, `NOT_YET_VALIDATED`, `COUNTEREXAMPLE_FOUND`. `research/production/CLAIM_CLASSIFICATION.md` uses a different production-research set (`VERIFIED_CURRENT_FACT`, `MEASURED_LOCAL`, ...). This program uses the task's classification list, which extends the PRISM math list with `MEASURED_LOCAL`, `MEASURED_TESTNET`, `INFERRED`, `RECOMMENDATION`, and `BLOCKED`. It does not rewrite the production-research schema.

No contradiction found in the accepted ADR set ADR-001..ADR-007 on these points: math-first sequencing, `h=Gx` with `x>=0`, no Phase-1 BackingMirror, admission versus runtime checks, retail trade versus primary create, RESOLVED versus REDEEMABLE for PRISM funding, and hard phase gates. Those ADRs outrank the diagrams and the reduced native oracle.

## Current blockers

| ID | Blocker | Classification |
|---|---|---|
| B-PRED-SPEC | No standalone prediction specification directory or frozen token/market ADR | measured absence |
| B-PRED-MODEL | No `research/prediction-model/`; native oracle omits canonical lifecycle, invalid outcomes, and integer redemption | measured absence |
| B-MATH-1 | PRISM `math_gate` is `IN_PROGRESS`; fresh 55-test run is not a gate verdict | MEASURED_LOCAL |
| B-SOL-AUTH | Production Solidity for both modules is unauthorized | accepted ADR-001 / ADR-007 |
| B-VAULT-ADR | Separate CompleteSetVault versus colocated controller is undecided | unresolved canonical assumption |
| B-INVALID | Invalid/cancelled payout is not specified in the executable native model | NOT_YET_VALIDATED |
| B-KURU | Launchpad Kuru target API and parameter policy are unresolved (`BLOCK-KURU-TARGET`, ADR-021 PROPOSED). No prediction/PRISM Kuru compatibility file exists | BLOCKED for live integration claims |
| B-SEC-TOOLS | slither, echidna, medusa, halmos, mythril, semgrep, solhint were not installed at baseline | BLOCKED_TOOL until installed and run |
| B-WEB-TESTS | `pnpm test:web` not run; `node_modules` absent | BLOCKED |
| B-FORMAL | Historical theorem registry says Z3/SymPy artifacts are outside the oracle. Packages were absent at first probe | NOT_YET_VALIDATED at baseline |
| B-MAINNET | No agent may self-authorize mainnet deployment | accepted rule |

## What this baseline does not claim

- MATH-1 is not PASS, CONDITIONAL_PASS, or FAIL yet. The historical note left it open. This rerun does not close it.
- PRED-CONTRACT-1 is not PASS.
- MODULE-ADMISSION-FINANCE-1 is not met.
- Doorway Foundry success is not Launchpad V2 qualification and not financial-module qualification.
- No files were placed under `contracts/src/v2/`.

## Evidence

- `evidence/research/baseline/prism-model-unittest-2026-09-26.txt`
- `evidence/research/baseline/prism-adversarial-2026-09-26.txt`
- `evidence/research/baseline/prism-scenarios-2026-09-26.txt`
- `evidence/research/baseline/forge-doorway-summary-2026-09-26.txt`

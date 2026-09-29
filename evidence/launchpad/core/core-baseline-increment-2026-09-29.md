# Launchpad Core V2 qualification increment — 2026-09-29

**START_SHA:** `bbc1feae910a23a33113037d424aa2adc53b6fbe` (`origin/main` at fetch; no newer commits). Branch: `codex/launchpad-v2-core-qualification`. **Verdict:** `CORE_BASELINE_QUALIFIED = BLOCKED`; this is a first exact-arithmetic/Curve-state increment, not the required full Factory/Deployer/Token/Fee/Graduation suite. Production Solidity changed: **NO**.

## CURRENT / TARGET / DELTA / MIGRATION ORDER audit

| Source-confirmed item | CURRENT | Classification / target delta |
| --- | --- | --- |
| Factory | Owner-managed launch configs and quote approval/economics; creator launch record and frozen economics digest; V4 pool/position/hook/locker/executor dependencies | `CURRENT_ACCEPTED_BEHAVIOR` for implemented records/config path; dedicated authorization/launch tests still missing. |
| Deployer | `new` Curve then `new` Token; Factory initializes Curve; token supply minted wholly to Curve | `CURRENT_ACCEPTED_BEHAVIOR` for source wiring, dedicated Deployer/Curve/Token direct tests executed; Factory entrypoint still untested. |
| Token | Fixed constructor mint, 18 decimals, public transfer/burn, no later mint entrypoint | `CURRENT_ACCEPTED_BEHAVIOR`; dedicated factory-create metadata tests missing. |
| Bonding math | Exact constant-product `getAmountOut`, `getAmountIn` integer division then `+1`; phantom quote affects price only | `CURRENT_ACCEPTED_BEHAVIOR`; new golden/exact fuzz tests executed. |
| Reserve accounting | `realQuote = trackedQuote − quoteFeeBalance − creatorTaxBalance`; `quoteReserve = phantomQuote + realQuote`; `reservedTokens = floor(supply×phantomQuote/(phantomQuote+threshold))` | `CURRENT_ACCEPTED_BEHAVIOR` for direct native Curve fixture. `buybackQuoteBalance` is a subset of fee, not a second reserve deduction. |
| Fees | Buy fee/tax on quote input; sell fee/tax on gross quote output; protocol share and optional buyback earmark; sweep via external fee escrow | Direct tests cover no-buyback sweep and earmark persistence; full buyback/vesting/adversarial escrow paths pending. |
| Graduation | Factory `NotGraduated → Swept → PoolCreated/Rescued`; V4 preflight, excess-token lock, position mint; 7-day owner rescue | `CANONICAL_REQUIREMENT_NOT_MET` for target Kuru destination; current V4 failure/retry tests pending. Do not remove V4. |
| Quote assets | Native sentinel plus owner-approved ERC20 with code/decimals/economics checks; Curve credits actual inbound ERC20 balance delta | `CURRENT_KNOWN_GAP` versus target exact-transfer-only P0 admission: no intrinsic rebasing/fee-on-transfer exclusion at approval. Malicious-token qualification pending. |
| Anti-snipe | Factory has snipe settings/exemption forwarding; Curve `exemptFromSnipeTax` is an explicit no-op stub; buy uses only base fee and creator tax | `CURRENT_KNOWN_GAP`; no claim of active anti-snipe taxation. Explicit config→trade differential test still pending. |
| Salt | `TokenParams.salt` documented as CREATE2 input, but `_launchToken` does not pass it and Deployer uses ordinary `new` | `CURRENT_KNOWN_GAP`; address prediction/collision semantics in current docs are not implemented. Explicit salt/address test pending. |
| FeeEscrow | `IRetroPickFeeEscrowV2` interface required by Factory/Curve/Hook/Vault; no local V2 FeeEscrow implementation | `CURRENT_KNOWN_GAP`; direct Curve test uses a test-only credit ledger. |
| Test inventory | Before this increment, 45 committed tests, all Doorway-focused; no Core V2 suite | `CANONICAL_REQUIREMENT_NOT_MET`; new math and direct Curve tests do not yet close it. |
| Full stack status text | `apps/web` exists as a prototype (80 tracked/nonignored files at inspection), while `apps/api`, `apps/indexer`, `packages/sdk`, `packages/contracts` are absent | `CURRENT_KNOWN_GAP` in `BLOCK-FULLSTACK` wording; web source is not live Core integration. |

**Migration order:** complete Factory/config/create and Curve/fee/buyback/graduation unit tests; add ERC20/adversarial, high-run fuzz and multi-actor stateful handlers; qualify Kuru target/accepted ADRs; only then implement destination boundary and replay frozen fixtures. No economic redesign in this increment.

## Executed verification

- Foundry: `forge 1.8.3`, solc `0.8.26`, Cancun, optimizer 200, `via_ir=true` in `contracts/foundry.toml`.
- Baseline before edits: `cd contracts && forge test --summary` — 45 Doorway tests passed (unit 35, integration 4, fuzz 5×256, invariant 1×64 runs/4096 calls), zero Core tests. This is **not** Core evidence.
- New: `forge test --match-path test/v2/unit/RetroPickBondingCurveMathV2Qualification.t.sol --fuzz-runs 4096 --summary` — five tests pass, including two fuzz functions ×4096 runs. Golden values and exact integer domains in source fixture SHA-256 `e3bfb0c6a2ef1393c6565a6ac28a6d73f0487761a23d573346ebe65fa6dbb56b`.
- New: `forge test --match-path test/v2/unit/RetroPickCurrentCurveStateV2Qualification.t.sol --summary` — initial five direct Curve/Token/fee-ledger tests passed: wiring, buy/sell physical balance reconciliation, fee sweep, buyback earmark non-double-deduction, unauthorized/slippage state preservation. A sixth explicit anti-snipe-stub negative control was then added and passed; final fixture SHA-256 `81a346a71975cc2435e9b70048dc91986046f6464c0c4418221baa470d7b8902`.
- `forge test --match-path test/v2/unit/RetroPickLaunchDeployerV2Qualification.t.sol --summary` — four tests pass for fresh Curve/Token wiring, metadata upper bounds, factory-only deployment, and quote-address pass-through (not Factory quote admission). Fixture SHA-256 `cc39919907a5e91f2f0c663a803266e58893dd3aa033edc9519da3bddfd402e9`.
- `cd contracts && forge test --summary` at the final increment — 62 tests passed (45 Doorway, 17 V2 qualification), zero failures. Default two new fuzz properties use 256 runs each.
- `FOUNDRY_INVARIANT_RUNS=128 FOUNDRY_INVARIANT_DEPTH=256 forge test --match-path test/v2/invariant/RetroPickCurrentCurveV2Invariant.t.sol --fuzz-seed 0x20260929 --summary` — two stateful properties plus handler-branch test pass; 128 runs ×256 depth = 32,768 handler calls, zero uncaught reverts/discards. Handler selections: 8,216 buys, 8,239 sells, 8,209 sweeps, 8,104 unauthorized mutation attempts. Rejected economic calls are caught and do not indicate invariant failure.
- Same command with seed `0x20260930` — 128 runs ×256 depth = 32,768 calls, zero uncaught reverts/discards; second independent campaign passes. The direct handler test confirms at least one accepted buy, sell and sweep, plus a rejected unauthorized mutation. These campaigns cover only the declared native-quote Curve fixture, not Factory or ERC20 quote assets.
- `cd contracts && forge build --sizes` — passed; V2 Factory runtime 24,106 bytes, below EIP-170's 24,576-byte limit by 470 bytes at this compiler profile. This is a narrow margin, not a Kuru executor capacity guarantee.
- `forge fmt --check` on all three new V2 test files — passed. Repository-wide `forge fmt --check` failed on pre-existing V1/V2/Doorway formatting as well as an initially unformatted new test; the new files were subsequently formatted. No existing production source was reformatted.
- `python3 -m unittest discover -s research/integration/kuru -p 'test_launchpad_seed_model.py' -v` — seven exact-integer Kuru source-constraint/first-seed model tests pass. This is target research, not Core implementation qualification.

## LP-I-001..012 coverage at this increment

| Invariant | Evidence now | Remaining |
| --- | --- | --- |
| LP-I-001 fixed supply | Deployer/Curve/Token wiring, direct supply fixture and native-quote three-actor stateful handler | Factory create and no-extra-mint across full launch lifecycle. |
| LP-I-002 real reserves/transfers/fees | Direct buy/sell/sweep sequence and 2×32,768-call native-quote handler checking physical balances | ERC20/adversarial and Factory/graduation conservation. |
| LP-I-003 payout ≤ real quote | One sell assertion | Bounded fuzz and stateful adversarial payout. |
| LP-I-004 fee limits | Math fee domain only | Factory ceilings and full fee policy tests. |
| LP-I-005 no unauthorized mint/seizure | Factory-only curve mutation rejection plus unauthorized stateful attempts | Broader ACL and hostile token callbacks. |
| LP-I-006 at-most-once graduation | None | Current V4 lifecycle test and handler. |
| LP-I-007 secured assets persist | None | V4 failure path then Kuru target simulation. |
| LP-I-008 safe retry | None | V4 failure/retry and later Kuru fork. |
| LP-I-009 no resumed trading | Source guard only | Executable post-sweep tests. |
| LP-I-010 quote admission | Source inspection only | Factory approval and malicious token tests. |
| LP-I-011 creator/admin authorization/timelock | One factory-only curve mutation rejection | Factory timelock/recipient changes. |
| LP-I-012 unchanged math during Kuru migration | Exact math fixture baseline begun | Expand golden cases and replay after DEV-4 implementation. |

No LP-I row above is a full protocol PASS yet. A test file or one direct sequence does not satisfy the whole invariant domain.

## Later same-day increment

Factory-mediated native and admitted six-decimal quote launch tests were added after this baseline. They preserve the known anti-snipe and CREATE2 contradictions as executable negative controls. See [factory-launch-increment-2026-09-29.md](factory-launch-increment-2026-09-29.md). The 62-test count and pending items above describe the earlier checkpoint, not the later suite state.

## Open qualification work

Factory/deployer launch path and economics pin; native/ERC20 quote matrix; token metadata bounds; partial final buy; high-run Curve fuzz; multi-actor stateful handler; buyback vault/fee escrow paths; current V4 graduation/retry; malicious quote tokens; Slither/Aderyn/Solhint triage; full Kuru target parameters, LP custody and retry ADR acceptance. `BLOCK-CONTRACT-TESTS` remains active.

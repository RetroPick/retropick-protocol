# Research Directory Map

This map inventories every authoritative research lane in this repository and
explains what each lane can and cannot decide. It is a navigation and evidence
index, not a substitute for the referenced reports, tests, source captures,
ADRs, or control-plane status.

For the shorter top-level overview, see [README.md](README.md).

## Reading rules

- Research code is an executable model or harness unless an accepted authority
  explicitly promotes it.
- A local pass is scoped to its declared model, compiler, profile, input
  domain, and recorded environment.
- A counterexample remains evidence even after a candidate repair passes.
- Source-derived facts, inferences, and recommendations must stay distinct.
- No benchmark result becomes a service-level objective without an accepted
  sampling and deployment methodology.
- Prediction, PRISM, and Launchpad/Hackathon lanes do not inherit one
  another's readiness.

## Directory overview

```text
research/
├── README.md
├── RESEARCH_MAP.md
├── requirements-formal.txt
├── sources.json
├── benchmarks/
│   ├── raw/
│   ├── reports/
│   └── scripts/
├── contract-kernels/
│   ├── src/
│   │   ├── hackathon/
│   │   ├── prediction/
│   │   └── prism/
│   ├── test/
│   │   ├── hackathon/
│   │   ├── prediction/
│   │   └── prism/
│   ├── cache/                    # generated
│   └── out/                      # generated
├── hackathon-p0/
│   ├── fixtures/
│   ├── models/
│   ├── scripts/
│   └── tests/
├── integration/
│   └── kuru/
├── market/
│   └── launchpads/
├── normalized/
├── prediction-model/
│   ├── fixtures/
│   ├── outputs/
│   └── tests/
├── prism/
│   └── reports/
├── prism-model/
│   ├── fixtures/
│   └── tests/
├── production/
│   ├── benchmarks/
│   ├── control/
│   ├── matrices/
│   ├── reports/
│   ├── schemas/
│   └── tooling/
├── raw/
└── reports/
```

Generated directories such as `contract-kernels/cache/`,
`contract-kernels/out/`, and `**/__pycache__/` are deliberately not expanded
as source lanes. They may support reproduction diagnostics, but rerunning the
associated deterministic model or test is stronger evidence.

## Lane index

| Lane | Primary question | Output | Authority boundary |
| --- | --- | --- | --- |
| [benchmarks/](benchmarks/) | How expensive and reproducible are the research models? | Timing/gas reports and reproduction scripts | No SLO or promotion authority |
| [contract-kernels/](contract-kernels/) | Do reduced Solidity kernels preserve modeled semantics? | Foundry unit, differential, invariant, and adversarial tests | Research Solidity only |
| [hackathon-p0/](hackathon-p0/) | Can a deliberately reduced demo profile be safely demonstrated? | Scoped P0 models, fixtures, tests, gate | Does not upgrade production gates |
| [integration/kuru/](integration/kuru/) | Can Launchpad graduation safely target real Kuru? | Exact models, witnesses, envelope checks, source compatibility | Does not freeze external integration alone |
| [market/launchpads/](market/launchpads/) | What do comparable launchpads do? | Fact/inference/recommendation matrix | Does not define RetroPick economics |
| [normalized/](normalized/) | Where should structured source-derived data live? | Reserved normalization layer | Sparse and not automatically canonical |
| [prediction-model/](prediction-model/) | What are exact Prediction semantics and failure boundaries? | Exact integer oracle, fixtures, theorem/probe tests | No production authority |
| [prism/](prism/) | What must PRISM prove or abandon? | Program, promotion gates, kill criteria, questions | Program governance only |
| [prism-model/](prism-model/) | What are exact PRISM semantics and counterexamples? | Canonical executable oracle and campaigns | `MATH-1` remains failed |
| [production/](production/) | How are shared platform and Launchpad Core production decisions evidenced? | Research OS, matrices, schemas, reports, tooling | Does not accept production scope |
| [raw/](raw/) | What exact external inputs were observed? | Unmodified captures/provenance | Facts only; no interpretation |
| [reports/](reports/) | What is the cross-module qualification state? | Decision packets and machine-readable gates | Evidence; acceptance still requires authority |

## Detailed lane map

### `benchmarks/` — timing and gas evidence

Subfolders:

- `raw/`: immutable raw timing arrays recorded from a named local run.
- `reports/`: human-readable reports that state assumptions and limitations.
- `scripts/`: local and clean-checkout reproduction drivers.

Current content focuses on:

- Prediction exhaustive-state timing.
- PRISM payoff, replication, telescope, and reference-model timing.
- Prediction Foundry operation-gas measurements.
- A clean clone, virtual environment, and named research profile.

The recorded clean profile is:

```bash
bash research/benchmarks/scripts/repro_clean.sh default
bash research/benchmarks/scripts/repro_clean.sh research
```

Interpretation limits:

- Most operation rows are local, deterministic samples rather than production
  percentile latency.
- Whole-test Foundry gas includes test overhead unless a report explicitly
  isolates an operation.
- Passing performance work does not repair an accounting or semantic failure.

Lane entry point: [benchmarks/README.md](benchmarks/README.md).

### `contract-kernels/` — isolated research Solidity

Subfolders:

- `src/prediction/`: prototype market, outcome token, clone helper, and mock
  collateral.
- `src/prism/`: candidate backing, cumulative settlement, payoff transform,
  and reservation-ledger kernels.
- `src/hackathon/`: reduced Prediction and PRISM P0 contracts.
- `test/prediction/`: lifecycle, differential, invariant, rejection, callback,
  malicious-token, arithmetic-boundary, and gas tests.
- `test/prism/`: candidate kernels, differential fixtures, bounded domains,
  adversarial behavior, and stateful checks.
- `test/hackathon/`: reduced Prediction/PRISM unit, differential, invariant,
  and cross-module P0 tests.
- `cache/` and `out/`: generated Foundry artifacts.

Research boundary:

- `CandidateCumulativeSettlement.sol` is a candidate kernel, not a `MATH-1`
  pass and not authorization for a production settlement port.
- Hackathon kernels intentionally remove unsafe paths rather than proving the
  unrestricted production semantics.
- Kernel tests do not replace accepted architecture, storage layout, or
  production security qualification.

Run:

```bash
cd research/contract-kernels
forge test
```

Lane entry point: [contract-kernels/README.md](contract-kernels/README.md).

### `hackathon-p0/` — reduced demonstration qualification

Subfolders:

- `fixtures/`: generated deterministic model inputs and expected outputs.
- `models/`: reduced Python semantic models.
- `scripts/`: local fast and stateful campaign drivers.
- `tests/`: Python assertions over the reduced profile.

The profile is intentionally narrow:

- Prediction P0 is binary YES/NO, with no INVALID or fractional payout.
- PRISM P0 is exact-backed, long-only, transferable, and redeemable in kind.
- No final cash settlement, settlement cursor, residual sweep, or shared
  prefunding pool exists.
- Kuru is a secondary venue only and is never backing or redemption authority.

The local reduced profile is qualified only under its declared assumptions.
Live market usability remains external/post-development and cannot convert this
profile into production authority.

Lane entry point: [hackathon-p0/README.md](hackathon-p0/README.md).

### `integration/` — mutable external integration research

This lane researches integrations without allowing an external implementation
to redefine RetroPick accounting. Its current child lane is
[kuru/](integration/kuru/).

Evidence layers normally required for an integration target are:

1. current public source capture and version/commit identity;
2. chain-specific environment manifest;
3. block-pinned fork tests against deployed code;
4. exact post-state verification and fault injection;
5. later live testnet evidence only after implementation gates permit it.

External code and deployment identities are mutable. A production path must
fail closed on observable drift and require requalification rather than
silently adapting to a new implementation.

Lane entry point: [integration/README.md](integration/README.md).

#### `integration/kuru/` — Launchpad/Kuru target research

Principal contents:

- Kuru token compatibility and quote identity notes.
- Parameter worksheet and SDK precision cross-check script.
- Launch-profile and first-seed exact-integer models.
- Curve completion and terminal-Q liveness models.
- Prelaunch, round-trip, bounded, wide, and exact terminal-Q witnesses.
- Unit tests for the seed model, completion invariant, exact interval, and P0
  terminal envelope.

The current central result is path dependence:

```text
buy 2 raw quote units
sell exactly the purchased tokens
tracked token reserve restored
real quote reserve increased
```

The cycle is repeatably pumpable. Therefore `LaunchConfig` alone cannot prove
a tight all-history terminal-Q bound, and `terminal secured Q equals threshold`
is not a valid admission assumption.

The replacement invariant is:

```text
completionTerminalQuote(state) <= graduationQuoteCeiling
```

It requires every accepted state to retain an immediate valid completion path
whose exact terminal quote remains in policy. A mere current-Q cap is weaker
and can leave a launch unable to finish.

The declared reduced-domain admissibility result covers every integer terminal
Q from each profile's exact immediate-completion lower bound through the
declared 50x-threshold upper bound for five positive launch profiles and both
P0 quote classes. It checks positive base seed, precision/tick representation,
price validity, nonzero vault bid/ask sizes, positive LP shares, and integer
widths.

Classification:

```text
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
```

This is not an all-history reachable-Q proof, not accepted economics, not a
real-Router boundary qualification by itself, and not production Solidity.

Run:

```bash
cd research/integration/kuru
python3 -m unittest discover -s . -p 'test_*.py' -v
```

Lane entry point: [integration/kuru/README.md](integration/kuru/README.md).

### `market/` — external market research

The current child lane is `launchpads/`.

Observed competitor surfaces are used to expose capability choices and product
questions. They do not establish a requirement for RetroPick. Every claim must
be labeled as:

- `SOURCE_DERIVED_FACT`;
- `INFERENCE`;
- `RETROPICK_RECOMMENDATION`.

Never treat competitor target functionality, RetroPick target functionality,
and currently implemented functionality as interchangeable.

Lane entry point: [market/README.md](market/README.md).

#### `market/launchpads/`

Primary documents:

- `CAPABILITY_MATRIX.md`
- `O1.md`
- `PONS.md`
- `OTHER_REFERENCES.md`
- [README.md](market/launchpads/README.md)

The matrix is useful for feature discovery and risk comparison. It does not
override RetroPick ADRs, economics, source qualification, or implementation
evidence.

### `normalized/` — structured source layer

This is a reserved layer for source-derived facts normalized into a stable,
traceable form. It is intentionally sparse and does not automatically become
canonical. A normalized record must preserve its raw source, transformation,
timestamp/version, and limitations.

Do not infer product semantics from this layer when raw evidence, accepted
documentation, or implementation contradicts it.

Lane entry point: [normalized/README.md](normalized/README.md).

### `prediction-model/` — exact Prediction oracle

Subfolders:

- `fixtures/`: deterministic lifecycle, rejection, resolution, archive, and
  rounding cases.
- `outputs/`: generated exhaustive-search summaries.
- `tests/`: lifecycle, invariant, theorem, callback, collateral, arithmetic,
  and semantic-contradiction tests.

The model uses exact integers and standard-library Python only. It defines and
challenges binary fully collateralized market semantics, including split,
merge, resolution, redemption, INVALID rounding, callback lifecycle, collateral
admission, and archive behavior.

Preserved research findings include:

- INVALID holder allocation counterexample;
- winner liability overflow at `2^255`;
- false-return collateral admission;
- rebasing collateral accounting;
- RESOLVED versus REDEEMABLE contradiction;
- callback lifecycle behavior;
- configured split maximum;
- semantic convergence gaps across Python, Solidity, and documentation.

Run:

```bash
cd research/prediction-model
python3 -m unittest discover -s tests -v
```

Lane entry point: [prediction-model/README.md](prediction-model/README.md).

### `prism/` — PRISM research program

Subfolder:

- `reports/`: module admission gaps, reproduction status, and research status.

Primary documents:

- `RESEARCH_PROGRAM.md`
- `PROMOTION_GATES.md`
- `KILL_CRITERIA.md`
- `OPEN_QUESTIONS.md`

This lane asks whether and under what conditions PRISM should be admitted. It
does not duplicate the executable oracle in `prism-model/`.

Lane entry point: [prism/README.md](prism/README.md).

### `prism-model/` — exact PRISM oracle

Subfolders:

- `fixtures/`: deterministic fixed-point, precision, backing, and boundary
  inputs.
- `tests/`: lifecycle, replication, backing, reservation, settlement, partial
  resolution, bounded verification, native markets, adversarial attacks, and
  theorem probes.

The model covers:

- exact replication and minimum-cost replication;
- component backing and reservation;
- fixed-point precision and width boundaries;
- cumulative settlement;
- partial resolution;
- native complete-set markets;
- terminal settlement and residual behavior;
- holder-order and fragmentation attacks.

The global cumulative redemption cursor repaired aggregate conservation for the
candidate settlement form, but holder-allocation fairness remains falsified.
Accordingly, canonical `MATH-1D` and `MATH-1` remain `FAIL`.

Run:

```bash
cd research/prism-model
python3 -m unittest discover -s tests -v
python scenarios.py
python adversarial.py
```

Lane entry point: [prism-model/README.md](prism-model/README.md).

### `production/` — production research operating system

Subfolders:

- `benchmarks/`: benchmark methodology and coverage policy.
- `control/`: current production-research gates and state.
- `matrices/`: benchmark, dependency, production gap, module promotion, risk,
  and security matrices.
- `reports/`: platform baseline, Launchpad Core production research, and
  verdict.
- `schemas/`: source, claim, environment, and benchmark JSON schemas.
- `tooling/`: deterministic validation/aggregation utilities.

Current program state is:

```text
PR-R0 = in_progress
PR-R1..PR-R6 = blocked
```

The scope includes shared platform infrastructure and Launchpad Core. PRISM is
a consumer only until it passes module admission. This lane records evidence
and gaps; it does not itself accept production scope or deploy anything.

Lane entry point: [production/README.md](production/README.md).

### `raw/` — unmodified provenance

This lane holds unmodified external source captures or exact observations used
as evidence. It is sparse and should not be expanded with paraphrases.
Interpretation belongs in a normalized record, lane report, or packet that
links back to the raw source.

Lane entry point: [raw/README.md](raw/README.md).

### `reports/` — cross-module qualification packets

Important reports and machine-readable artifacts:

- [SMART_CONTRACT_RESEARCH_GATE.md](reports/SMART_CONTRACT_RESEARCH_GATE.md)
- [qualification-gates.yaml](reports/qualification-gates.yaml)
- [DUAL_RESEARCH_BASELINE.md](reports/DUAL_RESEARCH_BASELINE.md)
- [DUAL_RESEARCH_STATUS.md](reports/DUAL_RESEARCH_STATUS.md)
- [MATRICES.md](reports/MATRICES.md)
- [EVIDENCE_INDEX.md](reports/EVIDENCE_INDEX.md)
- [FINANCIAL_MODULE_PROMOTION_VERDICT.md](reports/FINANCIAL_MODULE_PROMOTION_VERDICT.md)
- [ADR_R03_ACCEPTANCE_PACKET.md](reports/ADR_R03_ACCEPTANCE_PACKET.md)
- [SETTLEMENT_RESIDUAL_DECISION_PACKET.md](reports/SETTLEMENT_RESIDUAL_DECISION_PACKET.md)
- [COLLATERAL_ADMISSION_PACKET.md](reports/COLLATERAL_ADMISSION_PACKET.md)
- [PREDICTION_SEMANTIC_CONVERGENCE_PACKET.md](reports/PREDICTION_SEMANTIC_CONVERGENCE_PACKET.md)
- [PRISM_BACKING_RESERVATION_PACKET.md](reports/PRISM_BACKING_RESERVATION_PACKET.md)
- [PRISM_ADMISSION_SOURCE_INTERFACE_PACKET.md](reports/PRISM_ADMISSION_SOURCE_INTERFACE_PACKET.md)
- [HACKATHON_P0_GATE.md](reports/HACKATHON_P0_GATE.md)
- [hackathon-p0-gates.yaml](reports/hackathon-p0-gates.yaml)

These documents may recommend `ACCEPT`, `REJECT`, or `REVISE`, but a proposed
ADR remains proposed until the authorized human/protocol decision is recorded.

## Root research files

- [requirements-formal.txt](requirements-formal.txt): narrow dependencies used
  by formal/research profiles, not a blanket application dependency set.
- [sources.json](sources.json): research source registry and provenance
  metadata.

## Evidence and naming conventions

Use classifications that expose their basis, for example:

- `PROVEN_UNDER_ASSUMPTIONS`
- `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN`
- `SUPPORTED_BY_SIMULATION`
- `SUPPORTED_BY_LIVE_EVIDENCE`
- `COUNTEREXAMPLE_FOUND`
- `NOT_YET_VALIDATED`
- `BLOCKED_TOOL`
- `RECORDED_CONTRADICTION`
- `EXISTING_RULE`

Avoid vague confidence labels such as “looks safe” or “probably ready”. A gate
transition must cite the prior state, new state, reason, evidence path,
validated SHA, and any remaining blocker.

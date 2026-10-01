# RetroPick Research

This directory is the repository's evidence, executable-model, source-analysis,
and decision-support layer. It is not a production authority and it does not
promote contracts into `contracts/src/v2/*`.

For a complete folder-by-folder inventory, see [RESEARCH_MAP.md](RESEARCH_MAP.md).

## Authority boundaries

The normal order of authority is:

1. accepted ADRs;
2. canonical platform and module specifications;
3. the development architecture and control plane;
4. the active task or goal specification;
5. implementation;
6. research evidence and recommendations.

Research can preserve a counterexample, expose a semantic contradiction, or
recommend a decision. It cannot reinterpret historical evidence, accept a
proposed ADR, or change a qualification gate on its own.

Current release and implementation gates remain controlled by:

- [development/launchpad/control/status.yaml](../development/launchpad/control/status.yaml)
- [research/reports/qualification-gates.yaml](reports/qualification-gates.yaml)
- [research/reports/hackathon-p0-gates.yaml](reports/hackathon-p0-gates.yaml)

## Lane map

| Path | Role | Current posture |
| --- | --- | --- |
| [benchmarks/](benchmarks/) | Reproducible Python timing and Foundry gas evidence | Evidence only; no SLO authority |
| [contract-kernels/](contract-kernels/) | Isolated Foundry research kernels for Prediction, PRISM, and the hackathon P0 | Research Solidity only |
| [hackathon-p0/](hackathon-p0/) | Deliberately reduced binary Prediction and exact-backed PRISM demo models | Scoped reduced profile; not a production gate |
| [integration/](integration/) | External integration boundaries, currently Kuru on Monad | Active Launchpad/Kuru research lane |
| [market/](market/) | Market and launchpad competitor/reference analysis | Observations and recommendations only |
| [normalized/](normalized/) | Reserved structured and provenance-checked source layer | Sparse; not automatically canonical |
| [prediction-model/](prediction-model/) | Exact integer Prediction semantic oracle | Research-gated; semantic contradictions preserved |
| [prism/](prism/) | PRISM research program, gates, kill criteria, and questions | Research-gated |
| [prism-model/](prism-model/) | Exact executable PRISM oracle and adversarial model | `MATH-1` remains `FAIL` |
| [production/](production/) | Shared production-research operating system and Launchpad Core matrices | Research program; not production acceptance |
| [raw/](raw/) | Unmodified external-source captures | Provenance only |
| [reports/](reports/) | Cross-cutting packets and machine-readable qualification gates | Current evidence state |

## Research posture

### Launchpad Core + Kuru

The researched architecture keeps the Factory thin and extracts graduation
into a coordinator plus venue executors. Kuru-specific logic must not be
embedded in the current Factory: its current runtime is 24,565 bytes against
the 24,576-byte EIP-170 limit, leaving only 11 bytes of usable headroom.

The target direction is:

```text
RetroPickLaunchFactoryV2
  -> GraduationCoordinatorV2
     -> V4 executor
     -> Kuru executor
        -> Kuru Router
           -> OrderBook
           -> Kuru AMM Vault
              -> permanent protected LP/excess custody
```

The terminal secured-quote assumption changed during research: repeated raw
buy/sell round trips can restore the tracked token reserve while increasing
real quote reserve. Therefore `terminal secured Q == graduationThreshold` is
falsified, and threshold-only admission is invalid.

The replacement research invariant is:

```text
completionTerminalQuote(state) <= graduationQuoteCeiling
```

This is stronger than a current-Q cap because it requires an immediate valid
completion path. The Curve remains venue-agnostic: graduation policy derives
the ceiling, while the Curve enforces generic completion liveness.

Current control-plane status remains:

- `CORE_BASELINE_P0_QUALIFIED`: `BLOCKED`
- `KURU_TARGET_DEV_FROZEN`: `BLOCKED`
- `READY_FOR_DEV4_KURU_EXECUTOR`: `BLOCKED`
- `V2_HACKATHON_SMART_CONTRACT_DEV_READY`: `CONDITIONAL_PASS`

See the detailed evidence in
[development/launchpad/control/status.yaml](../development/launchpad/control/status.yaml)
and the cross-module summary in
[reports/SMART_CONTRACT_RESEARCH_GATE.md](reports/SMART_CONTRACT_RESEARCH_GATE.md).

### Prediction

Prediction remains a separate research-gated module. Its Python model is an
exact integer semantic oracle, not a production implementation. Important
preserved findings include INVALID holder allocation, winner-liability overflow
at `2^255`, false-return collateral behavior, rebasing collateral behavior,
RESOLVED versus REDEEMABLE separation, callback lifecycle, and split-boundary
contradictions.

### PRISM

PRISM remains independently research-gated. Its canonical settlement result
currently contains a preserved holder-allocation failure, so:

```text
PRISM MATH-1 = FAIL
```

No PRISM research kernel, differential result, or benchmark authorizes
production PRISM Solidity while this invariant remains falsified.

## Quote identity

Launchpad/Kuru P0 research distinguishes quote identity by contract address
and chain, not by the `USDC` symbol.

| Label | Chain | Address | Classification |
| --- | --- | --- | --- |
| Circle test USDC | 10143 | `0x534b2f3A21130d7a60830c2Df862319e593943A3` | Selected canonical Circle test quote candidate |
| Kuru-listed test USDC | 10143 | `0x3bA3d39AFcf8bb994f7964B3e0171Ea2Ba361570` | `KURU_TEST_USDC` compatibility fixture only |

The two contracts are not interchangeable, and the Kuru-listed fixture must not
be described as canonical Circle USDC.

## Reproduction entry points

Run only the lane needed for the current task. These are research entry points,
not deployment or promotion commands:

```bash
# Launchpad/Kuru exact models
cd research/integration/kuru
python3 -m unittest discover -s . -p 'test_*.py' -v

# Prediction semantic oracle
cd research/prediction-model
python3 -m unittest discover -s tests -v

# PRISM semantic oracle and campaigns
cd research/prism-model
python3 -m unittest discover -s tests -v
python scenarios.py
python adversarial.py

# Research Solidity kernels
cd research/contract-kernels
forge test

# Clean benchmark reproduction
bash research/benchmarks/scripts/repro_clean.sh default
bash research/benchmarks/scripts/repro_clean.sh research
```

## Generated artifacts

`research/contract-kernels/cache/`, `research/contract-kernels/out/`, and
Python `__pycache__/` directories are generated. They may explain a past local
run, but they are not authoritative source evidence and should not be used as
substitutes for rerunning the associated model, tests, or benchmark scripts.

# RetroPick Protocol

Protocol, market-structure, mathematical reference-model, and Metropolis delivery repository for **RetroPick + PRISM** on Monad.

> **Start with [`docs/00-context/EXECUTIVE_SUMMARY.md`](docs/00-context/EXECUTIVE_SUMMARY.md)** for the canonical human-facing overview of the product thesis, architecture, mathematical model, lifecycle, hackathon scope, current phase, and immediate next work.

## Current phase

**P1 SPEC -> P2 MATH-1**

The repository is intentionally math-first. Production Solidity is scaffolded but not yet authorized.

Current dependency order:

```text
SPEC-1
-> MATH-1
-> CONTRACT-ARCH-1
-> CONTRACT-1
-> INTEGRATION-1 / PRODUCT-1
-> E2E-1
-> SUBMISSION-1
```

See [`docs/05-hackathon/PHASE_GATES.md`](docs/05-hackathon/PHASE_GATES.md).

---

## Product boundary

### Native RetroPick

```text
Event + immutable ResolutionSpec
  -> PredictionMarketFactory
  -> fully collateralized complete set
  -> YES ERC20 / NO ERC20
  -> Kuru spot markets
  -> resolution / redemption
```

### PRISM

```text
Supported outcome ERC20s
  -> exact basket/payoff admission
  -> locked component backing
  -> PRISM structured ERC20
  -> Kuru secondary market
  -> partial/final settlement
```

RetroPick owns issuance, collateral semantics, payoff semantics, resolution rules and redemption.

Kuru supplies exchange microstructure.

Backing collateral, LP inventory, market-maker inventory, fees and settlement funds are separate accounting domains.

---

## Canonical Phase-1 equations

Exact structured payoff:

```math
h=Gx
```

Advanced payoff admission:

```math
Gx=h^*,\quad x\ge0
```

Runtime component backing:

```math
B_i\ge Sx_i
```

Final redemption funding gate:

```math
SettlementBalance\ge Supply\times FinalPayout
```

Native complete-set model:

```math
YES_{supply}=NO_{supply}=CollateralLocked
```

in the simple fully collateralized binary model.

---

## Proof architecture

The repository now separates protocol semantics, proof, executable semantics, and future implementation:

```text
docs/protocol/
  WHAT the protocol means
        ↓
docs/math/
  WHY those semantics hold
        ↓
research/prism-model/
  EXECUTABLE semantic oracle
        ↓
contracts/
  future Solidity implementation
```

`docs/math/17_THEOREMS.md` is the canonical theorem/counterexample/hypothesis registry. It deliberately keeps empirical market claims separate from protocol-safety proofs.

---

## Locked architecture corrections

The historical architecture report has been reconciled. Canonical Phase 1 now explicitly uses:
- Monad-native YES/NO backing for PRISM;
- no same-chain `BackingMirror`;
- no terminal-world enumeration inside every mint;
- component-wise runtime backing checks;
- basket mode as the simplest PRISM creator path;
- separate native-market and PRISM creation pipelines;
- separate retail PRISM BUY and primary PRISM CREATE;
- distinct `RESOLVED` and `REDEEMABLE` states;
- settlement funding before final redemption;
- corrected `pFEDBTC` payoff table;
- corrected complete-set open-interest accounting.

See [`docs/00-context/REPORT_RECONCILIATION.md`](docs/00-context/REPORT_RECONCILIATION.md).

---

## Canonical entry points

### Human overview
- [`docs/00-context/EXECUTIVE_SUMMARY.md`](docs/00-context/EXECUTIVE_SUMMARY.md)
- [`docs/00-context/REPORT_RECONCILIATION.md`](docs/00-context/REPORT_RECONCILIATION.md)

### Agent/execution
- [`AGENTS.md`](AGENTS.md)
- [`.agent/CURRENT_GOAL.md`](.agent/CURRENT_GOAL.md)
- [`docs/05-hackathon/PHASE_GATES.md`](docs/05-hackathon/PHASE_GATES.md)
- [`docs/06-execution/ROADMAP.md`](docs/06-execution/ROADMAP.md)

### Protocol semantics
- [`docs/protocol/README.md`](docs/protocol/README.md)
- [`docs/protocol/PRISM_PROTOCOL_SPEC.md`](docs/protocol/PRISM_PROTOCOL_SPEC.md)
- [`docs/protocol/ASSUMPTIONS.md`](docs/protocol/ASSUMPTIONS.md)
- [`docs/protocol/MATH_MODEL.md`](docs/protocol/MATH_MODEL.md)
- [`docs/protocol/CLAIMS.md`](docs/protocol/CLAIMS.md)
- [`docs/protocol/INVARIANTS.md`](docs/protocol/INVARIANTS.md)
- [`docs/protocol/STATE_MACHINE.md`](docs/protocol/STATE_MACHINE.md)
- [`docs/protocol/FAILURE_MODES.md`](docs/protocol/FAILURE_MODES.md)
- [`docs/protocol/PRECISION_MODEL.md`](docs/protocol/PRECISION_MODEL.md)
- [`docs/protocol/CONTRACT_REQUIREMENTS.md`](docs/protocol/CONTRACT_REQUIREMENTS.md)

### Mathematical proof layer
- [`docs/math/README.md`](docs/math/README.md)
- [`docs/math/01_DEFINITIONS.md`](docs/math/01_DEFINITIONS.md)
- [`docs/math/02_ASSUMPTIONS.md`](docs/math/02_ASSUMPTIONS.md)
- [`docs/math/05_BACKING_SOLVENCY.md`](docs/math/05_BACKING_SOLVENCY.md)
- [`docs/math/16_INVARIANTS.md`](docs/math/16_INVARIANTS.md)
- [`docs/math/17_THEOREMS.md`](docs/math/17_THEOREMS.md)

### Architecture
- [`docs/04-architecture/SYSTEM_ARCHITECTURE.md`](docs/04-architecture/SYSTEM_ARCHITECTURE.md)
- [`docs/04-architecture/SMART_CONTRACTS.md`](docs/04-architecture/SMART_CONTRACTS.md)

### Hackathon
- [`docs/05-hackathon/MVP.md`](docs/05-hackathon/MVP.md)
- [`docs/05-hackathon/RETROPICK_METROPOLIS_AGENT_DEVELOPMENT_WORKFLOW.md`](docs/05-hackathon/RETROPICK_METROPOLIS_AGENT_DEVELOPMENT_WORKFLOW.md)

### Executable reference model
- [`research/prism-model/README.md`](research/prism-model/README.md)

---

## Reference-model quick start

```bash
cd research/prism-model
python -m unittest discover -s tests -v
python scenarios.py
```

The accounting model uses Python exact `Fraction` arithmetic so Phase 1 does not hide financial bugs behind floating-point rounding.

`market_math.py` separately models complete-set parity, executable PRISM create/redeem values, partial-resolution NAV and post-resolution quote-pair identities without pretending these market relations are protocol guarantees.

---

## Repository layers

```text
.agent/               agent control plane
docs/protocol/         canonical protocol/economic semantics
docs/math/             canonical proof and theorem traceability layer
docs/                  broader project/product/hackathon documentation
goals/                  execution goals
decisions/              accepted architecture decisions
research/prism-model/   canonical executable economic model
apps/                   product applications after gates
packages/               shared packages after interfaces stabilize
contracts/              Solidity implementation after MATH-1/CONTRACT-ARCH-1
scripts/                automation/deployment/evidence tooling
tests/                  cross-layer/E2E tests
evidence/               reproducible evidence artifacts
```

---

## Phase-1 non-goals

- no production cross-chain outcome wrapper;
- no Polymarket custody dependency;
- no same-chain BackingMirror;
- no arbitrary StatePool/SLE implementation;
- no approximate replication;
- no claim that arbitrary nonlinear payoffs are replicable;
- no claim that simulation proves user adoption, liquidity or MM profitability;
- no fabricated sponsor capability/evidence;
- no assumption that passkeys equal legal identity/KYC.

---

## MATH-1 gate

The final MATH-1 verdict must be one of:

```text
MATH-1 = PASS
MATH-1 = CONDITIONAL_PASS
MATH-1 = FAIL
```

A core accounting or solvency kill criterion forces `FAIL` regardless of UI quality or simulated market behavior.

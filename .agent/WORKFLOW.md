# Agent Workflow

**Status:** CANONICAL AGENT EXECUTION FLOW  
**Phase control:** `docs/prism/05-hackathon/PHASE_GATES.md`  
**Protocol truth:** `docs/prism/protocol/`  
**Historical report reconciliation:** `docs/prism/00-context/REPORT_RECONCILIATION.md`

The hackathon-wide product strategy remains in:
`docs/prism/05-hackathon/RETROPICK_METROPOLIS_AGENT_DEVELOPMENT_WORKFLOW.md`.

Where historical wording conflicts with the canonical protocol docs or phase gates, the canonical protocol docs and accepted ADRs win.

---

## 1. Global execution DAG

```text
BASELINE-1
   ↓
SPEC-1
   ↓
MATH-1
   ↓
CONTRACT-ARCH-1
   ↓
CONTRACT-1
   ├──────────────┐
   ↓              ↓
INTEGRATION-1   PRODUCT-1
   └──────┬───────┘
          ↓
        E2E-1
          ↓
    SUBMISSION-1
```

No agent may skip a financial gate because another workstream is ahead.

---

## 2. Phase-1 SPEC + MATH workflow

```text
DISCOVER
  -> DEFINE
  -> RECONCILE
  -> SPEC
  -> MODEL
  -> FALSIFY
  -> EXHAUST
  -> PRECISION MODEL
  -> PROVE / VERIFY
  -> DERIVE CONTRACT REQUIREMENTS
  -> MATH-1 VERDICT
```

### Reconcile

Before extending protocol semantics, compare the request against:
- `REPORT_RECONCILIATION.md`;
- accepted ADRs;
- `PRISM_PROTOCOL_SPEC.md`;
- `INVARIANTS.md`;
- `STATE_MACHINE.md`.

Do not resurrect rejected Phase-1 architecture such as:
- same-chain `BackingMirror`;
- external bridge dependency;
- terminal-state enumeration inside every mint;
- generic StatePool/SLE;
- retail BUY flow that forces primary basket creation.

### Model

The executable semantic reference lives in:
`research/prism-model/`.

Use exact arithmetic first. Market simulation must be separated from accounting semantics.

### Falsify

Search for counterexamples before implementation:
- unbacked mint;
- over-redemption;
- double-use backing;
- terminal insolvency;
- illegal lifecycle transitions;
- false replication acceptance;
- settlement underfunding;
- rounding extraction.

### MATH-1 verdict

Allowed outputs:

```text
PASS
CONDITIONAL_PASS
FAIL
```

Protocol-accounting failure means `FAIL` regardless of simulated market performance.

---

## 3. Contract workflow after MATH-1

Only after accounting gates pass:

```text
CONTRACT REQUIREMENTS
  -> STORAGE / INTERFACES
  -> AUTHORIZATION
  -> PRECISION IMPLEMENTATION
  -> SOLIDITY KERNEL
  -> UNIT TESTS
  -> FUZZ
  -> STATEFUL INVARIANTS
  -> DIFFERENTIAL TESTS VS PYTHON
  -> DEPLOYMENT
```

Every critical contract responsibility must trace to a canonical invariant or requirement.

---

## 4. Integration workflow

Integrations may prototype against mocks after interfaces stabilize, but cannot become authoritative protocol truth.

```text
Kuru       -> execution / liquidity
Envio      -> indexed read model
CRE        -> resolution orchestration
Alchemy    -> RPC / WebSocket transport
Mera       -> user account UX
Aurora     -> funding path
Nansen     -> analytics / intelligence
MetaMask   -> optional agent automation
```

Never use an integration as a shortcut around the financial model.

---

## 5. Per-goal execution

1. Read `.agent/CURRENT_GOAL.md`.
2. Read `docs/prism/05-hackathon/PHASE_GATES.md`.
3. Inspect canonical source-of-truth docs.
4. Check accepted ADRs.
5. Declare assumptions and acceptance criteria.
6. Identify owned files and forbidden scope.
7. Implement the smallest coherent change.
8. Run deterministic tests.
9. Run adversarial/fuzz/exhaustive checks where applicable.
10. Write evidence under `evidence/`.
11. Update decisions when architecture changes.
12. Handoff only when the current gate's acceptance criteria pass.

---

## 6. Scientific classification

Always classify conclusions as one of:

```text
PROVEN_UNDER_ASSUMPTIONS
EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN
SUPPORTED_BY_SIMULATION
SUPPORTED_BY_LIVE_EVIDENCE
NOT_YET_VALIDATED
COUNTEREXAMPLE_FOUND
```

Never call market demand, liquidity, arbitrage speed or market-maker profitability mathematically proven.

---

## 7. Anti-patterns

- implementation-first protocol design;
- silently changing payoff semantics;
- calling simulation a proof;
- marking a sponsor integration complete without live evidence;
- treating exchange liquidity as automatic;
- mixing backing collateral and trading capital;
- confusing `RESOLVED` with `REDEEMABLE`;
- calculating open interest as `YES_supply + NO_supply` for a complete-set market;
- using mid-price identities as executable arbitrage conditions;
- treating a passkey as KYC/legal identity;
- treating an attestation as collateral.

# Graph Report - v2-readiness  (2026-09-29)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 16 nodes · 14 edges · 4 communities
- Extraction: 0% EXTRACTED · 100% INFERRED · 0% AMBIGUOUS · INFERRED: 14 edges (avg confidence: 0.5)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `797becbe`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Community 0
- Community 1
- Community 2
- Community 3

## God Nodes (most connected - your core abstractions)
1. `Core V2 Curve: reserves and primary pricing` - 3 edges
2. `Core V2 Graduation Controller: target` - 3 edges
3. `Core V2 Factory: launch/config authority` - 2 edges
4. `Prediction market: research kernel` - 2 edges
5. `Prediction outcome ERC20: candidate source` - 2 edges
6. `Versioned source-asset interface: PROPOSED` - 2 edges
7. `PRISM exact-replication admission: research` - 2 edges
8. `PRISM custody and reservation: research` - 2 edges
9. `PRISM series liability ERC20: candidate` - 2 edges
10. `PRISM settlement: MATH-1 FAIL` - 2 edges

## Surprising Connections (you probably didn't know these)
- `Versioned source-asset interface: PROPOSED` --proposed_metadata_and_custody_boundary--> `PRISM exact-replication admission: research`  [INFERRED]
  docs/prism/04-architecture/SOURCE_ASSET_INTERFACE.md → research/reports/SMART_CONTRACT_RESEARCH_GATE.md
- `Core V2 Factory: launch/config authority` --deploys_via_deployer--> `Core V2 Launch Token`  [INFERRED]
  development/launchpad/contracts/TARGET_V2_ARCHITECTURE.md → docs/architecture/contracts/V2_ARCHITECTURE.md
- `Prediction market: research kernel` --issues_outcome_claims_in_research_model--> `Prediction outcome ERC20: candidate source`  [INFERRED]
  research/reports/SMART_CONTRACT_RESEARCH_GATE.md → docs/prism/04-architecture/SOURCE_ASSET_INTERFACE.md
- `PRISM custody and reservation: research` --back_first_mint_second_candidate--> `PRISM series liability ERC20: candidate`  [INFERRED]
  research/reports/SMART_CONTRACT_RESEARCH_GATE.md → docs/prism/04-architecture/PHASE1_CANDIDATE_SERIES.md
- `PRISM series liability ERC20: candidate` --redeem_liability_at_terminal_state--> `PRISM settlement: MATH-1 FAIL`  [INFERRED]
  docs/prism/04-architecture/PHASE1_CANDIDATE_SERIES.md → research/reports/SMART_CONTRACT_RESEARCH_GATE.md

## Communities (4 total, 0 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.40
Nodes (5): PRISM exact-replication admission: research, PRISM custody and reservation: research, PRISM finance handoff: FAIL, PRISM series liability ERC20: candidate, PRISM settlement: MATH-1 FAIL

### Community 1 - "Community 1"
Cohesion: 0.50
Nodes (4): Core V2 Curve: reserves and primary pricing, Core V2 Factory: launch/config authority, Core V2 Fee / Buyback Components, Core V2 Launch Token

### Community 2 - "Community 2"
Cohesion: 0.50
Nodes (4): Prediction finance handoff: FAIL, Prediction market: research kernel, Prediction outcome ERC20: candidate source, Versioned source-asset interface: PROPOSED

### Community 3 - "Community 3"
Cohesion: 0.67
Nodes (3): Core DEVELOPMENT_READY: in progress, Core V2 Graduation Controller: target, Kuru secondary venue: target, not backing

## Knowledge Gaps
- **6 isolated node(s):** `Core V2 Launch Token`, `Core V2 Fee / Buyback Components`, `Kuru secondary venue: target, not backing`, `Core DEVELOPMENT_READY: in progress`, `Prediction finance handoff: FAIL` (+1 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Versioned source-asset interface: PROPOSED` connect `Community 2` to `Community 0`?**
  _High betweenness centrality (0.057) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Core V2 Curve: reserves and primary pricing` (e.g. with `Core V2 Fee / Buyback Components` and `Core V2 Graduation Controller: target`) actually correct?**
  _`Core V2 Curve: reserves and primary pricing` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Core V2 Factory: launch/config authority` (e.g. with `Core V2 Curve: reserves and primary pricing` and `Core V2 Launch Token`) actually correct?**
  _`Core V2 Factory: launch/config authority` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Core V2 Launch Token`, `Core V2 Fee / Buyback Components`, `Kuru secondary venue: target, not backing` to the rest of the system?**
  _6 weakly-connected nodes found - possible documentation gaps or missing edges._
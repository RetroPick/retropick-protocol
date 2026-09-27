# Launchpad V1/V2 Architecture Map

**Scope:** source-grounded documentation for `contracts/src/v1` and `contracts/src/v2` at commit `d8971ffee042314def2dfd48a413737e3d84ac22`.

This directory documents the implemented RetroPick launchpad only. It does not authorize production Solidity, alter any protocol/economic term, or claim that a Kuru, prediction-market, or PRISM runtime exists in either source tree.

## Reading order

1. [SOURCE_MAP.md](SOURCE_MAP.md) — per-file source inventory and call surface.
2. [V1_ARCHITECTURE.md](V1_ARCHITECTURE.md) and [V2_ARCHITECTURE.md](V2_ARCHITECTURE.md) — implementation truth and trust boundaries.
3. [V1_V2_COMPARISON.md](V1_V2_COMPARISON.md) — normalized source comparison.
4. `v1/` and `v2/` — typed Archify inputs (`*.json`), delivered standalone diagrams (`*.html`), and deliver receipts.
5. `graphify/` — extractor-status reports. These are not Solidity source graphs.

## Provenance and limits

- Pinned source ref: `d8971ff` (`d8971ffee042314def2dfd48a413737e3d84ac22`).
- Working tree carried a pre-existing non-semantic trailing-space edit in `contracts/src/v2/hooks/RetroPickMemeHookV2.sol:19`; it is recorded rather than changed.
- V1 and V2 are compared as independent source scopes. V1 “reference” and V2 “active” are labels, not evidence of behavioral divergence.
- `IRetroPickFeeEscrowV{1,2}` is an ABI-only external dependency. No escrow implementation is present in either scope.
- Vendored `contracts/lib` material is an external dependency, not a first-party launchpad node.

## Diagram index

For each version, the same seven diagrams cover the implemented Uniswap V4 launch path and the Doorway reference machine:

| Diagram | Type | Source-focused question |
|---|---|---|
| `01-architecture` | architecture | Which first-party contracts and external protocols participate? |
| `02-end-to-end-workflow` | workflow | How does a launch move from creator input to curve, graduation, and V4 fees? |
| `03-launch-trade-graduation-sequence` | sequence | Which calls occur during launch, trading, sweep, and V4 seeding? |
| `04-asset-fee-data-flow` | dataflow | Where do token, quote, fee, buyback, escrow-credit, and LP-NFT assets move? |
| `05-lifecycle` | lifecycle | What phases, retries, and delayed rescue transitions exist? |
| `06-trust-boundaries` | architecture | Which actors own privileged, creator, permissionless, and external surfaces? |
| `07-doorway` | architecture | What does the reference-only migration state machine record, and what does it not settle? |

`v1-v2-comparison.html` is generated from normalized logical component IDs. It demonstrates no architectural runtime delta; see the accompanying comparison receipt and report.

## Implemented, target, and unsupported

These three layers stay separate:

- **Implemented / current.** Graduation and secondary-pool integration in both source trees is Uniswap V4. The diagrams show that implemented launch path.
- **Planned / target.** Kuru is the target trading architecture in product documents. Neither `contracts/src/v1` nor `contracts/src/v2` imports or calls Kuru.
- **Unsupported / unimplemented.** Prediction-market and PRISM production contracts are not implemented in either launchpad tree and are not authorized by this documentation. They do not appear as runtime nodes.

Documented gaps, unchanged by these diagrams, are recorded in [V1_ARCHITECTURE.md](V1_ARCHITECTURE.md), [V2_ARCHITECTURE.md](V2_ARCHITECTURE.md), and [V1_V2_COMPARISON.md](V1_V2_COMPARISON.md):

- Doorway is a reference-only migration state machine. It does not settle a bridge.
- Fee escrow is an ABI-only dependency. No escrow implementation is in either scope.
- Snipe-tax configuration does not produce a runtime tax calculation.
- Documented CREATE2 `salt` is not used by the deployer.
- Launchpad runtime test coverage is absent beyond V1 Doorway tests.

## Evidence status

| Check | Status |
|---|---|
| Archify V1 | COMPLETE |
| Archify V2 | COMPLETE |
| Archify V1/V2 comparison | COMPLETE |
| Archify delivery validation | PASS |
| Browser visual validation | SKIPPED / NOT VERIFIED |
| Graphify V1 Solidity source graph | BLOCKED_BY_EXTRACTOR_CAPABILITY |
| Graphify V2 Solidity source graph | BLOCKED_BY_EXTRACTOR_CAPABILITY |
| Architecture Documentation Knowledge Graph | NOT_PRODUCED |

Archify structural/showcase validation passed for the 14 diagram specs (7 V1, 7 V2): 9/9 artifact checks, 0 composition errors, 0 warnings. HTML delivery passed for all 15 artifacts, including the comparison. Each has a `*.deliver.json` receipt with `ok: true`.

Browser visual checks were **skipped** because Chrome/Chromium was unavailable. The 15 `*.visual-check.json` receipts document that skip (`ok: false`, `status: skipped`). They are not visual-validation passes.

Graphify V1 and V2 Solidity source graphs were not produced. Tool: Graphify 0.9.46. Reason: the installed extractor does not classify Solidity `.sol` files as supported code. See [graphify/v1/GRAPH_REPORT.md](graphify/v1/GRAPH_REPORT.md) and [graphify/v2/GRAPH_REPORT.md](graphify/v2/GRAPH_REPORT.md). No `graph.json` or `graph.html` stands in for either source graph. This is an extractor limitation, not a protocol failure.

An Architecture Documentation Knowledge Graph was also not produced. Graphify classified the architecture Markdown as documents and refused to index them without an LLM API key. That attempt is recorded in [graphify/documentation/GRAPH_REPORT.md](graphify/documentation/GRAPH_REPORT.md). It is not a Solidity AST graph and not a V1 or V2 contract source graph.

These artifacts are static source maps, not deployment evidence. They do not establish production readiness. The repository remains at MATH-1 and production Solidity is not authorized by this documentation.

# Exact replication admission and source-asset boundary — 2026-09-28

**Decision state: PROPOSED_NOT_FROZEN.** The Python rational solver and proof identities support exact `h = Gx` for their declared domains. No Phase-1 onchain admission, replication certificate verifier, or Prediction→PRISM custody harness exists. ADR-R01/R04/R05/R17/R18 remain PROPOSED; `SOURCE-ASSET-INTERFACE-FREEZE` and X-I01..X-I07 are not validated. This packet is an architecture recommendation, not an admission approval.

## Compiler-to-chain boundary

1. Payoff compiler fixes a finite terminal-state schema and exact rational target `h`, source payoff columns `G`, settlement asset, maturity/resolution identity, and version. It rejects missing/ambiguous source states and non-qualified source tokens.
2. Spanning engine checks whether the declared source set spans the target. The permanent negative control is `AND(A,B)` against only marginal A, B, and cash columns: the missing interaction term cannot be replaced by `P(A)*P(B)` or any offchain probability estimate.
3. Exact nonnegative solver finds `x >= 0` and optionally minimum executable acquisition cost. `research/prism-model/minimum_cost_replication.py` uses rational basis enumeration with declared limits 16 states/8 components. It is not an onchain arbitrary linear solver, a live market quote, or a general completeness theorem.
4. A separate exact equality recheck recomputes every row of `Gx` and compares it to `h` using canonical rational integers. It also checks source qualification, nonnegative weights, zero/duplicate normalization, decimals, and bounded encoding. Solver success alone is not a certificate.
5. Admission certificate commits the validated inputs and proof result. Onchain series factory admits only an authorized/validated certificate and independently checks at least hash binding, field lengths, uniqueness, signer/authority, expiry/replay, and component/custody consistency. For a bounded matrix, an onchain row-by-row equality recheck is a possible stronger option, but gas and integer encoding must be benchmarked before acceptance. If equality is only offchain-checked, the admission authority is an explicit trust assumption, not a mathematical onchain proof.

Minimum immutable commitment: domain-separated `seriesId`, `payoffHash`, `sourceSetHash`, `replicationHash`, ordered component token addresses and weights, settlement asset and decimals, maturity and resolution identifiers, compiler/schema version, and qualification-policy version. Bind lengths, order, chain ID, factory identity, and exact rational encoding to prevent replay or ambiguous hashes. A source token address alone does not define its payoff; bind market, outcome, result semantics, and resolution identity. The certificate must never authorize mint unless real backing is already received/reserved for that issuance.

## Minimal source asset boundary

Prefer plain ERC-20 custody plus a versioned registry record, rather than an onchain PRISM call into `PredictionMarket` for every solvency check. Candidate fields: `sourceToken`, `sourceType`, `sourceId`, market identity, outcome identity, settlement asset, token decimals, resolution identifier/spec hash, admission status, qualification flags (including collateral class and INVALID payout version), schema version, and any immutable payoff hash. A registry claim is metadata; **actual controlled balance and unique reservation** are the backing. Prediction's collateral sits behind its outcome liability and does not automatically become PRISM backing. A source token may be transferred or redeemed only through a path that preserves PRISM's claim/value over all remaining terminal states.

`docs/prism/04-architecture/SOURCE_ASSET_INTERFACE.md` lists fields the current Prediction kernel exposes and correctly says it is not frozen. ADR-P05's new holder-allocation counterexample and ADR-P19's winner liveness failure are direct reasons not to freeze the payoff/settlement version yet. PRISM cannot value a source claim as a holder-independent half-unit on INVALID while Prediction's accepted rule remains undecided. The registry must never infer backing from Kuru depth, price, indexer state, resolver announcement, or offchain probability.

## X-I01..X-I07 executable acceptance map

| Property | Minimum end-to-end witness required | Current status |
| --- | --- | --- |
| X-I01 qualified admission | Reject unqualified/incorrect-token source; accept one exact qualified YES/NO source with bound metadata | NOT_YET_VALIDATED |
| X-I02 distinct liabilities | Prediction collateral remains owed to outcome holders; PRISM records a separate liability backed by its held source tokens | NOT_YET_VALIDATED |
| X-I03 custody and reservation | Move source ERC-20s into controlled custody, reserve once, reject a second series pledge of the same physical units | NOT_YET_VALIDATED |
| X-I04 source resolution/redemption | Resolve source, then redeem/transform only with a value-conserving accounting transition; no silent deletion of PRISM backing | NOT_YET_VALIDATED |
| X-I05 identity and partial transform | Reject wrong market/result/resolution identity; permit partial transform only when `g_i(ω)=r_i` for every remaining possible state | NOT_YET_VALIDATED |
| X-I06 terminal funding and PRISM redemption | Demonstrate actual settlement-asset funding, accepted payout rule, full/partial holder redemption, and distinct donation/residual accounting | NOT_YET_VALIDATED |
| X-I07 external-service independence | Repeat solvency path with Kuru and indexer unavailable and arbitrary secondary prices; backed redemption must not depend on either | NOT_YET_VALIDATED |

Each row needs Python semantic oracle, machine-readable fixture, Solidity research execution, exact post-state/reject assertion, and stateful invariant where sequence matters. Current PRISM component, settlement, transform, and reservation kernels are separate reduced contracts; combining their passing tests is not an end-to-end harness. Because exact admission and source semantics are not frozen, keep X-I01..X-I07 `NOT_YET_VALIDATED` and `MODULE-ADMISSION-FINANCE-1` NOT MET.

## Partial resolution and Kuru boundary

The existing `T-PARTIAL-001/002` identities support replacing a resolved source payoff column with compatible settlement value only if equality holds on **all still-possible** states. Re-run both when an actual Prediction source is held and its resolution is bound to the certificate. Resolution is not blanket permission to liquidate or mark up backing. Kuru may provide secondary trading for the PRISM ERC-20, but orderbook inventory is never primary collateral; separate solvency, venue compatibility, and live-liquidity-quality gates.

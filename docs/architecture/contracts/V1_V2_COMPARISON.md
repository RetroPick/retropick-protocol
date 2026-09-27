# V1/V2 Launchpad Comparison

## Result

**Semantic result: IDENTICAL.** Each of the fifteen V1 files has a V2 counterpart with identifier/path suffixes normalized (`V1`/`V2`, `v1`/`v2`) and trailing whitespace removed. The normalized textual comparison is empty for every counterpart. There are no source-backed ADDED, REMOVED, MOVED, REROUTED, or CHANGED runtime components.

| Logical component group | Result |
|---|---|
| Factory, Deployer, Curve, Token | `IDENTICAL` |
| Guard, Executor, Locker, BuybackVault | `IDENTICAL` |
| V4 Hook | `IDENTICAL` behavior; V2 line 19 has a non-functional trailing-space text difference |
| Doorway and its interfaces | `IDENTICAL` |
| Fee/launch interfaces and math libraries | `IDENTICAL` |

## Comparison method

- Source ref: `d8971ffee042314def2dfd48a413737e3d84ac22`.
- Scope isolation: `contracts/src/v1` was compared only to `contracts/src/v2` counterpart paths.
- Normalization: replace V1/V2 and v1/v2 identifiers with a shared marker, remove trailing whitespace, then compare each pair.
- Archify comparison input: source-backed logical component IDs are intentionally stable across V1/V2. The generated `v1-v2-comparison.html` therefore shows an unchanged logical architecture. Its receipt records the exact input artifacts.

## Boundaries preserved in both versions

Both implement an Uniswap V4—not Kuru—path; both call an ABI-only fee escrow; both retain the reference-only Doorway state machine; both carry unused snipe-tax/configured CREATE2 semantics described elsewhere; both lack launchpad runtime coverage beyond V1 Doorway tests. These are common findings, not deltas.

## Artifact links

- [V1 component map](v1/01-architecture.html)
- [V2 component map](v2/01-architecture.html)
- [Archify comparison](v1-v2-comparison.html)
- [Comparison receipt](v1-v2-comparison.receipt.json)

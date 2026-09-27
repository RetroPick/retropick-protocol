# Graphify V2 Solidity Source Graph

**Status:** `BLOCKED_BY_EXTRACTOR_CAPABILITY`

**Tool:** Graphify 0.9.46

**Scope:** `contracts/src/v2` only. Vendored `contracts/lib` was not in scope.

**Attempted command:** `graphify extract contracts/src/v2 --mode deep --code-only --out <staging-dir>`

## Reason

The installed extractor does not classify Solidity `.sol` files as supported code. It reported `found 0 code` and an empty graph for all 15 `.sol` files in this scope. Deep mode does not add a Solidity classifier.

## Result

No `graph.json` or `graph.html` was generated. No synthetic graph was substituted. No Solidity file was renamed or transformed to imitate support.

This status is an extractor capability limit. It is not a protocol failure and it is not a finding about V2 correctness.

The implementation map remains [SOURCE_MAP.md](../../SOURCE_MAP.md) and the Archify diagrams in `../../v2/`.

# Maintenance and Repository Rehabilitation

This directory contains the **2026-11-09** non-destructive rehabilitation audit for `RetroPick/retropick-protocol`. It is based on an immutable Git snapshot and deliberately separates proven findings from unverified code/runtime references.

1. [REPOSITORY_AUDIT.md](REPOSITORY_AUDIT.md) — source-of-truth map, inventory metrics, risks and audit limitations.
2. [TRACKED_FILE_CENSUS.tsv](TRACKED_FILE_CENSUS.tsv) — **15,335** tracked blobs/gitlinks with Git hashes and provisional per-path classifications.
3. [CLEANUP_DECISIONS.md](CLEANUP_DECISIONS.md) — no-delete and financial compatibility decisions; deferred candidate work.
4. [VALIDATION_REPORT.md](VALIDATION_REPORT.md) — exact verification status, known historical CI runs and release blockers.

The inventory is reproducible with [`scripts/maintenance/git_inventory.py`](../../scripts/maintenance/git_inventory.py), which generates a per-path TSV, workspace manifest graph and summary from a specified Git revision. Run it from a complete local checkout; its classification labels are provisional.

For onboarding, see [root README](../../README.md), [contributor guide](../../CONTRIBUTING.md), [applications map](../../apps/README.md) and [Solidity guide](../../contracts/README.md). The [earlier hygiene audit](../engineering/REPOSITORY_HYGIENE_AUDIT.md) remains historical evidence of the previous phase.

**Warning:** a matching Git blob SHA or a path-based classification is **not** evidence that a file is unused or safely deletable.

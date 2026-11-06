# CI repair qualification

Scope: workflow initialization and mandatory local Foundry JSON gate. No Solidity changes by this work unit. Hosted Actions status remains NOT_RUN.

- `baseline-workflow-reproducer.log`: expected actionlint failure on baseline `runner.temp` job context.
- `workflow-actionlint.log`: repaired workflow validation passes with actionlint v1.7.7; shellcheck disabled explicitly.
- `parser-unit-tests-final.log`: ten regression tests pass, including an empty required suite borrowing another suite's successes.
- `foundry-schema.json`: genuine Forge v1.8.4 synthetic probe, intentionally one success, one failure, one skip. Its nonzero exit is expected and is not a protocol test failure.
- `schema-rejected-summary.json`: strict gate correctly rejects that probe.
- `canonical-math*`: independently compiled canonical math smoke; completion and exit recorded in manifest when available.
- `qualified-source-hashes.json`: precise workflow/parser/test overlay identities.

The mandatory gate requires nonempty suite objects, a positive minimum pass count, no failures, no skips, known statuses, unique JSON keys and required suite presence with executed tests. Missing RPC or fork skips cannot qualify as a local PASS. This first CI repair does not add the remaining M6, real fork, Safe or static-analysis campaigns.

Canonical invariant minimum is four invariant properties, with both Coordinator and Curve suites required. The existing handler branch test remains selected normally; this minimum does not represent a fresh invariant execution claim.

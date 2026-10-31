# Community economy V2 research experiment

Status: PARTIAL — an experimental curve-only financial vertical slice is implemented and locally tested. Real native/USDC trades, authenticated funding, old-policy checkpointing and independent claims are covered. Treasury vault, rewards, strategies, full controller/venue/release qualification remain open. No production or fork qualification is claimed.

Start with EXECUTIVE_DECISION.md, SOURCE_TRUTH_MATRIX.md, SECURITY_FINDINGS.md, QUALIFICATION_REPORT.md and NEXT_STEPS.md. The original source report is preserved in inputs/deep-research-report.md; its embedded ChatGPT citation identifiers are not independently resolvable sources.

Input SHA-256: `24308e94a3e34e6b873bd63d5f3d34d1f1f1d68b0ba9bc0b4297bcba0a0628ae`.

## Reproduce inventory

From the repository root:

```sh
python3 research/launchpad/community-economy-v2/tools/baseline.py --check
```

The command prints JSON and does not write files. It exits nonzero for modified protected source/deployment/script paths, untracked additions within those paths, changes to original V2 tests, or a branch not descended from the frozen baseline. New experiment tests are permitted. The output is a lexical inventory, not a compiler ABI, audit, or proof of economic correctness.

Evidence: evidence/launchpad/community-economy-v2/2026-10-31-baseline/. Never overwrite earlier runs; create a new iteration directory.

Current implementation: iterations/002-real-curve-accounting.md, V2_EXPERIMENT_ARCHITECTURE.md, FEE_ACCOUNTING_SPEC.md and evidence/launchpad/community-economy-v2/2026-10-31-authenticated-curve/. Candidate economics decision: decisions/ADR-CE01-experimental-community-curve-entitlements.md, PROPOSED only.

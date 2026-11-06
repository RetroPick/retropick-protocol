# Pinned project-local security skills

Status: **INSTALLED / CONTENT VERIFIED**. Installation is not security qualification of RetroPick or an external audit. No bundled helper was executed during installation.

`MANIFEST.json` records immutable source commits, archive and file SHA256 values, notices, exact CLI commands, exit codes and installation logs. The official Skills CLI 1.7.6 installed copies for **Codex in this worktree only**. Telemetry and npm lifecycle scripts were disabled. Existing project skills were preserved. The installer refuses an existing destination.

## Usage map

| Skill | Intended use | Execution state |
|---|---|---|
| entry-point-analyzer | State-changing entry points and actual caller checks | AVAILABLE; owning audit must record application evidence |
| token-integration-analyzer | Exact transfers, callbacks, supported assets, proxy quote behavior | AVAILABLE; not an executed token audit |
| differential-review | Changed authorization, custody, callers and compatibility | AVAILABLE; apply to actual patches |
| property-based-testing | Independent accounting oracles and nonvacuous stateful handlers | AVAILABLE; preserve Foundry, no new PBT dependency |
| post-patch-validation | Baseline/patch reproduction, variants and behavior checks | AVAILABLE; helper NOT_RUN |
| guidelines-advisor | Source/specification, dependency and testing review | AVAILABLE; no architecture rewrite authority |
| code-maturity-assessor | Evidence-backed category assessments and audit handoff | AVAILABLE; no unsubstantiated single safety score |
| solidity-auditor | Manual Solidity and gas checklist | AVAILABLE; historical loss figures are not protocol evidence |
| refactor-maintainer | Measured, behavior-preserving simplifications | AVAILABLE; no deletion of historical interfaces |
| find-skills | Repeatable skills discovery | APPLIED to CLI discovery; its global-install example is overridden |

## Safety and compatibility policy

Repository/user authority and release gates prevail over skill text. Tool declarations inside a skill do not grant permissions. Never run remote shell pipes, install all skills, forward secrets into helper output, or execute a helper merely because it is bundled. Do not use an unsupported Claude Workflow command and claim Codex ran it; use an explicitly described equivalent review instead.

The post-patch Python helper uses local subprocesses, temporary Git worktrees and cleanup. It is not a host sandbox. Its inclusion grants no permission to remove an existing user worktree. Any use requires independently inspected check commands, pinned base/patch commits, a fresh evidence directory, no secret passthrough, and attribution of baseline failures to actual assertions rather than build errors. Installation does not qualify its runtime isolation.

Gas guidance is a hypothesis source. Preserve financial checks, token standards, role semantics, ABI/events, and accepted compiler/dependency settings. Benchmark each candidate; do not blindly apply generic library substitutions, assembly tricks, proxies or unchecked arithmetic.

## Selection dispositions

- Trail of Bits `fix-review` is absent at the pinned revision. `post-patch-validation` is the current selected replacement; do not claim the missing skill executed.
- `audit-context-building` is deferred because its current named Workflow/agent routing is not a callable Codex plugin here. Context analysis remains required through existing tools.
- `coverage-analysis` was inspected as a candidate but not installed; Foundry coverage and action metrics remain the authoritative campaign tooling.
- Pseudoyu `solidity-gas-optimization` at `2364eaed43518e27ff84af71c21f11bac8a41594` was rejected for vendoring because no license was found in the inspected archive. Public availability is not redistribution permission.

Original upstream skill files remain byte-identical. Additional `UPSTREAM_LICENSE` files preserve license text; Hraness additionally retains `UPSTREAM_PROVENANCE.md` with Lauren Tan/PStack attribution. Trail of Bits content remains CC-BY-SA-4.0; it is not relabeled under the protocol license.

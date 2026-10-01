# External Integration Research

This lane contains research against mutable external systems and contracts.
Its current active child is [kuru/](kuru/), for Kuru on Monad as a Launchpad
V2 graduation destination.

Integration research can measure compatibility, expose source assumptions,
derive exact parameter candidates, and preserve failure witnesses. It cannot
freeze a target, accept an integration ADR, or redefine RetroPick accounting.

## Evidence layers

An integration conclusion normally needs to distinguish these layers:

1. **Current-source evidence**: public source snapshot, repository commit or
   release, and documented review date.
2. **Environment identity**: chain ID, deployed router, implementation
   addresses, code hashes, quote asset identity, and block or timestamp.
3. **Pinned fork evidence**: real deployed Router, market, vault, margin
   system, and quote behavior at a recorded block.
4. **Fault/post-state evidence**: injected external failures, exact balance
   changes, deterministic addresses, returned parameters, custody, retry, and
   replay behavior.
5. **Live evidence**: only after the relevant implementation and safety gates
   permit a live transaction, with tx hashes and actor roles recorded.

A simplified mock is useful for deterministic fault injection but cannot be the
final source of integration truth. Conversely, a passing fork test does not
prove long-term operational quality or authorize staging.

## External drift rule

External deployments and implementations can change. A RetroPick path must:

- pin the accepted environment identity;
- verify every observable identity and parameter it depends on;
- fail closed on drift;
- stop new operations rather than silently recompute against changed code;
- require requalification after an external upgrade.

## Integration boundaries

External market infrastructure is not economic backing unless actual controlled
assets and custody explicitly make it so. In particular:

- market liquidity is not an oracle;
- order-book depth is not reserve accounting;
- an indexer is not authority;
- a quote issuer's controls remain an external trust/liveness risk;
- a successful API or SDK example does not establish RetroPick economics.

## Child lanes

| Lane | Status | Purpose |
| --- | --- | --- |
| [kuru/](kuru/) | Active Launchpad/Kuru research | Exact seed, parameter, terminal-Q, retry, drift, custody, fork, and gas research |

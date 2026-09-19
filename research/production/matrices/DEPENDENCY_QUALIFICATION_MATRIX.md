# Dependency Qualification Matrix

| Dependency | Purpose | Scope | Current status | Reverify before production |
|---|---|---|---|---|
| Monad | execution chain | platform | requires current environment qualification | yes |
| Kuru | mature/execution venue | platform + modules | pinned research exists; exact target integration still open | yes |
| RPC provider(s) | chain transport | platform | provider strategy not frozen | yes |
| Indexing stack | derived read model | platform | runtime not implemented | yes |
| Wallet/signing | user/admin transaction signing | platform | implementation strategy not frozen | yes |
| Foundry/OZ/libs | contract engineering | module-specific | repository dependencies exist | on upgrade |
| Chainlink/CRE | future resolution orchestration | PRISM/prediction | research/integration-gated | yes |

Current-source metadata should be added as qualification work proceeds.

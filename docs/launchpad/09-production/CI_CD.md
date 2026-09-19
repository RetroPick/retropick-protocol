# CI/CD

**Status:** DRAFT  
**Owner:** Release + Validation

Required lanes:

```text
contract-format
contract-build
contract-unit
contract-fuzz
contract-invariant
contract-static-analysis
frontend-lint
frontend-typecheck
frontend-unit
frontend-build
backend-test
indexer-build
integration-test
e2e
deployment-smoke
```

Merge-block on build/unit/invariant/typecheck failures, critical security regressions and new untriaged high-severity security findings. Deployment workflows must use environment-scoped secrets and record commit/deployment artifacts.

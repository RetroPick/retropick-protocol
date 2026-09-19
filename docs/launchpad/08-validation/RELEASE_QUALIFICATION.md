# Release Qualification

**Status:** ACTIVE  
**Owner:** Validation + Release

For each candidate, record:

- commit SHA;
- V2 contract build/test/static-analysis results;
- bytecode sizes;
- deployed environment and addresses;
- quote-asset configuration;
- Kuru integration result;
- indexer sync/rebuild status;
- frontend/backend build/test status;
- golden E2E result;
- security findings/dispositions;
- known limitations;
- rollback/redeploy readiness.

Verdict:
```text
PASS
CONDITIONAL_PASS
FAIL
```

CONDITIONAL_PASS lists explicit conditions and cannot be presented as production approval.

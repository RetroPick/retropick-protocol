---
id: LP-STATE
type: normative
product: launchpad
version: v2
status: active
---

# State Machine

Product states:

```text
DRAFT -> ACTIVE -> GRADUATION_READY -> GRADUATING -> GRADUATED -> ARCHIVED
```

The exact Solidity representation may use a smaller enum plus derived readiness; implementation docs must map contract phases to product states precisely.

Rules:
- illegal backwards economic transitions revert;
- readiness does not equal successful destination creation;
- GRADUATING represents secured/committed transition with retryable external completion;
- GRADUATED requires verified Kuru market identity/state;
- recovery/rescue states, if implemented, are explicit and never silently mapped to GRADUATED.

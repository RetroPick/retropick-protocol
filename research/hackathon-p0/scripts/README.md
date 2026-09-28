# Hackathon P0 scripts

Scripts for the dedicated P0 reproducibility profile belong here. The profile
should avoid rerunning expensive production research unless explicitly asked.

Planned flow:

1. Fresh clone.
2. Pinned Python/formal dependencies.
3. Prediction P0 model tests.
4. PRISM P0 exact solver and lot tests.
5. Foundry P0 unit/fuzz/stateful tests.
6. Cross-module harness.
7. Gate report generation.

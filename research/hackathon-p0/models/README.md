# Hackathon P0 models

This directory is reserved for reduced P0 semantic oracles. They must not edit
the production Prediction or PRISM Python models merely to make P0 pass.

Models:

- `prediction_p0.py` implements `HackathonPredictionModel`: binary-only YES/NO lifecycle, bounded arithmetic,
  exact winner redemption.
- `prism_p0.py` implements exact rational replication certificates, minimal
  exact-lot derivation, factory/source admission checks, and a physical-backing
  state oracle for caller-funded mint, transferable claims, donations, and
  in-kind redemption.

The model prints the canonical integer state snapshots used to construct the
Prediction P0 differential fixture. It is an independent semantic oracle; it
does not import or modify the production Prediction model.

Still planned:

- Cross-module fixture generation and execution for YES_WIN and NO_WIN worlds.

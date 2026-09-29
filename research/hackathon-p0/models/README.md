# Hackathon P0 models

This directory is reserved for reduced P0 semantic oracles. They must not edit
the production Prediction or PRISM Python models merely to make P0 pass.

Models:

- `prediction_p0.py` implements `HackathonPredictionModel`: binary-only YES/NO lifecycle, bounded arithmetic,
  exact winner redemption.

The model prints the canonical integer state snapshots used to construct the
Prediction P0 differential fixture. It is an independent semantic oracle; it
does not import or modify the production Prediction model.

Still planned:

- `HackathonPrismModel`: exact rational lot arithmetic, atomic minter-funded
  backing, transferable ERC-20 claim projection, in-kind redemption.
- Cross-module fixture generation for YES_WIN and NO_WIN worlds.

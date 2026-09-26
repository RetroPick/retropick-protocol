# Resolution

Three different events:

1. The world learns the outcome. That is not a contract transition.
2. The committed resolver calls `resolve` and the result becomes immutable. State becomes RESOLVED.
3. `openRedemption` checks funding and the state becomes REDEEMABLE.

An HTTP API is not a trustless oracle. The kernel stores `resolver` and `resolutionSpecHash`. Settlement does not read a URL. Mutable UI text is not a settlement input.

Phase-1 results are only YES_WIN, NO_WIN, and INVALID. A second `resolve` reverts.

The resolver is a trusted role for the result. The model does not remove that trust. It prevents the resolver from minting outcome tokens or withdrawing live collateral. Replacing the resolver with a specific oracle is a later ADR. This research does not claim the resolver is decentralized.

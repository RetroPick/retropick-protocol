# Prediction module — executive summary

**Status:** research prototype. Not promoted. ADR proposals are not accepted.  
**Date:** 2026-09-26

RetroPick's prediction module is a binary, fully collateralized market whose outcome assets are normal ERC-20s. One unit of qualified collateral splits into one YES and one NO before resolution. The market contract is the collateral controller in the research kernel. A separate `CompleteSetVault` remains the picture in `docs/prism/protocol/PRISM_PROTOCOL_SPEC.md` and is not silently deleted. ADR-P03 proposes colocating custody in the market.

Phase-1 results are `YES_WIN`, `NO_WIN`, and `INVALID`. `INVALID` is explicit. It is not an automatic copy of Polymarket's UMA "Unknown/50-50" path. Integer INVALID redemption uses a cumulative floor. Paying `ceil(q/2)` on both sides is insolvent for one unit. Paying `floor(q/2)` on every 1-unit call strands the payout.

`RESOLVED` and `REDEEMABLE` are different states. Redemption is impossible in `RESOLVED`.

The integer model and the Foundry kernel agree on the committed fixtures. PRED-CONTRACT-1 is not PASS. Slither 0.11.6 did not build a complete IR. Echidna, Medusa, Halmos, and Mythril were not run. No Kuru market was deployed. Human acceptance of the ADRs was not granted.

Module status: `CONTRACT_CANDIDATE` for the research harness only. Not `READY_FOR_V2_INTEGRATION`.

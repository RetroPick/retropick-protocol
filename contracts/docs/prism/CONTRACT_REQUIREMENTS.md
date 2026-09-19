# PRISM Contract Requirements

**Status:** CANONICAL IMPLEMENTATION PROJECTION

The complete normative requirement set lives in `../../../docs/prism/protocol/CONTRACT_REQUIREMENTS.md`.

Implementation must preserve at minimum:

1. native Prediction and PRISM creation remain separate;
2. activated PRISM series definitions are immutable;
3. same-chain backing is authoritative in the PRISM vault/accounting;
4. runtime backing is component-wise: `B_i >= S*x_i`;
5. minting is backing-first;
6. reserved units cannot be double pledged;
7. pre-resolution redemption reduces liability before releasing backing;
8. partial-resolution transformation preserves remaining payoff;
9. final resolution is one-time;
10. `REDEEMABLE` requires full settlement funding;
11. complete-set issuance/merge conserves collateral;
12. fixed-point rounding biases toward solvency;
13. retail secondary BUY is separate from primary CREATE;
14. events support independent reconstruction;
15. admin authority cannot seize reserved backing or mint unbacked claims;
16. Solidity must support differential/invariant testing against the Python reference model.

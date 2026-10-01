# P0 terminal-Q sufficient-envelope boundary

**Classification:** `EXHAUSTIVELY_VERIFIED_WITHIN_DOMAIN` only for the endpoint binary search over the fixed reduced-model sufficient predicate; `SUPPORTED_BY_SIMULATION` for exact endpoint cross-checks; `NOT_YET_VALIDATED` for accepted P0 policy and real Router/vault execution.

This increment extends the [wide-Q sufficient proof](terminal-q-wide-bound-2026-09-30.md) rather than replacing it. It does **not** recommend or accept an economic `graduationQuoteCeiling`. The reported endpoint is the largest raw terminal Q, under the generator's uint256 search cap, for which all conservative reduced-model sufficient conditions remain true. It is not the exact mathematical maximum admissible Q.

The [generator](../../../research/integration/kuru/p0_terminal_envelope.py) binary-searches the boundary where any sufficient condition first fails, starting from the exact product-invariant lower Q and the configured threshold. It records both the last covered endpoint and its immediate successor. For every positive candidate profile, it separately evaluates the exact reduced seed model at:

- the fresh immediate-completion Q, computed with the exact production-arithmetic completion model;
- the configured graduation threshold; and
- the conservative sufficient upper endpoint.

The [machine artifact](p0-terminal-envelope-2026-10-01.json) covers both P0 quote classes:

- native MON, 18 decimals;
- canonical chain-10143 Circle test USDC, six decimals, address `0x534b2f3A21130d7a60830c2Df862319e593943A3`.

| Sufficient coverage endpoint | MON | Circle USDC |
| --- | ---: | ---: |
| MINIMUM_VALID_LAUNCH | 10737418239999999999999 | 10737418239 |
| SMALL | 1071307035283446712064476 | 1071307081660 |
| MEDIUM | 10734928179339843850709334 | 10734928235517 |
| LARGE | 1073741555832778263542428268 | 1073741556368844 |
| MAXIMUM_SUPPORTED_CANDIDATE | 10730358793425378040763235353 | 10730358794004614 |

All ten positive rows have exact admissible fresh-completion, configured-threshold and sufficient-upper checks, and each conservative endpoint exceeds the earlier illustrative 100×-threshold stress endpoint. The immediate successor is recorded and the focused tests prove that the two minimum-valid successor witnesses fail the sufficient predicate.

The one-token `FACTORY_MINIMUM_NEGATIVE` profile remains rejected because its seed sizes do not satisfy the candidate minimum-size rule. This is a permanent contradiction between that profile and the candidate tuple, not evidence that its raw quote is otherwise unseedable.

These endpoints do not close B3/B4:

- they are sufficient-proof coverage limits, not owner-selected economic ceilings;
- they apply only to the pinned reduced first-deposit model, not real Router execution;
- profile points do not constitute the continuous accepted LaunchConfig domain;
- the round-trip terminal-Q path dependence remains, so a generic completion-ceiling guard still requires production-architecture qualification;
- no production Solidity, ADR status, fork boundary or live transaction is authorized by this report.

Reproduce:

```bash
python3 research/integration/kuru/p0_terminal_envelope.py
python3 -m unittest discover -s research/integration/kuru -p 'test_*.py'
```

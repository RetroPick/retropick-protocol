# M6 measured gas and remaining economic qualification

Genuine local v4 revenue trace: `evidence/launchpad/community-economy-v2/2026-11-05-m6-revenue/20261105T133842923862Z/genuine-revenue.log`. Extracted call gas and full call arguments are retained in `gateway-gas-trace.json`.

| Quote model | Exact-input quote→token | Exact-input token→quote | Exact-output quote→token | Exact-output token→quote |
|---|---:|---:|---:|---:|
| Native | 1,025,223 | 740,058 | 684,080 | 815,739 |
| Six-decimal modeled ERC20 | 1,064,266 | 893,977 | 843,325 | 843,412 |

These are local **payment-gateway call trace** measurements including real Manager operations, authenticated revenue funding, protocol escrow and entitlement allocation. They are not the pure Hook overhead, fork gas, a controlled baseline difference or a guaranteed target-chain transaction cost. Cold/warm state, first asset-credit writes and policy epochs differ. No gas-price forecast is assumed.

The cost is material. For sensitivity only, 1,000,000 gas costs 0.0001 MON at0.1gwei, 0.001 MON at1gwei and0.01 MON at10gwei. These are arithmetic scenarios, not observed network prices. Small trades and small fee claims may be economically unattractive. Six-decimal rewards cannot be compared with MON gas costs without an explicit conversion-price assumption.

The current implementation deliberately favors immediate epoch-bound allocation and independent backing verification. It has a bounded allocation list of at most10; the tested genuine policy uses3 recipients. It avoids conversion swaps, buyback sandwiches and LP-principal fee accounting, but this does not prove the gas/adoption tradeoff is acceptable.

Before adoption, profile actual opcode/storage costs, first versus repeated swaps, maximum recipient count and claim batching independently. Any optimization must retain authenticated funding, policy-transition exclusion, exact protocol remittance and physical backing; removing those checks merely to lower a gas number is not acceptable. A different delayed-allocation design would need its own accounting specification and temporal-rights proof.

Trading volume alone does not prove retention or sustainable creator income. Wash trading incurs trading fees and gas and creates no external income; enforceable allocation cannot make those circular transfers intrinsically profitable. Treasury/controller concentration and low-volume liveness remain product/governance risks. No guaranteed yield, buyback return or external-business revenue right is implemented.

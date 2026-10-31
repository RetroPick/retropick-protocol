# Migration and compatibility

NEW_EXPERIMENT only. Existing V1/V2 source, tests, deployment scripts, manifests and production ABI files remain protected. No deployed token, pool, hook or factory identity changes. CE mode is a new opt-in launch path, not a retrofit of earned legacy rights.

The existing constructor terms, fee denominators, token supply and curve formula remain unchanged. Community mode disables legacy source buyback and legacy recipient-reassignment paths; these deliberate differences apply only to new CE launches. Direct canonical-versus-experimental legacy tests cover native and exact six-decimal quotes across eight buy/sell cycles, fee settlement and reserve/readiness comparisons. They do not prove every historical state transition equivalent.

The router receives pre-separated C, never gross base fees. Protocol P retains the existing escrow. Uniswap v4 CE registration disables unsupported creator/hook revenue capture until a separately qualified adapter exists. Pool LP fees remain independent. Kuru continuous fees remain BLOCKED_EXTERNAL_CAPABILITY. Graduation integration qualification uses mocked venue destinations; it is not a live market claim.

Future SDK/indexer work must distinguish creator identity, current controller, fixed fee recipients, modules, original and current policy, epochs, settlement sequence, funding, outstanding claims and unsupported venue revenue. No SDK/indexer/frontend changes are included. Original ABI surfaces are retained where feasible; compiler-derived new ABIs are evidence artifacts, not production replacements.

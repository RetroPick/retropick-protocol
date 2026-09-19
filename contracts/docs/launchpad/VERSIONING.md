# Contract Versioning

**Status:** ACCEPTED  
**Owner:** Smart Contracts

`src/v1/` is the stable/reference generation. `src/v2/` is the active feature-development generation.

V1 receives security maintenance and critical correctness fixes. V2 owns new launchpad functionality, Monad integration changes and Kuru graduation work.

When V2 diverges, it must receive dedicated unit, fuzz, invariant and integration tests. Shared libraries may be introduced only when their semantics are genuinely identical and the change does not create hidden cross-version coupling.

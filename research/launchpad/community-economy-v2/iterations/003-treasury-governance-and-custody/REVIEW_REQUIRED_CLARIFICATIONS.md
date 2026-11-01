# Independent review follow-up
G2 remains BLOCKED by CE003-001. No custody/dependency import.

Additional policy clarifications required before G3: enforce governed role changes against immediate AccessControl.renounceRole, protect self-admin against both revoke and renounce, preserve address(0) open executor role against revocation, expose explicit expired/executable views because upstream Ready does not imply unexpired. Constructor failures must bubble; never catch a failed CREATE and consume the deterministic nonce.

These are proposed specification clarifications, not implemented security fixes. First resolve unique launch binding through an independently reviewed authenticated selection/commitment design with preexisting-credit analysis and owner acceptance of any changed bootstrap authority. Original owner acceptance covers the exact initial candidate, not arbitrary changes.

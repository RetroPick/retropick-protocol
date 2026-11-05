# Legacy V2 — hackathon testnet freeze

This archive preserves the V2 implementation recorded for the current hackathon deployment on Monad testnet (chain 10143), including Kuru. The recorded source revision is `f0363249f4b74e58dde37d1241742ca5a92bcfe3`, not the later Community Economy development checkpoint.

The Factory address in the preserved deployment record is `0xa7f18b9eceb0A9852b08408854A45D00fc682454`. Existing deployment addresses, frontend configuration, economic entitlements, custody and historical evidence remain unchanged by this archive. No deployment or administration transaction is part of this work.

`src/v2/` contains byte-for-byte Git blobs from that revision. Keep original Solidity contract names: renaming or wrapping the contracts would create different artifacts. `legacy-v2` is the archive name, not a new deployed contract or proxy.

`MANIFEST.json` records original paths, source revisions, Git blob IDs, SHA-256 hashes and dependency gitlinks. `records/` preserves the deployment manifest, ABI catalog and historical source-verification evidence. These are recorded historical results; a fresh RPC/codehash reconciliation has not been performed by this archival task.

Verify the archive from any working directory:

```bash
python3 /absolute/path/to/contracts/legacy-v2/verify.py
```

For bytecode reproduction, use the **original virtual source paths** (`src/v2/...`), exact dependency revisions and each contract's compiler settings from `records/deployments/monad-testnet/abi/manifest.json`. The historical build embedded absolute remappings. Compiling relocated files under new source paths can alter metadata and CREATE2 identities, including Kuru locks. This directory is deliberately outside the active `contracts/src/` tree; it does not introduce another default artifact namespace.

Do not update this snapshot with current development files, strip Kuru from it, or switch the judging application to a new deployment. New permissionless-venue work proceeds separately. The later Kuru regression archive under `src/legacy/v2/kuru/` serves a different purpose and is not the deployed-source snapshot.

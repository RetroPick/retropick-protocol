# Third-party attribution

The root MIT license covers original RetroPick project source. It does not relicense vendored files, Git submodules, dependencies or third-party artwork. Their original notices and licenses remain applicable.

- Solidity: see [contracts/THIRD_PARTY_NOTICES.md](contracts/THIRD_PARTY_NOTICES.md) and `contracts/licenses/`. Preserve SPDX headers and dependency license files. Uniswap deployment components can have different licensing from narrow MIT interfaces; do not infer deployment rights from the root license.
- Foundry testing: forge-std and recursively pinned submodule notices.
- Frontend: Next.js/React, viem, Tailwind, shadcn/Base UI/Radix UI, lucide and other packages pinned in `pnpm-lock.yaml`; their license files are distributed in installed packages. The preserved shadcn vendor CSS has its own source attribution.
- Kuru integration interfaces are narrow observable interfaces; external Kuru contracts are not owned or relicensed by RetroPick. The deployment uses the environment recorded in the manifest.

For reproducibility, initialize recursive Git submodules and install from the frozen lockfile. Review third-party licensing and issuer/venue conditions independently before any production use.

import { retroPickLaunchFactoryV2Abi } from '@retropick/abi/abi';
import type { Address } from './instruments';
import type { ContractFamily, VerifiedDeployment } from './contract-registry';

/**
 * Verified RetroPick V2 deployments on Monad Testnet (chain 10143), populated from
 * the canonical ABI catalog (`@retropick/abi`, derived from the frozen deployment
 * bundle at `deployments/monad-testnet/abi/`). Every source here is Sourcify
 * `exact_match` verified on both the BlockVision Monad endpoint and the public
 * Sourcify repository — see
 * `evidence/launchpad/v2-monad-testnet/source-verification-foundry.md`.
 *
 * This module intentionally does not mutate `contractRegistry` in
 * `contract-registry.ts`: that file is compiled by `scripts/test-frontend.mjs`
 * with bare `tsc` flags and executed under Node's CJS test path, which cannot
 * resolve workspace TypeScript imports. Compose instead:
 * `resolveContractDeployment(chainId, family, verifiedDeployments)`.
 */
export const VERIFIED_V2_SOURCE_COMMIT = 'f0363249f4b74e58dde37d1241742ca5a92bcfe3';

const monadTestnet: Partial<Record<ContractFamily, VerifiedDeployment>> = {
  // The launchpad's static executable entry contract on chain 10143: launches and
  // curve trading route through the factory. Tokens/curves are per-launch dynamic
  // instances of the factory-created templates (same catalog ABIs).
  'launch-token': {
    address: '0xa7f18b9eceb0A9852b08408854A45D00fc682454' as Address,
    abi: retroPickLaunchFactoryV2Abi,
    sourceCommit: VERIFIED_V2_SOURCE_COMMIT,
  },
};

/** Reviewed, chain-specific verified deployments keyed by chain id. */
export const verifiedDeployments: Readonly<
  Record<number, Partial<Record<ContractFamily, VerifiedDeployment>>>
> = {
  10143: monadTestnet,
};

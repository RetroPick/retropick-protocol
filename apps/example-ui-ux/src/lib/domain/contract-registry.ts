import type { Address, InstrumentContractRef } from './instruments';

export type ContractFamily = InstrumentContractRef['family'] | 'prism-claim-token';
export interface VerifiedDeployment {
  address: Address;
  abi: readonly unknown[];
  sourceCommit: string;
}

/** Only reviewed, chain-specific deployments belong here. None are configured for this demo. */
export const contractRegistry: Readonly<Record<number, Partial<Record<ContractFamily, VerifiedDeployment>>>> = {};

export function resolveContractDeployment(chainId: number, family: ContractFamily, deployments: Readonly<Record<number, Partial<Record<ContractFamily, VerifiedDeployment>>>> = contractRegistry): VerifiedDeployment | null {
  const entry = deployments[chainId]?.[family];
  return entry?.address && entry.abi.length ? entry : null;
}

export function hasExecutableContract(chainId: number, ref: InstrumentContractRef, deployments: Readonly<Record<number, Partial<Record<ContractFamily, VerifiedDeployment>>>> = contractRegistry): boolean {
  const deployment = resolveContractDeployment(chainId, ref.family, deployments);
  if (!deployment) return false;
  if (ref.family === 'launch-token') return Boolean(ref.tokenAddress && ref.poolAddress);
  if (ref.family === 'market-engine-v1') return Boolean(ref.marketEngine === deployment.address && ref.templateId);
  return Boolean(ref.statePool === deployment.address && ref.statePoolId && ref.claimId !== undefined);
}

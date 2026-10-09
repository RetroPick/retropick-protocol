import { createPublicClient, defineChain, http, type Address } from 'viem';
import release from './release.json';
export { release };
export const monad = defineChain({ id: 10143, name: 'Monad Testnet', nativeCurrency: { name: 'MON', symbol: 'MON', decimals: 18 }, rpcUrls: { default: { http: ['https://testnet-rpc.monad.xyz'] } }, blockExplorers: { default: { name: 'Monad Explorer', url: 'https://testnet.monadexplorer.com' } }, testnet: true });
export const chain = createPublicClient({ chain: monad, transport: http('/api/chain', { batch: { batchSize: 30, wait: 10 }, retryCount: 1 }) });
export const addresses = Object.fromEntries(Object.entries(release.addresses).filter(([, v]) => typeof v === 'string' && v.startsWith('0x'))) as Record<string, Address>;
export const explorer = (value: string, kind = 'address') => `${monad.blockExplorers.default.url}/${kind}/${value}`;
export const short = (value: string) => `${value.slice(0, 6)}…${value.slice(-4)}`;
export const liveMode = () => process.env.NEXT_PUBLIC_DATA_MODE !== 'mock';

export function errorText(error: unknown) {
  if(error && typeof error==='object' && 'shortMessage' in error) return String(error.shortMessage);
  return error instanceof Error ? error.message : 'Network unavailable. Please retry.';
}

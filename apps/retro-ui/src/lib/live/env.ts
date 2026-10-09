import { chooseDataMode } from '@/lib/liquidity/registry';

/** Resolved live-mode configuration. All reads fail closed through chooseDataMode. */
export const DATA_MODE = chooseDataMode(
  import.meta.env.VITE_DATA_MODE as string | undefined,
  import.meta.env.VITE_INDEXER_URL as string | undefined,
);

export const INDEXER_URL = DATA_MODE === 'live'
  ? (import.meta.env.VITE_INDEXER_URL as string).replace(/\/$/, '')
  : null;

export const RPC_URL = (import.meta.env.VITE_MONAD_RPC_URL as string | undefined) ?? 'https://testnet-rpc.monad.xyz';

export const CHAIN_ID = 10143;

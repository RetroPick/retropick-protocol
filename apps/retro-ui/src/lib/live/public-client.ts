import { createChain, type ChainClient } from '@retropick/launchpad-sdk/chain';
import { RPC_FALLBACK_URL, RPC_URL } from './env';

/** Shared read-only Monad Testnet client (chain 10143, batched multicall, primary RPC with ordered failover). */
export const publicClient: ChainClient = createChain(RPC_FALLBACK_URL ? [RPC_URL, RPC_FALLBACK_URL] : RPC_URL);

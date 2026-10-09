import { createChain, type ChainClient } from '@retropick/launchpad-sdk/chain';
import { RPC_URL } from './env';

/** Shared read-only Monad Testnet client (chain 10143, batched multicall). */
export const publicClient: ChainClient = createChain(RPC_URL);

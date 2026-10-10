import type { Address } from 'viem';
import type { ChainClient } from './chain.ts';
import { kuruAbi } from './abis/kuruAbi.ts';
/** Mirrors the pinned book's _checkIfCancelledOrFilled: consumed orders can retain nonzero storage size. */
export async function readKuruOrder(chain: ChainClient, market: Address, orderId: number, blockNumber?: bigint) {
  if (!Number.isSafeInteger(orderId) || orderId <= 0 || orderId >= 2 ** 40) throw Error('Invalid event-derived order id.');
  const order = await chain.readContract({ address: market, abi: kuruAbi, functionName: 's_orders', args: [orderId], blockNumber });
  if (order[5] === 0 || order[1] === 0n) return { order, active: false };
  const [head] = await chain.readContract({ address: market, abi: kuruAbi, functionName: order[7] ? 's_buyPricePoints' : 's_sellPricePoints', args: [BigInt(order[5])], blockNumber });
  return { order, active: head !== 0 && head <= orderId };
}

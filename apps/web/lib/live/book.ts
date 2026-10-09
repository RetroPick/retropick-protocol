import type { Hex } from 'viem';
export function decodeBook(hex: Hex) {
  const words = hex.slice(2).match(/.{64}/g)?.map(word => BigInt(`0x${word}`)) || [];
  const bids: { price: bigint; size: bigint }[] = [], asks: { price: bigint; size: bigint }[] = [];
  let i = 1;
  while (i < words.length && words[i] !== 0n) { if (i + 1 >= words.length) throw Error('Malformed orderbook'); bids.push({ price: words[i], size: words[i + 1] }); i += 2; }
  i++;
  while (i + 1 < words.length) { asks.push({ price: words[i], size: words[i + 1] }); i += 2; }
  return { block: words[0] || 0n, bids, asks };
}

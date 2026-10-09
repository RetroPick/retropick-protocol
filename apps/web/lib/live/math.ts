export const BPS = 10_000n;
export function amountOut(input: bigint, reserveIn: bigint, reserveOut: bigint) {
  if (input <= 0n || reserveIn <= 0n || reserveOut <= 0n) return 0n;
  return input * reserveOut / (reserveIn + input);
}
export function buyQuote(input: bigint, quoteReserve: bigint, tokenReserve: bigint, remaining: bigint, fee: bigint, tax: bigint) {
  const net = input - input * fee / BPS - input * tax / BPS;
  const output = amountOut(net, quoteReserve, tokenReserve);
  return output < remaining ? output : remaining;
}
export function sellQuote(input: bigint, tokenReserve: bigint, quoteReserve: bigint, fee: bigint, tax: bigint) {
  const gross = amountOut(input, tokenReserve, quoteReserve);
  return gross - gross * fee / BPS - gross * tax / BPS;
}
export function minOutput(output: bigint, slippageBps = 50n) { return output * (BPS - slippageBps) / BPS; }

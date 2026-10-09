import { type Address, zeroAddress, isAddress } from 'viem';
import { addresses, chain } from './client';
import { coordinatorAbi, curveAbi, tokenAbi } from './abi';
export async function readLaunch(token: Address, account?: Address) {
  if (!isAddress(token)) throw Error('Invalid launch token address');
  const blockNumber = await chain.getBlockNumber({ cacheTime: 0 });
  const [packet, ledger, receipt, name, symbol, supply, balance] = await Promise.all([
    chain.readContract({ address: addresses.coordinator, abi: coordinatorAbi, functionName: 'packet', args: [token], blockNumber }),
    chain.readContract({ address: addresses.coordinator, abi: coordinatorAbi, functionName: 'ledger', args: [token], blockNumber }),
    chain.readContract({ address: addresses.coordinator, abi: coordinatorAbi, functionName: 'receipt', args: [token], blockNumber }),
    chain.readContract({ address: token, abi: tokenAbi, functionName: 'name', blockNumber }),
    chain.readContract({ address: token, abi: tokenAbi, functionName: 'symbol', blockNumber }),
    chain.readContract({ address: token, abi: tokenAbi, functionName: 'totalSupply', blockNumber }),
    account ? chain.readContract({ address: token, abi: tokenAbi, functionName: 'balanceOf', args: [account], blockNumber }) : 0n,
  ]);
  if (packet.token.toLowerCase() !== token.toLowerCase() || packet.curve === zeroAddress) throw Error('Not a RetroPick V2 launch');
  if (packet.quoteAsset !== zeroAddress || packet.venue !== 1) throw Error('This demo supports native MON launches graduating to Kuru.');
  const [reserves, remaining, reserved, realQuote, fee, tax, completion] = await Promise.all([
    chain.readContract({ address: packet.curve, abi: curveAbi, functionName: 'getReserves', blockNumber }),
    chain.readContract({ address: packet.curve, abi: curveAbi, functionName: 'sellableTokens', blockNumber }),
    chain.readContract({ address: packet.curve, abi: curveAbi, functionName: 'reservedTokens', blockNumber }),
    chain.readContract({ address: packet.curve, abi: curveAbi, functionName: 'realQuoteReserve', blockNumber }),
    chain.readContract({ address: packet.curve, abi: curveAbi, functionName: 'feeBps', blockNumber }),
    chain.readContract({ address: packet.curve, abi: curveAbi, functionName: 'creatorTaxBps', blockNumber }),
    ledger.phase === 0 ? chain.readContract({ address: packet.curve, abi: curveAbi, functionName: 'completionQuote', blockNumber }) : [0n, 0n] as const,
  ]);
  let custody: { lp: bigint; excess: bigint } | undefined;
  if (ledger.phase === 2) {
    const [lp, excess] = await Promise.all([
      chain.readContract({ address: receipt.lpAsset, abi: tokenAbi, functionName: 'balanceOf', args: [ledger.protectedLPReceiver], blockNumber }),
      chain.readContract({ address: token, abi: tokenAbi, functionName: 'balanceOf', args: [ledger.protectedExcessReceiver], blockNumber }),
    ]);
    custody = { lp, excess };
  }
  return { token, packet, ledger, receipt, name, symbol, supply, balance, reserves, remaining, reserved, realQuote, fee: BigInt(fee), tax: BigInt(tax), completion, custody, blockNumber, observedAt: Date.now() };
}
export type LiveLaunch = Awaited<ReturnType<typeof readLaunch>>;

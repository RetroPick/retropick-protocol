import { zeroAddress, type Address } from 'viem';
import { addresses,release,type ChainClient } from './chain.ts';
import {decodeBook} from './book.ts';
export {kuruAbi,marginAbi} from './abi.ts';
import {kuruAbi,marginAbi,routerAbi,kuruEnvironmentAbi} from './abi.ts';
export async function readKuru(chain:ChainClient,market: Address, token: Address, vault: Address, account?: Address) {
  const blockNumber = await chain.getBlockNumber({ cacheTime: 0 });
  await chain.readContract({address:addresses.kuruEnvironment,abi:kuruEnvironmentAbi,functionName:'validate',blockNumber});
  const router = release.kuruEnvironment.router as Address;
  const [params, vaultParams, best, encoded, margin, orderImpl, vaultImpl, registered] = await Promise.all([
    chain.readContract({ address: market, abi: kuruAbi, functionName: 'getMarketParams', blockNumber }),
    chain.readContract({ address: market, abi: kuruAbi, functionName: 'getVaultParams', blockNumber }),
    chain.readContract({ address: market, abi: kuruAbi, functionName: 'bestBidAsk', blockNumber }),
    chain.readContract({ address: market, abi: kuruAbi, functionName: 'getL2Book', args: [20, 20], blockNumber }),
    chain.readContract({ address: router, abi: routerAbi, functionName: 'marginAccountAddress', blockNumber }),
    chain.readContract({ address: router, abi: routerAbi, functionName: 'orderBookImplementation', blockNumber }),
    chain.readContract({ address: router, abi: routerAbi, functionName: 'kuruAmmVaultImplementation', blockNumber }),
    chain.readContract({ address: router, abi: routerAbi, functionName: 'verifiedMarket', args: [market], blockNumber }),
  ]);
  if (registered.some((v, i) => String(v).toLowerCase() !== String(params[i]).toLowerCase()) || params[2].toLowerCase() !== token.toLowerCase() || params[4] !== zeroAddress || vaultParams[0].toLowerCase() !== vault.toLowerCase() || margin.toLowerCase() !== release.kuruEnvironment.marginAccount.toLowerCase() || orderImpl.toLowerCase() !== release.kuruEnvironment.orderBookImplementation.toLowerCase() || vaultImpl.toLowerCase() !== release.kuruEnvironment.vaultImplementation.toLowerCase()) throw Error('Kuru identity/environment mismatch; trading disabled.');
  const [quoteBalance, baseBalance] = account ? await Promise.all([
    chain.readContract({ address: margin, abi: marginAbi, functionName: 'getBalance', args: [account, zeroAddress], blockNumber }),
    chain.readContract({ address: margin, abi: marginAbi, functionName: 'getBalance', args: [account, token], blockNumber }),
  ]) : [0n, 0n];
  const trades = await chain.getContractEvents({address:market,abi:kuruAbi,eventName:'Trade',fromBlock:blockNumber > 99n ? blockNumber - 99n : 0n,toBlock:blockNumber}).catch(() => undefined);
  return { trades, params, best, book: decodeBook(encoded), margin, quoteBalance, baseBalance, blockNumber, observedAt: Date.now() };
}
export type KuruState = Awaited<ReturnType<typeof readKuru>>;

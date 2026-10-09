import { parseAbi, zeroAddress, type Address } from 'viem';
import { chain, release } from './client';
import {decodeBook} from './book';
export const kuruAbi = parseAbi([
  'function getMarketParams() view returns (uint32,uint96,address,uint256,address,uint256,uint32,uint96,uint96,uint256,uint256)',
  'function getVaultParams() view returns (address,uint256,uint96,uint256,uint96,uint96,uint96,uint96)',
  'function bestBidAsk() view returns (uint256,uint256)',
  'function getL2Book(uint32,uint32) view returns (bytes)',
  'function addBuyOrder(uint32 price,uint96 size,bool postOnly) returns (uint40)',
  'function addSellOrder(uint32 price,uint96 size,bool postOnly) returns (uint40)',
  'function batchCancelOrders(uint40[] orderIds)',
  'function s_orders(uint40) view returns (address owner,uint96 size,uint40 prev,uint40 next,uint40 flippedId,uint32 price,uint32 flippedPrice,bool isBuy)',
  'event OrderCreated(uint40 orderId,address owner,uint96 size,uint32 price,bool isBuy)',
  'event Trade(uint40 orderId,address makerAddress,bool isBuy,uint256 price,uint96 updatedSize,address takerAddress,address txOrigin,uint96 filledSize)',
  'event OrdersCanceled(uint40[] orderId,address owner)',
]);
export const marginAbi = parseAbi(['function deposit(address user,address token,uint256 amount) payable', 'function getBalance(address user,address token) view returns (uint256)', 'function withdraw(uint256 amount,address token)']);
const routerAbi = parseAbi(['function marginAccountAddress() view returns (address)', 'function orderBookImplementation() view returns (address)', 'function kuruAmmVaultImplementation() view returns (address)', 'function verifiedMarket(address) view returns (uint32,uint96,address,uint256,address,uint256,uint32,uint96,uint96,uint256,uint256)']);
export async function readKuru(market: Address, token: Address, vault: Address, account?: Address) {
  const blockNumber = await chain.getBlockNumber({ cacheTime: 0 });
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

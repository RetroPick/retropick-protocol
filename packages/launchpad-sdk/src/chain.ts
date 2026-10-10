import {createPublicClient,defineChain,http,fallback,type Address} from 'viem';
import {release} from './release.ts';
export {release};
export const monad=defineChain({id:10143,name:'Monad Testnet',nativeCurrency:{name:'MON',symbol:'MON',decimals:18},rpcUrls:{default:{http:['https://testnet-rpc.monad.xyz']}},contracts:{multicall3:{address:'0xcA11bde05977b3631167028862bE2a173976CA11',blockCreated:251449}},blockExplorers:{default:{name:'Monad Explorer',url:'https://testnet.monadexplorer.com'}},testnet:true});
export const addresses=Object.fromEntries(Object.entries(release.addresses).filter(([,v])=>typeof v==='string'&&v.startsWith('0x'))) as Record<string,Address>;
// rank:false keeps strict order: urls[0] is the primary, later urls serve only
// as failover after a deterministic RPC error (4xx, wrong-chain), which is not retried.
const rpcTransport=(urls:string[])=>{const options={batch:{batchSize:30,wait:10},retryCount:2};return urls.length===1?http(urls[0],options):fallback(urls.map(u=>http(u,options)),{rank:false});};
export const createChain=(url:string|string[])=>createPublicClient({chain:monad,batch:{multicall:{batchSize:4096,wait:25}},transport:rpcTransport(Array.isArray(url)?url:[url])});
export type ChainClient=ReturnType<typeof createChain>;
export const explorer=(value:string,kind='address')=>`${monad.blockExplorers.default.url}/${kind}/${value}`;
export const short=(value:string)=>`${value.slice(0,6)}…${value.slice(-4)}`;
export function errorText(error:unknown){if(error&&typeof error==='object'&&'shortMessage'in error)return String(error.shortMessage);return error instanceof Error?error.message:'Network unavailable. Please retry.';}

import { writeFileSync, mkdirSync } from 'node:fs';
import { createChain, release, addresses } from '../src/chain.ts';
import { curveAbi } from '../src/abis/curveAbi.ts';
import { coordinatorAbi } from '../src/abis/coordinatorAbi.ts';
import { tokenAbi } from '../src/abis/tokenAbi.ts';
import { encodeFunctionData, keccak256, parseAbi, type Address } from 'viem';
const url=process.env.FRONTEND_RPC_BENCHMARK_URL??'https://testnet-rpc.monad.xyz';
const count=Number(process.env.RPC_BENCHMARK_SAMPLES??30);
if (!Number.isInteger(count)||count<1) throw Error('Invalid sample count');
const modes=[{name:'parallel-http',httpBatch:false,multicall:false},{name:'json-rpc-batch',httpBatch:true,multicall:false},{name:'multicall3',httpBatch:false,multicall:true}] as const;
const fetchOriginal=globalThis.fetch;
let measuring: { requests:number; rpcCalls:number; bytesFetched:number }|null=null;
globalThis.fetch=async(input,init)=>{
 const sample=measuring;
 if(sample){sample.requests++;try{const body=JSON.parse(String(init?.body));sample.rpcCalls+=Array.isArray(body)?body.length:1;}catch{sample.rpcCalls++;}}
 const response=await fetchOriginal(input,init);
 if(sample)sample.bytesFetched+=(await response.clone().arrayBuffer()).byteLength;
 return response;
};
const primary=createChain(url,{httpBatch:false});await primary.probeProviders();
if(await primary.getChainId()!==10143)throw Error('Wrong chain');
const blockNumber=await primary.getBlockNumber({cacheTime:0});
const multicall='0xcA11bde05977b3631167028862bE2a173976CA11' as Address;
const code=await primary.getBytecode({address:multicall,blockNumber});
if(!code||code==='0x')throw Error('No Multicall3 runtime at candidate address');
const calls=[{target:release.demo.token as Address,allowFailure:false,callData:encodeFunctionData({abi:tokenAbi,functionName:'totalSupply'})}];
const aggregate=await primary.readContract({address:multicall,abi:parseAbi(['function aggregate3((address target,bool allowFailure,bytes callData)[] calls) payable returns ((bool success,bytes returnData)[])']),functionName:'aggregate3',args:[calls],blockNumber});
const direct=await primary.call({to:release.demo.token as Address,data:calls[0].callData,blockNumber});
if(!aggregate[0]?.success||aggregate[0].returnData!==direct.data)throw Error('Multicall3 aggregate3 did not reproduce direct call');
const verification={address:multicall,chainId:10143,blockNumber:String(blockNumber),codeHash:keccak256(code),codeBytes:(code.length-2)/2,aggregate3MatchesDirect:true};
const results=[];
const quantile=(values:number[],q:number)=>[...values].sort((a,b)=>a-b)[Math.ceil(values.length*q)-1]??null;
let expected:string|undefined;
for(const mode of modes){
 const client=createChain(url,mode);await client.probeProviders();
 const samples=[];const errors:string[]=[];
 for(let i=0;i<count;i++){
  measuring={requests:0,rpcCalls:0,bytesFetched:0};const started=performance.now();
  try{
   const values=await Promise.all([
    client.readContract({address:release.demo.curve,abi:curveAbi,functionName:'getReserves',blockNumber}),
    client.readContract({address:release.demo.curve,abi:curveAbi,functionName:'realQuoteReserve',blockNumber}),
    client.readContract({address:release.demo.curve,abi:curveAbi,functionName:'sellableTokens',blockNumber}),
    client.readContract({address:release.demo.curve,abi:curveAbi,functionName:'reservedTokens',blockNumber}),
    client.readContract({address:release.demo.curve,abi:curveAbi,functionName:'feeBps',blockNumber}),
    client.readContract({address:release.demo.curve,abi:curveAbi,functionName:'creatorTaxBps',blockNumber}),
    client.readContract({address:release.demo.curve,abi:curveAbi,functionName:'readyToGraduate',blockNumber}),
    client.readContract({address:addresses.coordinator,abi:coordinatorAbi,functionName:'ledger',args:[release.demo.token],blockNumber}),
    client.readContract({address:addresses.coordinator,abi:coordinatorAbi,functionName:'receipt',args:[release.demo.token],blockNumber}),
   ]);
   const encoded=JSON.stringify(values,(_,value)=>typeof value==='bigint'?String(value):value);
   if(expected&&encoded!==expected)throw Error('Read results differ at pinned block');expected=encoded;
   samples.push({ms:Math.round((performance.now()-started)*100)/100,...measuring});
  }catch(error){errors.push(error instanceof Error?error.name:'UNKNOWN_RPC_ERROR');}
  finally{measuring=null;}
 }
 const summary={mode:mode.name,samples:samples.length,errors:errors.length,p50Ms:quantile(samples.map(s=>s.ms),.5),p95Ms:quantile(samples.map(s=>s.ms),.95),meanRequests:samples.reduce((n,s)=>n+s.requests,0)/samples.length,meanRpcCalls:samples.reduce((n,s)=>n+s.rpcCalls,0)/samples.length,meanBytesFetched:samples.reduce((n,s)=>n+s.bytesFetched,0)/samples.length};
 results.push({...summary,samplesDetail:samples,errorClasses:errors});console.log(JSON.stringify(summary));
}
const qualified=results.filter(r=>r.samples===count&&r.errors===0).sort((a,b)=>a.p95Ms!-b.p95Ms!);
const winner=qualified[0];
const evidence={measuredAt:new Date().toISOString(),providerOrigin:new URL(url).origin,samplesPerMode:count,scenario:'Nine related launch economic reads at identical pinned block, successful results compared byte-for-byte',verification,results,winner:winner?.mode??null};
const output=process.env.RPC_BENCHMARK_OUTPUT??'development/performance/RPC_BENCHMARK.json';mkdirSync(output.slice(0,output.lastIndexOf('/')),{recursive:true});writeFileSync(output,JSON.stringify(evidence,null,2)+'\n');console.log(JSON.stringify({evidence:output,winner:evidence.winner}));

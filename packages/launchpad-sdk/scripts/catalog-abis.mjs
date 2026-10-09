import {readFileSync,writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {toFunctionSelector,toEventSelector,toFunctionSignature,toEventSignature} from 'viem';
const dir=fileURLToPath(new URL('../../../deployments/monad-testnet/abi/',import.meta.url));
const manifest=JSON.parse(readFileSync(dir+'manifest.json','utf8'));
const files=[...new Set(manifest.contracts.map(c=>c.abi))].sort();
const contracts=files.map(file=>{
 const abi=JSON.parse(readFileSync(dir+file,'utf8'));
 const mappings=manifest.contracts.filter(c=>c.abi===file);
 return {abi:file,contractName:mappings[0].contractName,coverage:mappings[0].coverage,addresses:mappings.map(c=>({role:c.role,address:c.address})),
 functions:abi.filter(i=>i.type==='function').map(i=>({name:i.name,signature:toFunctionSignature(i),selector:toFunctionSelector(i),stateMutability:i.stateMutability,inputs:i.inputs,outputs:i.outputs})),
 events:abi.filter(i=>i.type==='event').map(i=>({name:i.name,signature:toEventSignature(i),topic0:i.anonymous?null:toEventSelector(i),anonymous:i.anonymous,inputs:i.inputs})),
 errors:abi.filter(i=>i.type==='error').map(i=>({name:i.name,selector:toFunctionSelector(i),inputs:i.inputs})),
 constructor:abi.find(i=>i.type==='constructor')??null,receive:abi.find(i=>i.type==='receive')??null,fallback:abi.find(i=>i.type==='fallback')??null};
});
const catalog={schemaVersion:1,chainId:10143,deployedSourceSHA:manifest.deployedSourceSHA,contracts};
writeFileSync(dir+'function-event-map.json',JSON.stringify(catalog,null,2)+'\n');
const lines=['# Deployed contract ABI map','',`Chain: **10143 (Monad Testnet)**. Deployed RetroPick source: \`${manifest.deployedSourceSHA}\`.`, '', 'Generated from ABI JSON, preserving overloads. This is an interface inventory; authorization and economic preconditions remain enforced onchain. A selector appearing here does not authorize its use or expose it as a frontend action.','', 'External Circle USDC has interface-only coverage. Kuru source/ABI provenance and external upgrade assumptions are recorded in [manifest.json](manifest.json).',''];
for(const c of contracts){
 lines.push(`## ${c.contractName}`,'',`ABI: [${c.abi}](${c.abi}) · ${c.coverage}`,'',...c.addresses.map(x=>`- ${x.role}: \`${x.address}\``),'','| Function | Selector | Mutability |','| --- | --- | --- |',...c.functions.map(f=>`| \`${f.signature}\` | \`${f.selector}\` | ${f.stateMutability} |`));
 if(c.events.length)lines.push('','| Event | Topic 0 |','| --- | --- |',...c.events.map(e=>`| \`${e.signature}\` | \`${e.topic0??'anonymous'}\` |`));
 lines.push('');
}
writeFileSync(dir+'FUNCTIONS.md',lines.join('\n'));
console.log(JSON.stringify({abiFiles:files.length,functions:contracts.reduce((n,c)=>n+c.functions.length,0),events:contracts.reduce((n,c)=>n+c.events.length,0),errors:contracts.reduce((n,c)=>n+c.errors.length,0)}));

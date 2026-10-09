import {factoryAbi,coordinatorAbi,curveAbi,tokenAbi,kuruAbi,marginAbi,kuruVaultAbi,registryAbi} from './abi.ts';
// Derived from complete compiler ABIs; no handwritten event signatures.
const seen=new Set<string>();
export const indexerAbi=[...factoryAbi,...coordinatorAbi,...curveAbi,...tokenAbi,...kuruAbi,...marginAbi,...kuruVaultAbi,...registryAbi].filter(e=>e.type==='event').filter(e=>{const key=JSON.stringify(e);if(seen.has(key))return false;seen.add(key);return true;});
export const jsonExact=(value:unknown)=>JSON.stringify(value,(_,v)=>typeof v==='bigint'?v.toString():v);

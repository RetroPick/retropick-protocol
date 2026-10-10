import { factoryAbi } from './abis/factoryAbi.ts';
import { coordinatorAbi } from './abis/coordinatorAbi.ts';
import { curveAbi } from './abis/curveAbi.ts';
import { tokenAbi } from './abis/tokenAbi.ts';
import { kuruAbi } from './abis/kuruAbi.ts';
import { marginAbi } from './abis/marginAbi.ts';
import { kuruVaultAbi } from './abis/kuruVaultAbi.ts';
import { registryAbi } from './abis/registryAbi.ts';
// Derived from complete compiler ABIs; no handwritten event signatures.
const seen=new Set<string>();
export const indexerAbi=[...factoryAbi,...coordinatorAbi,...curveAbi,...tokenAbi,...kuruAbi,...marginAbi,...kuruVaultAbi,...registryAbi].filter(e=>e.type==='event').filter(e=>{const key=JSON.stringify(e);if(seen.has(key))return false;seen.add(key);return true;});
export const jsonExact=(value:unknown)=>JSON.stringify(value,(_,v)=>typeof v==='bigint'?v.toString():v);

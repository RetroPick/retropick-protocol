import {createServer} from 'node:http';
import {mkdirSync} from 'node:fs';
import {dirname,resolve} from 'node:path';
import {jsonExact} from '@retropick/launchpad-sdk/events';
import type {IndexedLaunch,IndexedTrade} from '@retropick/launchpad-sdk/read-model';
import {Store} from './store.ts';
import {Indexer} from './sync.ts';
const url=process.env.MONAD_TESTNET_RPC_URL;
if(!url)throw Error('MONAD_TESTNET_RPC_URL is required');
const file=resolve(process.env.INDEXER_DB??'.data/monad-testnet.sqlite');
mkdirSync(dirname(file),{recursive:true});
const store=new Store(file);const indexer=new Indexer(store,url);
type Snapshot={launches:IndexedLaunch[];trades:IndexedTrade[];holders:Record<string,{address:string;balanceRaw:string}[]>};
const server=createServer((req,res)=>{
 res.setHeader('Content-Type','application/json');res.setHeader('Cache-Control','no-store');
 // Read-only GET API: allow browser consumers (the retro-ui dev server and
 // any future read client). No credentials are ever accepted or exposed.
 res.setHeader('Access-Control-Allow-Origin','*');res.setHeader('Access-Control-Allow-Methods','GET, OPTIONS');
 if(req.method==='OPTIONS'){res.statusCode=204;res.end();return;}
 const send=(status:number,data:unknown)=>{res.statusCode=status;res.end(jsonExact(data));};
 if(req.method!=='GET'){send(405,{error:'READ_ONLY_API'});return;}
 const path=new URL(req.url??'/', 'http://localhost').pathname;
 const freshness=indexer.freshness();
 if(path==='/health'){send(200,{freshness,ready:!!store.get('snapshot')});return;}
 const snapshot=store.get<Snapshot>('snapshot');
 if(!snapshot){send(503,{error:'INDEX_NOT_READY',freshness});return;}
 if(path==='/v1/launches'){send(200,{data:snapshot.launches,freshness});return;}
 const match=/^\/v1\/launches\/(0x[\da-fA-F]{40})(?:\/(trades|holders|candles))?$/.exec(path);
 if(!match){send(404,{error:'NOT_FOUND',freshness});return;}
 const token=match[1].toLowerCase();const launch=snapshot.launches.find(l=>l.token.toLowerCase()===token);
 if(!launch){send(404,{error:'LAUNCH_NOT_FOUND',freshness});return;}
 const data=match[2]==='trades'?snapshot.trades.filter(t=>t.token===token):match[2]==='holders'?snapshot.holders[token]??[]:match[2]==='candles'?launch.candles:launch;
 send(200,{data,freshness});
});
const port=Number(process.env.INDEXER_PORT??8787);
server.listen(port,'127.0.0.1',()=>console.log('Testnet read-only indexer listening on',port));
void indexer.sync();
const timer=setInterval(()=>void indexer.sync(),15000);
const stop=()=>{clearInterval(timer);server.close(()=>{store.close();process.exit(0);});};
process.on('SIGINT',stop);process.on('SIGTERM',stop);

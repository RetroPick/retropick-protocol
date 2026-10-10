import {mkdirSync} from 'node:fs';
import {dirname,resolve} from 'node:path';
import {Store} from './store.ts';
import {Indexer} from './sync.ts';
const url=process.env.MONAD_TESTNET_RPC_URL;
if(!url)throw Error('MONAD_TESTNET_RPC_URL is required; sync cannot silently skip');
const fallbackUrl=process.env.MONAD_TESTNET_RPC_FALLBACK_URL;
const file=resolve(process.env.INDEXER_DB??'.data/monad-testnet.sqlite');
mkdirSync(dirname(file),{recursive:true});
const store=new Store(file);
try {const indexer=new Indexer(store,fallbackUrl?[url,fallbackUrl]:url);await indexer.sync();if(indexer.error)process.exitCode=1;console.log(JSON.stringify(indexer.freshness()));}finally{store.close();}

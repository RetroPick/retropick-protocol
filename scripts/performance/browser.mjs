// Read-only production-preview benchmark. No wallet connections or transactions.
import {createRequire} from 'node:module';
import {mkdir,writeFile} from 'node:fs/promises';
const require=createRequire(new URL('../../apps/retro-ui/package.json',import.meta.url));
const {chromium}=require('@playwright/test');
const base=process.env.APP_URL??'http://127.0.0.1:4180';
const indexer=process.env.INDEXER_URL??'http://127.0.0.1:8787';
const samples=Number(process.env.SAMPLES??30);
const directory=process.env.REPORT_DIR??'evidence/launchpad/productization/performance/baseline';
const envelope=await fetch(`${indexer}/v1/launches?limit=100`).then(r=>r.json());
const launches=Array.isArray(envelope.data)?envelope.data:[];
const active=launches.find(l=>l.phase==='ACTIVE');
const graduated=launches.find(l=>l.phase==='GRADUATED');
const cases=[{name:'discovery',path:'/launchpad',content:'.market-table tbody tr',ticket:null},...[
 ['active',active],['graduated',graduated],
].filter(([,l])=>l).map(([name,l])=>({name:`detail-${name}`,path:`/launchpad/token/${l.token}`,content:'.token-detail-heading h1',ticket:'.token-trade-ticket'}))];
const browser=await chromium.launch({headless:true});
const results=[];
try {
 for(const scenario of cases) {
  const warmContext=await browser.newContext();
  for(const temperature of ['cold','warm']) for(let i=0;i<samples;i++) {
   const context=temperature==='cold'?await browser.newContext():warmContext;
   const page=await context.newPage();
   let rpcRequests=0,rpcCalls=0,indexerRequests=0,bytes=0,indexerMs=null;
   const byteReads=[];
   let started=performance.now();
   page.on('request',r=>{
    if(r.method()==='POST'&&!r.url().includes('/wallet')) {
     try{const d=JSON.parse(r.postData()??'null');const calls=Array.isArray(d)?d:[d];if(calls.some(c=>c?.jsonrpc)){rpcRequests++;rpcCalls+=calls.length;}}catch{}
    }
    if(r.url().startsWith(indexer)&&!r.url().endsWith('/health'))indexerRequests++;
   });
   page.on('response',r=>{
    if(r.url().startsWith(indexer)&&indexerMs===null)indexerMs=performance.now()-started;
    byteReads.push(r.body().then(b=>{bytes+=b.length;}).catch(()=>{}));
   });
   const errors=[];
   page.on('pageerror',e=>errors.push(e.message));
   started=performance.now();
   let contentMs=null,ticketMs=null,error=null;
   try {
    await page.goto(`${base}${scenario.path}`,{waitUntil:'domcontentloaded',timeout:20000});
    await page.locator(scenario.content).first().waitFor({timeout:15000});
    contentMs=performance.now()-started;
    if(scenario.ticket){await page.locator(scenario.ticket).first().waitFor({timeout:15000});ticketMs=performance.now()-started;}
   }catch(e){error=e.message.split('\n')[0];}
   const paint=await page.evaluate(()=>performance.getEntriesByType('paint').map(p=>({name:p.name,ms:p.startTime}))).catch(()=>[]);
   await Promise.allSettled(byteReads);
   results.push({scenario:scenario.name,temperature,sample:i+1,contentMs,ticketMs,indexerMs,rpcRequests,rpcCalls,indexerRequests,bytes,paint,error,errors});
   await page.close();
   if(temperature==='cold')await context.close();
   if((i+1)%10===0)console.log(`${scenario.name} ${temperature} ${i+1}/${samples}`);
  }
  await warmContext.close();
 }
}finally{await browser.close();}
const percentile=(values,p)=>{const sorted=values.filter(v=>v!==null).sort((a,b)=>a-b);return sorted.length?sorted[Math.max(0,Math.ceil(sorted.length*p)-1)]:null;};
const summary=cases.flatMap(c=>['cold','warm'].map(temperature=>{
 const rows=results.filter(r=>r.scenario===c.name&&r.temperature===temperature);
 return {scenario:c.name,temperature,samples:rows.length,failures:rows.filter(r=>r.error).length,...Object.fromEntries(['contentMs','ticketMs','indexerMs','rpcRequests','rpcCalls','bytes'].map(k=>[k,{p50:percentile(rows.map(r=>r[k]),.5),p95:percentile(rows.map(r=>r[k]),.95)}]))};
}));
await mkdir(directory,{recursive:true});
await writeFile(`${directory}/browser.json`,JSON.stringify({base,samples,indexerFreshness:envelope.freshness,method:'Production preview, sequential samples, fresh contexts for cold and shared HTTP cache for warm. Each navigation creates a document; SPA cache is qualified separately.',summary,results},null,2));
console.log(JSON.stringify(summary,null,2));

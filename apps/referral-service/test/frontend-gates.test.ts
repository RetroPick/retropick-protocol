import test from 'node:test';
import assert from 'node:assert/strict';
import { captureReferral, clearPendingReferral, pendingReferral, referralLink } from '../../retro-ui/src/lib/live/referral-client.ts';
import { fiatProviders, MONAD_TESTNET_FAUCET } from '../../retro-ui/src/lib/live/fiat-provider.ts';

test('local referral capture is first touch, expires at 30 days and rejects malformed wallets',()=>{
  const values=new Map<string,string>();const existing=Object.getOwnPropertyDescriptor(globalThis,'localStorage');
  Object.defineProperty(globalThis,'localStorage',{configurable:true,value:{getItem:(key:string)=>values.get(key)??null,setItem:(key:string,value:string)=>values.set(key,value),removeItem:(key:string)=>values.delete(key)}});
  const first='0x'+'1'.repeat(40);const second='0x'+'2'.repeat(40);
  try {
    assert.equal(captureReferral('arbitrary-code'),false);assert.equal(captureReferral('0x'+'0'.repeat(40)),false);
    assert.equal(captureReferral(first),true);assert.equal(captureReferral(second),true);assert.equal(pendingReferral()?.referrer,first);
    assert.equal(pendingReferral()!.expiresAt-pendingReferral()!.firstSeenAt,30*24*60*60*1000);
    const key=[...values.keys()][0];const stale=JSON.parse(values.get(key)!) as {firstSeenAt:number;expiresAt:number};stale.firstSeenAt-=31*24*60*60*1000;stale.expiresAt-=31*24*60*60*1000;values.set(key,JSON.stringify({...stale,referrer:first}));
    assert.equal(pendingReferral(),null);assert.equal(captureReferral(second),true);assert.equal(pendingReferral()?.referrer,second);
    clearPendingReferral();assert.equal(pendingReferral(),null);
    assert.equal(referralLink(first,'https://retro.example'),`https://retro.example/r/${first}`);
  }finally{if(existing)Object.defineProperty(globalThis,'localStorage',existing);else Reflect.deleteProperty(globalThis,'localStorage');}
});

test('every fiat adapter fails closed for Monad Testnet MON and USDC and unqualified networks',async()=>{
  assert.equal(fiatProviders.length,4);
  for(const provider of fiatProviders)for(const request of [{chainId:10143,asset:{symbol:'MON'}},{chainId:10143,asset:{symbol:'USDC',tokenAddress:'0x'+'3'.repeat(40)}},{chainId:143,asset:{symbol:'MON'}}]){
    const capability=await provider.capabilities(request);assert.equal(capability.buy,false);assert.equal(capability.sell,false);assert.match(capability.documentationUrl,/^https:/);
    await assert.rejects(provider.buy(request));await assert.rejects(provider.sell(request));
  }
  assert.equal(MONAD_TESTNET_FAUCET,'https://faucet.monad.xyz');
});

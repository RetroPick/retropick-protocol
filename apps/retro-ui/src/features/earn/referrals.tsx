'use client';

import { useEffect, useRef, useState } from 'react';
import { formatUnits } from 'viem';
import { useWallet } from '@/wallet/provider';
import { shortAddress } from '@/lib/live/format';
import { getReferralSummary, logoutReferralSession, pendingReferral, referralLink, verifyReferralAssociation, type ReferralSummary } from '@/lib/live/referral-client';

export function ReferralCard({quoteAssets=[]}:{quoteAssets?:{address:string;symbol:string;decimals:number}[]}) {
  const wallet=useWallet();const [summary,setSummary]=useState<ReferralSummary|null>(null);const [error,setError]=useState('');const [busy,setBusy]=useState(false);const [copied,setCopied]=useState(false);
  const current=useRef({account:wallet.account,chainId:wallet.chainId});current.current={account:wallet.account,chainId:wallet.chainId};
  const previous=useRef(wallet.account);
  const account=wallet.account;const link=account?referralLink(account):null;
  const pending=pendingReferral();
  const needsAssociation=!!pending&&pending.referrer!==account?.toLowerCase()&&!summary?.referredBy;
  useEffect(()=>{
    const controller=new AbortController();setSummary(null);setError('');
    const changed=previous.current!==account;previous.current=account;
    const sessionCleanup=changed?logoutReferralSession().catch(()=>undefined):Promise.resolve();
    const load=async()=>{
      await sessionCleanup;
      if(!account)return;
      try {
        const result=await getReferralSummary(controller.signal);
        if(result?.wallet.toLowerCase()===account.toLowerCase() && current.current.account===account)setSummary(result);
        else if(result)await logoutReferralSession();
      }catch(cause){if(!controller.signal.aborted)setError(cause instanceof Error?cause.message:'Referral service unavailable.');}
    };
    void load();
    const timer=setInterval(()=>{if(document.visibilityState==='visible')void load();},15000);
    return()=>{controller.abort();clearInterval(timer);};
  },[account]);

  const verify=async()=>{
    if(!wallet.wallet||!account||wallet.chainId!==10143)return;
    setBusy(true);setError('');
    try {
      await verifyReferralAssociation(wallet.wallet,account,pending,()=>current.current.account===account&&current.current.chainId===10143);
      const next=await getReferralSummary();if(current.current.account===account)setSummary(next);
    }catch(cause){setError(cause instanceof Error?cause.message:'Referral verification failed.');}
    finally{setBusy(false);}
  };
  return <section className="earn-panel panel" id="referrals" aria-label="Wallet referral attribution">
    <div className="earn-panel-head"><h2>Referrals</h2><span className="tag">Attribution</span></div>
    <p className="earn-empty">Share your link to track confirmed launches and trades. Referral earnings are not enabled.</p>
    {!account?<p>Connect your wallet to get your referral link.</p>:<>
      <label className="field-label" htmlFor="referral-link">Your referral link</label>
      <input id="referral-link" className="input" value={link!} readOnly aria-label="Your referral link" />
      <div className="earn-actions"><button className="btn" onClick={()=>{if(!navigator.clipboard?.writeText){setError('Copy is unavailable. Select and copy your link.');return;}void navigator.clipboard.writeText(link!).then(()=>setCopied(true),()=>setError('Copy is unavailable. Select and copy your link.'));}}>{copied?'Link copied':'Copy referral link'}</button></div>
      {pending?.referrer===account.toLowerCase()?<p className="earn-note">Your own link cannot refer your wallet.</p>:pending&&!summary?.referredBy?<p className="earn-note">Pending referral: {shortAddress(pending.referrer)}. Sign to associate it with this wallet.</p>:null}
      {(!summary||needsAssociation)&&<button className="btn primary" disabled={busy||wallet.chainId!==10143} onClick={()=>void verify()}>{busy?'Waiting for signature…':needsAssociation?'Associate referral with wallet':'Verify wallet to view attribution'}</button>}
      {summary&&<>
        <div className="earn-row"><span>Associated wallets</span><strong>{summary.referredWallets}</strong></div>
        <div className="earn-row"><span>Qualified wallets</span><strong>{summary.qualifiedWallets}</strong></div>
        <div className="earn-row"><span>Confirmed launches</span><strong>{summary.createdLaunches}</strong></div>
        {summary.referredBy&&<p className="earn-note">Referred by {shortAddress(summary.referredBy)}</p>}
        {summary.volumeByQuote.map(row=>{const quote=quoteAssets.find(q=>q.address.toLowerCase()===row.quote);return <div className="earn-row" key={row.quote}><span>Attributed volume · {quote?.symbol??shortAddress(row.quote)}</span><strong>{quote?formatUnits(BigInt(row.volumeRaw),quote.decimals):`${row.volumeRaw} base units`}</strong></div>;})}
        {!!summary.referrals.length&&<table className="data-table"><thead><tr><th>Wallet</th><th>Status</th><th>Qualifying action</th></tr></thead><tbody>{summary.referrals.map(r=><tr key={r.wallet}><td><a href={`https://testnet.monadexplorer.com/address/${r.wallet}`} target="_blank" rel="noopener noreferrer">{shortAddress(r.wallet)}</a></td><td>{r.status==='QUALIFIED'?'Confirmed':'Awaiting confirmed activity'}</td><td>{r.qualifyingTxHash?<a href={`https://testnet.monadexplorer.com/tx/${r.qualifyingTxHash}`} target="_blank" rel="noopener noreferrer">{r.qualifyingAction}</a>:'—'}</td></tr>)}</tbody></table>}
        <p className="earn-note">{summary.freshness?`Indexed through block ${summary.freshness.indexedBlock}; ${summary.freshness.lagBlocks} blocks behind head.`:'Awaiting confirmed activity from the indexer.'}{summary.syncError?' Attribution is syncing; these are the last confirmed results.':''}</p>
        <button className="btn ghost" onClick={()=>{void logoutReferralSession().then(()=>setSummary(null),()=>setError('Session logout failed.'));}}>End attribution session</button>
      </>}
    </>}
    {error&&<p className="form-error" role="alert">{error}</p>}
    <p className="earn-note">Signatures prove wallet ownership only. They do not authorize a trade or transfer. Test MON has no displayed USD valuation.</p>
  </section>;
}

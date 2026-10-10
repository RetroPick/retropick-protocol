'use client';
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { formatUnits, zeroAddress, type Address } from 'viem';
import { publicClient } from '@/lib/live/public-client';
import { launchKeys } from '@/lib/live/queries';
import { useWallet } from '@/wallet/provider';
import { executePreparedWrite, type TxPhase } from '@/services/tx-pipeline';
import { fetchWalletState } from '@/services/wallet-state';
import { prepareFeeClaim, prepareFeeClaimToken, prepareBuybackRelease } from '@retropick/launchpad-sdk/prepare';
import { explorer } from '@retropick/launchpad-sdk/chain';
import { markStage, measureStage } from '@/lib/live/performance';
import { toast } from 'sonner';
export function LiveEarn() {
 const wallet=useWallet(),account=wallet.account;
 const state=useQuery({queryKey:launchKeys.wallet(account??'disconnected','state'),enabled:!!account,queryFn:({signal})=>fetchWalletState(account!,signal),refetchInterval:10_000,structuralSharing:false});
 const [tx,setTx]=useState<TxPhase|{kind:'idle'}>({kind:'idle'}),[error,setError]=useState('');
 const busy=!['idle','failed','success'].includes(tx.kind), data=state.data;
 const run=async(prepare:()=>Promise<Parameters<typeof executePreparedWrite>[2]>)=>{
  if(!wallet.wallet||!account)return;setError('');setTx({kind:'preparing'});markStage('transaction.click');const preflight=measureStage('transaction.preflight');
  try{const prepared=await prepare();preflight();const result=await executePreparedWrite(publicClient,wallet.wallet,prepared,{onPhase:setTx});if(result.kind==='failed')setError(result.reason);else{toast.success(`${prepared.label} confirmed`,{description:result.hash});void state.refetch();}}catch(cause){setError(cause instanceof Error?cause.message:'Claim failed.');}finally{setTx({kind:'idle'});}
 };
 if(!account)return <section className="earn-panel panel"><h2>Available to claim</h2><p>Connect your wallet to view real creator credits and buyback releases.</p></section>;
 const credits=data?.assets.filter(row=>row.creditRaw>0n)??[];
 return <section className="earn-panel panel" aria-label="Live earnings"><h2>Available to claim</h2>
 {state.isPending?<p role="status">Reading wallet credits…</p>:state.isError?<p role="alert">Wallet credits are temporarily unavailable.</p>:<>
 <div className="earn-amount-row"><strong>{data?formatUnits(data.nativeCreditRaw,18):'—'} MON</strong><span>Creator fee credit</span></div>
 <button className="btn primary" disabled={busy||!wallet.wallet||!data?.nativeCreditRaw} onClick={()=>void run(()=>prepareFeeClaim(publicClient,account))}>Claim MON fees</button>
 <div className="earn-row-group">{credits.map(row=><div className="earn-row" key={row.token}><span>{row.decimals===null?`${row.creditRaw} atomic units`:formatUnits(row.creditRaw,row.decimals)} {row.symbol} available</span><button className="btn ghost" disabled={busy||!wallet.wallet} onClick={()=>void run(()=>prepareFeeClaimToken(publicClient,account,row.token as Address))}>Claim {row.symbol}</button></div>)}{!credits.length&&<p>No ERC20 fee credits available.</p>}</div>
 <h3>Buyback / vested release</h3>{data?.buybacks.length?data.buybacks.map(row=><div className="earn-row" key={row.token}><span>{row.symbol} · your currently releasable share {formatUnits(row.beneficiaryRaw,row.decimals)}</span><button className="btn ghost" disabled={busy||!wallet.wallet||row.releasableRaw===0n} onClick={()=>void run(()=>prepareBuybackRelease(publicClient,row.token as Address,account))}>Release</button></div>):<p>No indexed vesting positions for your wallet.</p>}
 <p className="ticket-note">Release credits the fee escrow. Claim that token separately to receive it in your wallet.</p>
 <h3>Claim history</h3>{data?.claims.length?<table className="detail-trades"><thead><tr><th>Asset</th><th>Amount</th><th>Time</th><th>Transaction</th></tr></thead><tbody>{data.claims.slice(0,100).map(row=>{const asset=data.assets.find(a=>a.token.toLowerCase()===row.token.toLowerCase());const native=row.token===zeroAddress;return <tr key={row.id}><td>{native?'MON':asset?.symbol??row.token}</td><td>{native?formatUnits(BigInt(row.amountRaw),18):asset?.decimals!==null&&asset?.decimals!==undefined?formatUnits(BigInt(row.amountRaw),asset.decimals):`${row.amountRaw} atomic units`}</td><td>{new Date(row.timestamp*1000).toLocaleString()}</td><td><a href={explorer(row.transactionHash,'tx')} target="_blank" rel="noreferrer">View transaction</a></td></tr>;})}</tbody></table>:<p>No indexed claims yet.</p>}
 {data?.issues.map(issue=><p role="status" key={issue}>{issue}.</p>)}
 </>}
 {busy&&<p role="status" data-tx-phase={tx.kind}>{tx.kind==='awaiting-signature'?'Confirm in wallet…':`${tx.kind}…`}</p>}{error&&<p role="alert" className="form-error">{error}</p>}
 <p className="earn-empty">Balances stay grouped by asset. Testnet MON has no assumed USD value.</p></section>;
}

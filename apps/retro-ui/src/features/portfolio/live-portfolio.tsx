'use client';
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { formatUnits, type Address } from 'viem';
import { useWallet } from '@/wallet/provider';
import { publicClient } from '@/lib/live/public-client';
import { launchKeys } from '@/lib/live/queries';
import { fetchWalletState } from '@/services/wallet-state';
import { executePreparedWrite, type TxPhase } from '@/services/tx-pipeline';
import { prepareKuruCancel, prepareMarginWithdraw } from '@retropick/launchpad-sdk/prepare';
import { zeroAddress } from 'viem';
import Link from '@/components/product/safe-link';
export function LivePortfolio() {
 const wallet=useWallet(),account=wallet.account;
 const state=useQuery({queryKey:launchKeys.wallet(account??'disconnected','state'),enabled:!!account,queryFn:({signal})=>fetchWalletState(account!,signal),refetchInterval:10_000,structuralSharing:false});
 const [tx,setTx]=useState<TxPhase|{kind:'idle'}>({kind:'idle'}),[error,setError]=useState('');
 const busy=!['idle','failed','success'].includes(tx.kind),data=state.data;
 const run=async(prepare:()=>Promise<Parameters<typeof executePreparedWrite>[2]>)=>{if(!wallet.wallet)return;setError('');setTx({kind:'preparing'});try{const result=await executePreparedWrite(publicClient,wallet.wallet,await prepare(),{onPhase:setTx});if(result.kind==='failed')setError(result.reason);else void state.refetch();}catch(e){setError(e instanceof Error?e.message:'Action failed.');}finally{setTx({kind:'idle'});}};
 if(!account)return <section className="panel"><h2>Portfolio</h2><p>Connect your wallet to view assets, Kuru margin balances and orders.</p></section>;
 if(state.isPending)return <section className="panel"><h2>Portfolio</h2><p role="status">Reading current wallet balances…</p></section>;
 if(state.isError)return <section className="panel"><h2>Portfolio</h2><p role="alert">Balances are temporarily unavailable.</p><button className="btn" onClick={()=>void state.refetch()}>Retry</button></section>;
 const assets=data?.assets.filter(row=>row.walletRaw>0n||row.marginRaw>0n)??[],orders=data?.orders.filter(o=>o.status==='OPEN'||o.status==='PARTIALLY_FILLED')??[];
 return <section className="panel" aria-label="Live portfolio"><h2>Portfolio</h2><div className="quote-lines"><div><span>MON in wallet</span><strong>{data?formatUnits(data.monRaw,18):'—'}</strong></div><div><span>MON in Kuru margin</span><strong>{data?formatUnits(data.nativeMarginRaw,18):'—'}</strong><button className="btn ghost" disabled={busy||!wallet.wallet||!data?.nativeMarginRaw} onClick={()=>void run(()=>prepareMarginWithdraw(publicClient,account,{token:zeroAddress,amount:data!.nativeMarginRaw}))}>Withdraw</button></div></div>
 <table className="detail-trades"><thead><tr><th>Asset</th><th>Wallet</th><th>Kuru margin</th><th>Action</th></tr></thead><tbody>{assets.map(row=><tr key={row.token}><td><Link href={`/launchpad/token/${row.token}`}>{row.symbol}</Link></td><td>{row.decimals===null?`${row.walletRaw} atomic units`:formatUnits(row.walletRaw,row.decimals)}</td><td>{row.decimals===null?`${row.marginRaw} atomic units`:formatUnits(row.marginRaw,row.decimals)}</td><td><button className="btn ghost" disabled={busy||!wallet.wallet||!row.marginRaw} onClick={()=>void run(()=>prepareMarginWithdraw(publicClient,account,{token:row.token as Address,amount:row.marginRaw}))}>Withdraw</button></td></tr>)}</tbody></table>{!assets.length&&<p>No indexed token balances in your wallet or margin.</p>}
 <h3>Open Kuru orders</h3>{orders.length?<table className="detail-trades"><thead><tr><th>Side</th><th>Price</th><th>Initial resting size</th><th>Remaining</th><th>Created</th><th>Status</th><th>Action</th></tr></thead><tbody>{orders.map(o=><tr key={`${o.market}:${o.orderId}`}><td>{o.side}</td><td>{formatUnits(BigInt(o.priceX18),18)}</td><td>{formatUnits(BigInt(o.originalSizeUnits)*10n**BigInt(o.baseDecimals)/BigInt(o.sizePrecision),o.baseDecimals)}</td><td>{formatUnits(BigInt(o.remainingSizeUnits)*10n**BigInt(o.baseDecimals)/BigInt(o.sizePrecision),o.baseDecimals)}</td><td>{new Date(o.createdAt*1000).toLocaleString()}</td><td>{o.status.replaceAll('_',' ')}</td><td><button className="btn ghost" disabled={busy||!wallet.wallet} onClick={()=>void run(()=>prepareKuruCancel(publicClient,o.market as Address,account,[Number(o.orderId)]))}>Cancel</button></td></tr>)}</tbody></table>:<p>No indexed open orders.</p>}
 {data?.issues.map(issue=><p role="status" key={issue}>{issue}.</p>)}{error&&<p role="alert" className="form-error">{error}</p>}{busy&&<p role="status" data-tx-phase={tx.kind}>Working…</p>}
 <p className="ticket-note">Wallet balances and free margin balances are read from chain. Open order history is indexed; cancellation validates current on-chain ownership.</p></section>;
}

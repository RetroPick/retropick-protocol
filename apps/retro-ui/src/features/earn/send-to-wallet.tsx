'use client';
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { formatUnits, isAddress, zeroAddress, type Address } from 'viem';
import { parseExact } from '@retropick/launchpad-sdk/math';
import { prepareTransfer } from '@retropick/launchpad-sdk/transfer';
import { launchKeys } from '@/lib/live/queries';
import { publicClient } from '@/lib/live/public-client';
import { useWallet } from '@/wallet/provider';
import { fetchWalletState } from '@/services/wallet-state';
import { executePreparedWrite, type TxPhase } from '@/services/tx-pipeline';
import { toast } from 'sonner';
export function SendToWallet() {
 const wallet=useWallet(),account=wallet.account;
 const state=useQuery({queryKey:launchKeys.wallet(account??'disconnected','state'),enabled:!!account,queryFn:({signal})=>fetchWalletState(account!,signal),structuralSharing:false});
 const [asset,setAsset]=useState<string>(zeroAddress),[recipient,setRecipient]=useState(''),[amount,setAmount]=useState(''),[error,setError]=useState('');
 const [tx,setTx]=useState<TxPhase|{kind:'idle'}>({kind:'idle'}),[reviewed,setReviewed]=useState(false);
 const busy=!['idle','failed','success'].includes(tx.kind);
 const options=[{token:zeroAddress,symbol:'MON',decimals:18,walletRaw:state.data?.monRaw??0n},...(state.data?.assets.filter(a=>a.decimals!==null&&a.walletRaw>0n)??[])];
 const selected=options.find(a=>a.token===asset)??options[0];
 const valid=isAddress(recipient)&&recipient!==zeroAddress&&!!amount;
 const reset=()=>setReviewed(false);
 const send=async()=>{if(!wallet.wallet||!account||!valid||selected.decimals===null)return;setError('');setTx({kind:'preparing'});try{const prepared=await prepareTransfer(publicClient,account,{recipient:recipient as Address,asset:selected.token as Address,amount:parseExact(amount,selected.decimals)});const result=await executePreparedWrite(publicClient,wallet.wallet,prepared,{onPhase:setTx});if(result.kind==='failed')setError(result.reason);else{toast.success('Wallet transfer confirmed',{description:result.hash});setAmount('');setReviewed(false);void state.refetch();}}catch(e){setError(e instanceof Error?e.message:'Transfer failed.');}finally{setTx({kind:'idle'});}};
 return <section className="earn-panel panel" aria-label="Send to wallet"><h2>Send to wallet</h2><p>Network: Monad Testnet (10143)</p><p>Verify that the recipient supports this asset on Monad Testnet before sending. Exchange deposit support depends on the selected asset and network.</p>
 <label className="field"><span>Asset</span><select value={selected.token} onChange={e=>{setAsset(e.target.value);reset();}}>{options.map(a=><option key={a.token} value={a.token}>{a.symbol}</option>)}</select><small>Wallet balance {selected.decimals!==null?formatUnits(selected.walletRaw,selected.decimals):'unavailable'} {selected.symbol}</small></label>
 <label className="field"><span>Recipient EVM address</span><input value={recipient} onChange={e=>{setRecipient(e.target.value.trim());reset();}} placeholder="0x…"/></label><label className="field"><span>Amount · {selected.symbol}</span><input inputMode="decimal" value={amount} onChange={e=>{setAmount(e.target.value);reset();}} placeholder="0"/></label>
 {reviewed&&<div className="notice">Send {amount} {selected.symbol} to {recipient} on Monad Testnet. Network gas is paid in MON.</div>}{error&&<p role="alert" className="form-error">{error}</p>}{busy&&<p role="status" data-tx-phase={tx.kind}>{tx.kind==='awaiting-signature'?'Confirm in wallet…':`${tx.kind}…`}</p>}
 <button className="btn primary" disabled={busy||!wallet.wallet||!valid||state.isPending} onClick={()=>reviewed?void send():setReviewed(true)}>{busy?'Working…':reviewed?'Send to wallet':'Review transfer'}</button></section>;
}

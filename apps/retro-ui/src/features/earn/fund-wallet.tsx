'use client';

import { useEffect, useState, type ReactNode } from 'react';
import { fiatProviders, MONAD_TESTNET_FAUCET, type FiatCapability } from '@/lib/live/fiat-provider';

export function FundWallet({children}:{children?:ReactNode}) {
  const [capabilities,setCapabilities]=useState<FiatCapability[]>([]);
  useEffect(()=>{void Promise.all(fiatProviders.map(p=>p.capabilities({chainId:10143,asset:{symbol:'MON'}}))).then(setCapabilities);},[]);
  return <section className="earn-panel panel" aria-label="Fund wallet and transfer">
    <div className="earn-panel-head"><h2>Fund wallet</h2><span className="tag">Monad Testnet · 10143</span></div>
    <p className="earn-empty">Get test MON from the official faucet. Fiat purchases and bank/card cash-out are unavailable on this test network.</p>
    <a className="btn" href={MONAD_TESTNET_FAUCET} target="_blank" rel="noopener noreferrer">Get test MON</a>
    <div className="cashout-grid">{capabilities.map(c=><div className="cashout-card" key={c.provider}>
      <span className="cashout-kind">{c.provider}</span><p>{c.reason}</p>
      <button className="btn" disabled title={c.reason}>Buy / cash out unavailable</button>
      <a href={c.documentationUrl} target="_blank" rel="noopener noreferrer">Provider support</a>
    </div>)}</div>
    <p className="earn-note">Claims settle to your wallet first. A separate supported off-ramp would be required for a bank payout.</p>
    {children}
  </section>;
}

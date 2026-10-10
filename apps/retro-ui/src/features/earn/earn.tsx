'use client';

import { useState } from 'react';
import { toast } from 'sonner';
import { Banknote, Check, Copy, Rocket, Share2, Wallet } from 'lucide-react';
import { Segments } from '@/components/product/ui';
import { money } from '@/lib/domain/fixtures';
import Portfolio from '@/features/portfolio/portfolio';
import { LiveEarn } from '@/features/earn/live-earn';
import { DATA_MODE } from '@/lib/live/env';

// Local demo snapshot. No claim, revenue or cash-out surface is connected —
// every value is presentation-only and nothing here moves funds.
const EARN = {
  creatorFees: 0,
  referralEarnings: 0,
  deployerRevenue: 0,
  claimedAllTime: 0,
  solAvailable: '0 SOL',
  address: '3hKz...6nPw',
};
const DEMO_REFERRAL = 'https://demo.retropick.xyz/r/3hKz6nPw';

function copyText(value: string, message: string) {
  const done = () => toast.success(message);
  if (navigator.clipboard?.writeText) {
    navigator.clipboard.writeText(value).then(done, () => toast.error('Copy is unavailable in this browser.'));
  } else {
    toast.error('Copy is unavailable in this browser.');
  }
}

function AddrChip({ address }: { address: string }) {
  return <button className="addr-chip" onClick={() => copyText(address, 'Address copied')} aria-label={`Copy address ${address}`}>
    <span>{address}</span>
    <Copy size={12}/>
  </button>;
}

function ClaimAllButton({ compact = false }: { compact?: boolean }) {
  return <button className={`btn${compact ? '' : ' primary'}`} onClick={() => toast.info('Demo only — no live earnings are connected to this interface.')}>Claim all</button>;
}

function CreatorFeesPanel() {
  return <section className="earn-panel panel" id="creator-fees" aria-label="Creator fees">
    <div className="earn-panel-head"><h2>Creator fees</h2><AddrChip address={EARN.address}/></div>
    <div className="earn-amount-row"><strong>{money(EARN.creatorFees)}</strong><span>Available to claim</span><span className="earn-sol">{EARN.solAvailable}</span></div>
    <p className="earn-empty">Nothing to claim right now — fees show up here as your coins trade.</p>
    <div className="earn-row"><span>Claimed all-time</span><strong>{money(EARN.claimedAllTime)}</strong></div>
    <div className="earn-actions"><ClaimAllButton/></div>
  </section>;
}

function ReferralPanel() {
  const [activated, setActivated] = useState(false);
  const activate = () => {
    setActivated(true);
    copyText(DEMO_REFERRAL, 'Demo referral link copied');
  };
  return <section className="earn-panel panel" id="referrals" aria-label="Referral earnings">
    <div className="earn-panel-head"><h2>Referral earnings</h2><Share2 size={17} className="earn-glyph"/></div>
    <p className="earn-empty">Earn 50% of protocol fees when someone launches a coin with your link.</p>
    <div className="earn-actions">
      {activated
        ? <button className="btn" onClick={() => copyText(DEMO_REFERRAL, 'Demo referral link copied')}><Check size={15}/> Copy referral link</button>
        : <button className="btn primary" onClick={activate}>Activate referral link</button>}
    </div>
  </section>;
}

function DeployerPanel() {
  return <section className="earn-panel panel" id="deployers" aria-label="Deployer earnings">
    <div className="earn-panel-head"><h2>Deployer earnings</h2><AddrChip address={EARN.address}/></div>
    <div className="earn-amount-row"><strong>{money(EARN.deployerRevenue)}</strong><span>Available to claim</span><span className="earn-sol">{EARN.solAvailable}</span></div>
    <p className="earn-empty">No deployer earnings to claim yet. Fees show here as your coins trade.</p>
    <p className="earn-note">Deployers earn 0.20% from every trade (even if you share 100% of creator fees).</p>
    <div className="earn-actions"><ClaimAllButton/></div>
  </section>;
}

function CashOutPanel() {
  return <section className="earn-panel panel" aria-label="Cash out">
    <div className="earn-panel-head"><h2>Cash out</h2><Wallet size={17} className="earn-glyph"/></div>
    <p className="earn-empty">Move what you&apos;ve earned to a bank account or a wallet.</p>
    <div className="cashout-grid">
      <div className="cashout-card">
        <span className="cashout-kind"><Banknote size={15}/> Bank or card · MoonPay</span>
        <p>Send money to your bank account or debit card with MoonPay. Settles in 1–3 business days, depending on your bank.</p>
        <button className="btn" onClick={() => toast.info('Demo only — cash-out is not connected.')}>Cash out to bank</button>
      </div>
      <div className="cashout-card">
        <span className="cashout-kind"><Wallet size={15}/> Wallet address</span>
        <p>Send money to a wallet address on Coinbase, Binance, Solana, or Robinhood. Payment settles instantly.</p>
        <button className="btn" onClick={() => toast.info('Demo only — cash-out is not connected.')}>Send to a wallet</button>
      </div>
    </div>
  </section>;
}

export default function EarnPage() {
  const [view, setView] = useState('Earnings');
  const total = EARN.creatorFees + EARN.referralEarnings + EARN.deployerRevenue;
  return <>
    <div className="page-heading"><div><h1>Earn</h1><p>Everything you&apos;ve earned on Bags, in one place.</p></div><span className="tag">DEMO</span></div>
    <Segments values={['Earnings', 'Portfolio']} value={view} onChange={setView} label="Earn sections"/>
    {view === 'Portfolio' ? <div style={{ marginTop: 22 }}><Portfolio/></div> : DATA_MODE === 'live' ? <>
      <div style={{ marginTop: 22 }}><LiveEarn/></div>
      <div className="notice" style={{ marginTop: 20 }}>Live earnings on Monad Testnet: creator fees accrue to your fee-escrow as your launches trade, and vested buyback proceeds release here. Referral and deployer-revenue programs are not part of the deployed V2 contracts.</div>
    </> : <>
      <section className="earn-hero panel" aria-label="Available to claim">
        <div>
          <span className="earn-label">Available to claim</span>
          <strong className="earn-total">{money(total)}</strong>
          <p>{EARN.solAvailable} across creator fees, referrals and deployer revenue</p>
        </div>
        <ClaimAllButton/>
      </section>
      <div className="earn-cards">
        <a className="earn-card" href="#creator-fees"><span>Creator fees</span><strong>{money(EARN.creatorFees)}</strong></a>
        <a className="earn-card" href="#referrals"><span>Referral earnings</span><strong>{money(EARN.referralEarnings)}</strong></a>
        <a className="earn-card" href="#deployers"><span>Deployer revenue</span><strong>{money(EARN.deployerRevenue)}</strong></a>
      </div>
      <CreatorFeesPanel/>
      <ReferralPanel/>
      <DeployerPanel/>
      <CashOutPanel/>
    </>}
  </>;
}

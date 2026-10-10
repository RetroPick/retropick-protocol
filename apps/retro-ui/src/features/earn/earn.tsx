'use client';
// Earn & Portfolio finance hub (Sections 20–23). LIVE sections consume the existing qualified wallet/claim/referral
// components unchanged; DEMO shows the same information architecture with no claimable amounts and no
// copied third-party fee policy (no SOL, no "50% of fees", no deployer revenue rate).
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ArrowUpRight, Coins, Gift, Layers, Rocket, Send, Wallet } from 'lucide-react';
import Link from '@/components/product/safe-link';
import Portfolio from '@/features/portfolio/portfolio';
import { LivePortfolio } from '@/features/portfolio/live-portfolio';
import { ReferralCard } from './referrals';
import { FundWallet } from './fund-wallet';
import { SendToWallet } from './send-to-wallet';
import { LiveEarn } from '@/features/earn/live-earn';
import { DATA_MODE, INDEXER_URL } from '@/lib/live/env';
import { fetchSearch } from '@/lib/live/indexer-client';
import { launchKeys } from '@/lib/live/queries';
import { useWallet } from '@/wallet/provider';
import { useDemo } from '@/components/product/provider';
import { liveRow } from '@/lib/view-models/discovery';
import { DemoBadge, EmptyState, InfoHint, useCopy } from '@/components/trading/primitives';
import { LaunchTable } from '@/features/launchpad/launch-table';
import './earn-hub.css';

const SECTIONS: Array<[string, string]> = [['claims', 'Claims'], ['portfolio', 'Portfolio'], ['launches', 'Created launches'], ['referrals', 'Referrals'], ['funding', 'Fund & send']];

function HubNav() {
  return <nav className="rp-hub-nav" aria-label="Earn and portfolio sections">{SECTIONS.map(([id, label]) => <a key={id} href={`#${id}`}>{label}</a>)}</nav>;
}

/** Created launches. The indexer has no creator filter; search by the wallet address is capped at 20 results. */
function CreatedLaunches() {
  const { account } = useWallet();
  const q = useQuery({ queryKey: [...launchKeys.all, 'created', account ?? ''], enabled: !!INDEXER_URL && !!account, queryFn: ({ signal }) => fetchSearch(INDEXER_URL!, account!, signal), staleTime: 10000 });
  const rows = (q.data?.data ?? []).filter((l) => l.creator.toLowerCase() === account?.toLowerCase()).map(liveRow);
  return <section id="launches" className="rp-hub-section" aria-labelledby="h-launches">
    <h2 id="h-launches"><Rocket size={16} aria-hidden/>Created launches</h2>
    {!account ? <EmptyState title="Connect a wallet to see launches you created"/>
      : q.isError ? <p className="rp-note" role="alert">Launch search is unavailable. Try again later.</p>
      : <><LaunchTable rows={rows} view="list" now={Date.now()} empty="No indexed launches list this wallet as creator."/>
        <p className="rp-note">Matched by creator address through indexer search (first 20 matches). {(q.data?.data.length ?? 0) >= 20 ? 'More launches may exist — this list is not complete.' : 'This list may still be incomplete until the indexer exposes a creator filter.'}</p></>}
  </section>;
}

function LiveHub() {
  return <div className="rp-hub" data-testid="earn-hub" data-data-mode="live">
    <header className="rp-hub-head"><div><h1>Earn &amp; Portfolio</h1><p>Real balances, claims and attribution for your connected Monad Testnet wallet.</p></div></header>
    <HubNav/>
    <section id="claims" className="rp-hub-section"><LiveEarn/></section>
    <section id="portfolio" className="rp-hub-section"><LivePortfolio/></section>
    <CreatedLaunches/>
    <section className="rp-hub-section"><ReferralCard/></section>
    <section id="funding" className="rp-hub-section"><FundWallet><SendToWallet/></FundWallet></section>
  </div>;
}

const DEMO_REFERRAL = 'https://demo.retropick.xyz/r/DEMO-0001';

function DemoHub() {
  const demo = useDemo();
  const [copied, copy] = useCopy();
  const [view, setView] = useState<'earnings' | 'portfolio'>('earnings');
  return <div className="rp-hub" data-testid="earn-hub" data-data-mode="demo">
    <header className="rp-hub-head"><div><h1>Earn &amp; Portfolio <DemoBadge/></h1><p>How creator fees, buyback releases, referrals and wallet funding appear in RetroPick. No real funds and no claim contract are connected in demo mode.</p></div></header>
    <HubNav/>
    <section id="claims" className="rp-hub-hero" aria-label="Available to claim">
      <div><span className="rp-hub-label">Available to claim</span><strong className="rp-hub-total" data-testid="claimable-total">—</strong><p>In live mode this is read per asset from the RetroPick fee escrow for your wallet. Demo mode has no claimable balance.</p></div>
      <button className="rp-btn rp-btn-primary" disabled title="No claim contract is connected in demo mode">Claim all</button>
    </section>
    <div className="rp-hub-cards">
      <div className="rp-hub-card"><Coins size={16} aria-hidden/><span>Creator fees <InfoHint text="The creator fee configured on each launch (shown on the token's Protocol tab) is credited to the fee escrow on every curve trade."/></span><strong>—</strong><small>Fee escrow credit · live only</small></div>
      <div className="rp-hub-card"><Layers size={16} aria-hidden/><span>Buyback / vested release</span><strong>—</strong><small>Releasable share from buyback vaults · live only</small></div>
      <div className="rp-hub-card"><Gift size={16} aria-hidden/><span>Referral earnings</span><strong>Not enabled</strong><small>Referral attribution is tracked; payouts are not funded.</small></div>
    </div>
    <section id="portfolio" className="rp-hub-section" aria-labelledby="h-portfolio">
      <div className="rp-hub-row"><h2 id="h-portfolio"><Wallet size={16} aria-hidden/>Portfolio</h2><button className="rp-btn rp-btn-ghost rp-btn-sm" onClick={() => setView(view === 'portfolio' ? 'earnings' : 'portfolio')} aria-expanded={view === 'portfolio'}>{view === 'portfolio' ? 'Hide demo positions' : 'Show demo positions'}</button></div>
      <p className="rp-note">Live mode lists wallet assets, Kuru margin (with withdraw), and open orders from chain + indexer.{demo.connected ? '' : ' Prediction/PRISM demo positions are available below.'}</p>
      {view === 'portfolio' && <div className="rp-hub-embed"><Portfolio/></div>}
    </section>
    <section id="launches" className="rp-hub-section" aria-labelledby="h-launches"><h2 id="h-launches"><Rocket size={16} aria-hidden/>Created launches</h2><p className="rp-note">Launches your wallet created appear here in live mode. <Link className="rp-link" href="/launchpad/create">Launch a token <ArrowUpRight size={12} aria-hidden/></Link></p></section>
    <section id="referrals" className="rp-hub-section" aria-labelledby="h-ref">
      <h2 id="h-ref"><Gift size={16} aria-hidden/>Referrals</h2>
      <p className="rp-note">Share a link to attribute confirmed launches and trades to your wallet. Referral earnings are not enabled.</p>
      <div className="rp-ref"><label className="rp-sr" htmlFor="demo-ref">Your referral link</label><input id="demo-ref" readOnly value={DEMO_REFERRAL} aria-label="Your referral link"/><button className="rp-btn rp-btn-sm" onClick={() => copy(DEMO_REFERRAL)}>{copied ? 'Link copied' : 'Copy'}</button><DemoBadge/></div>
    </section>
    <section id="funding" className="rp-hub-section" aria-labelledby="h-fund"><h2 id="h-fund" className="rp-sr">Fund and send</h2><FundWallet/><div className="rp-hub-send"><h3><Send size={15} aria-hidden/>Send</h3><p className="rp-note">Transfers to an EVM address on Monad Testnet. Connect a live wallet in live mode; demo mode never sends.</p></div></section>
  </div>;
}

export default function EarnPage() {
  return DATA_MODE === 'live' ? <LiveHub/> : <DemoHub/>;
}

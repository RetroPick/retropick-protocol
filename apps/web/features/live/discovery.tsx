'use client';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { release } from '@/lib/live/client';
import { readLaunch, type LiveLaunch } from '@/lib/live/model';
import type { Address } from 'viem';
export default function LiveDiscovery() {
  const [demo, setDemo] = useState<LiveLaunch>(); const [error, setError] = useState('');
  useEffect(() => { let active = true; readLaunch(release.demo.token as Address).then(data => { if (active) setDemo(data); }).catch(() => { if (active) setError('RPC unavailable. Open the market to retry.'); }); return () => { active = false; }; }, []);
  return <><div className="live-heading"><div><span className="eyebrow">THE MARKET CREATION LAYER FOR MONAD</span><h1>From token to live market.</h1><p>Launch through transparent onchain price discovery.<br/>Graduate into protected Kuru orderbook liquidity.</p></div><Link className="btn primary" href="/launchpad/create">Create token ↗</Link></div><section className="live-panel"><p className="live-flow">Launch → Bonding curve → Graduation → Kuru → Protected liquidity → Trading</p></section><div className="live-heading"><h2>Live on Monad Testnet</h2><span>Actual chain state · no illustrative volumes</span></div><Link className="live-panel live-market-card" href={`/launchpad/token/${release.demo.token}`}><div><span className="eyebrow">CANONICAL DEMO MARKET</span><h2>{demo?.name || 'RetroPick V2 launch'} {demo && <small>{demo.symbol}</small>}</h2><p>{error || (demo ? ['Bonding', 'Graduating', 'Graduated to Kuru'][demo.ledger.phase] : 'Reading onchain status…')}</p></div><span>View market & Launch Proof ↗</span></Link><section className="live-panel"><h2>Why two stages?</h2><p>The bonding curve bootstraps primary price discovery. Kuru provides the secondary orderbook, limit orders and market-making workflows. Graduation assets are permanently protected for this testnet candidate.</p><p>Functional order/fill/cancel evidence is available in the repository. Test traffic is not a claim of organic volume.</p></section></>;
}

'use client';

import Link from '@/components/product/safe-link';
import { TokenIcon } from '@/components/product/ui';
import { Dialog, DialogContent, DialogDescription, DialogTitle } from '@/components/ui/dialog';
import { getInstrumentRoute } from '@/lib/domain/launchpad-adapters';
import { launchInstruments } from '@/lib/domain/launchpad-repository';
import type { LaunchInstrument } from '@/lib/domain/instruments';
import { useDemo } from './provider';
import Image from 'next/image';
import { ArrowUpRight, BookOpen, ChevronDown, Menu, Search, Wallet, X } from 'lucide-react';
import { useEffect, useState, type ReactNode } from 'react';
import { usePathname } from 'next/navigation';

const nav = [['Launchpad', '/launchpad'], ['PRISM', '/prism'], ['Activity', '/activity'], ['Portfolio', '/portfolio']] as const;
const groups = ['prediction', 'token', 'prism'] as const;
const kindLabel = (item: LaunchInstrument) => item.kind === 'prediction' ? 'Prediction' : item.kind === 'prism' ? 'PRISM' : item.referenceClass === 'stock' ? 'Stocks' : 'Crypto';

export function Shell({ children }: { children: ReactNode }) {
  const path = usePathname();
  const demo = useDemo();
  const [searchOpen, setSearchOpen] = useState(false);
  const [walletOpen, setWalletOpen] = useState(false);
  const [mobile, setMobile] = useState(false);
  const [q, setQ] = useState('');
  useEffect(() => { const key = (event: KeyboardEvent) => { if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') { event.preventDefault(); setSearchOpen(true); } }; window.addEventListener('keydown', key); return () => window.removeEventListener('keydown', key); }, []);
  const results = launchInstruments.filter((item) => `${item.name} ${item.symbol} ${item.creator}`.toLowerCase().includes(q.toLowerCase()));
  return <><a href="#main" className="skip">Skip to content</a><header className="header"><Link href="/launchpad" className="brand" aria-label="RetroPick Launchpad home"><Image src="/brand/retropick.png" alt="" width={34} height={34} unoptimized/><span>RetroPick</span><span className="launchpad-label">LAUNCHPAD</span></Link><nav className={mobile ? 'main-nav mobile-open' : 'main-nav'} aria-label="Primary navigation">{nav.map(([name, url]) => <Link key={url} href={url} onClick={() => setMobile(false)} className={path.startsWith(url) ? 'active' : ''}>{name}{name === 'PRISM' && <span className="nav-new">NEW</span>}</Link>)}</nav><div className="header-actions"><button className="global-search" onClick={() => setSearchOpen(true)} aria-label="Search Launchpad and PRISM"><Search size={16}/><span>Search launches</span><kbd>⌘ K</kbd></button><span className="network"><span className="monad">◈</span> Monad <ChevronDown size={12}/></span><button className="btn wallet" aria-label={demo.connected ? 'Demo wallet' : 'Connect wallet'} onClick={() => setWalletOpen(true)}><Wallet size={15}/><span>{demo.connected ? 'Demo wallet' : 'Connect wallet'}</span></button><button className="icon-button menu-toggle" aria-label="Toggle navigation" onClick={() => setMobile((open) => !open)}>{mobile ? <X size={20}/> : <Menu size={20}/>}</button></div></header><div className="demo-strip"><span className="demo-pill">DEMO</span><span>Illustrative markets, token launches and trading states. No real funds or transactions.</span><Link href="/docs">How it works <ArrowUpRight size={12}/></Link></div><main id="main" className="main">{children}</main><footer className="footer"><div><span className="footer-brand">RetroPick</span><span>Real events. Onchain assets.</span></div><div><span>Demo snapshot · Sep 17, 2026</span><Link href="/docs">Protocol guide <BookOpen size={13}/></Link><a href="https://github.com/RetroPick/retropick-protocol" target="_blank" rel="noreferrer">GitHub <ArrowUpRight size={13}/></a></div></footer><Dialog open={searchOpen} onOpenChange={setSearchOpen}><DialogContent className="product-dialog"><DialogTitle>Search RetroPick</DialogTitle><DialogDescription>Grouped results preserve the difference between prediction markets, normal token launches and PRISM.</DialogDescription><div className="search-field"><Search size={17}/><input autoFocus aria-label="Search Launchpad and PRISM" value={q} onChange={(event) => setQ(event.target.value)} placeholder="BTC, MDOG, NVIDIA…"/></div><div className="search-results">{groups.map((kind) => { const grouped = results.filter((item) => item.kind === kind); if (!grouped.length) return null; return <div className="search-group" key={kind}><span>{kind === 'token' ? 'Tokens' : kind === 'prediction' ? 'Prediction' : 'PRISM'}</span>{grouped.map((item) => <Link href={getInstrumentRoute(item)} key={item.id} onClick={() => setSearchOpen(false)}><TokenIcon market={{ icon: item.icon ?? '◇', color: item.color ?? '#b09cfa' }} small/><span>{item.name}<small>{kindLabel(item)} · {item.symbol} · DEMO</small></span><ArrowUpRight size={16}/></Link>)}</div>; })}{q && !results.length && <p>No matching launch. Try a title or symbol.</p>}</div></DialogContent></Dialog><Dialog open={walletOpen} onOpenChange={setWalletOpen}><DialogContent className="product-dialog"><DialogTitle>{demo.connected ? 'Demo wallet' : 'Explore with a demo wallet'}</DialogTitle><DialogDescription>Try the presentation flows using a simulated balance. No wallet extension, signature or real transaction is requested.</DialogDescription><div className="notice">Live wallet connection is unavailable until the protocol and execution integrations are verified.</div><button className="btn primary full" onClick={() => { demo.setConnected(!demo.connected); setWalletOpen(false); }}>{demo.connected ? 'Disconnect demo wallet' : 'Use demo wallet'}</button></DialogContent></Dialog></>;
}

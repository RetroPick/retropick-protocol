'use client';

import Link from '@/components/product/safe-link';
import { TokenIcon } from '@/components/product/ui';
import { Dialog, DialogContent, DialogDescription, DialogTitle } from '@/components/ui/dialog';
import { getInstrumentRoute } from '@/lib/domain/launchpad-adapters';
import { launchInstruments } from '@/lib/domain/launchpad-repository';
import type { LaunchInstrument } from '@/lib/domain/instruments';
import { useDemo } from '@/components/product/provider';
import { RetroLogo } from '@/components/Icons';
import { Sidebar } from '@/components/shell/sidebar';
import { MobileNav } from '@/components/shell/mobile-nav';
import { ArrowUpRight, Search, Wallet } from 'lucide-react';
import { useEffect, useState, type ReactNode } from 'react';

const groups = ['prediction', 'token', 'prism'] as const;
const kindLabel = (item: LaunchInstrument) => item.kind === 'prediction' ? 'Prediction' : item.kind === 'prism' ? 'PRISM' : item.referenceClass === 'stock' ? 'Stocks' : 'Crypto';

const SIDEBAR_COLLAPSED_KEY = 'retropick-sidebar-collapsed';

// No top navbar: desktop chrome is the sidebar alone (search, wallet and
// theme toggle included). Phones get a one-row fallback bar for search and
// wallet, since the sidebar is hidden below md.
export function Shell({ children }: { children: ReactNode }) {
  const demo = useDemo();
  const [searchOpen, setSearchOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  const [q, setQ] = useState('');
  useEffect(() => {
    try { setCollapsed(localStorage.getItem(SIDEBAR_COLLAPSED_KEY) === '1'); } catch { /* ignore */ }
  }, []);
  const toggleCollapsed = () => setCollapsed((value) => {
    const next = !value;
    try { localStorage.setItem(SIDEBAR_COLLAPSED_KEY, next ? '1' : '0'); } catch { /* ignore */ }
    return next;
  });
  useEffect(() => { const key = (event: KeyboardEvent) => { if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') { event.preventDefault(); setSearchOpen(true); } }; window.addEventListener('keydown', key); return () => window.removeEventListener('keydown', key); }, []);
  const results = launchInstruments.filter((item) => `${item.name} ${item.symbol} ${item.creator}`.toLowerCase().includes(q.toLowerCase()));
  return <><a href="#main" className="skip">Skip to content</a><Sidebar isCollapsed={collapsed} onToggleCollapse={toggleCollapsed} onOpenSearch={() => setSearchOpen(true)}/><div className={`min-h-screen flex flex-col transition-all duration-200 ${collapsed ? 'md:pl-[72px]' : 'md:pl-[240px]'}`}><div className="mobilebar"><Link href="/launchpad" aria-label="RetroPick Launchpad home"><RetroLogo className="w-7 h-7"/></Link><span className="spacer"/><button className="icon-btn" onClick={() => setSearchOpen(true)} aria-label="Search tokens and markets"><Search size={18}/></button><button className="icon-btn" onClick={() => demo.setConnected(!demo.connected)} aria-label={demo.connected ? 'Demo wallet' : 'Connect wallet'}><Wallet size={18}/></button></div><div className="demo-strip"><span className="demo-pill">DEMO</span><span>Illustrative data — no real funds.</span><Link href="/docs">How it works <ArrowUpRight size={12}/></Link></div><main id="main" className="main">{children}</main><footer className="footer"><div><span className="footer-brand">RetroPick</span><span>Demo snapshot · Sep 17, 2026</span></div><div><Link href="/docs">Docs</Link><a href="https://github.com/RetroPick/retropick-protocol" target="_blank" rel="noreferrer">GitHub <ArrowUpRight size={12}/></a></div></footer></div><MobileNav/><Dialog open={searchOpen} onOpenChange={setSearchOpen}><DialogContent className="product-dialog"><DialogTitle>Search RetroPick</DialogTitle><DialogDescription>Prediction markets, token launches and PRISM.</DialogDescription><div className="search-field"><Search size={17}/><input autoFocus aria-label="Search Launchpad and PRISM" value={q} onChange={(event) => setQ(event.target.value)} placeholder="Token, market or symbol…"/></div><div className="search-results">{groups.map((kind) => { const grouped = results.filter((item) => item.kind === kind); if (!grouped.length) return null; return <div className="search-group" key={kind}><span>{kind === 'token' ? 'Tokens' : kind === 'prediction' ? 'Prediction' : 'PRISM'}</span>{grouped.map((item) => <Link href={getInstrumentRoute(item)} key={item.id} onClick={() => setSearchOpen(false)}><TokenIcon market={{ icon: item.icon ?? '◇', color: item.color ?? '#b09cfa' }} small/><span>{item.name}<small>{kindLabel(item)} · {item.symbol} · DEMO</small></span><ArrowUpRight size={16}/></Link>)}</div>; })}{q && !results.length && <p>No matching launch. Try a title or symbol.</p>}</div></DialogContent></Dialog></>;
}

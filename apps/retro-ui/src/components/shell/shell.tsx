'use client';

import Link from '@/components/product/safe-link';
import { DATA_MODE } from '@/lib/live/env';
import { CommandPalette } from './command-palette';
import { Sidebar } from '@/components/shell/sidebar';
import { MobileNav } from '@/components/shell/mobile-nav';
import { TopNavbar } from '@/components/shell/top-navbar';
import { ArrowUpRight } from 'lucide-react';
import { useEffect, useState, type ReactNode } from 'react';


const SIDEBAR_COLLAPSED_KEY = 'retropick-sidebar-collapsed';

// Shell = sidebar (>=1024px) + universal top navbar + demo/live strip + main +
// footer + mobile bottom nav (<768px). Search, wallet, network and theme live
// in the navbar; the sidebar owns primary navigation and Launch on desktop.
export function Shell({ children }: { children: ReactNode }) {
  const [searchOpen, setSearchOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  useEffect(() => {
    try { setCollapsed(localStorage.getItem(SIDEBAR_COLLAPSED_KEY) === '1'); } catch { /* ignore */ }
  }, []);
  const toggleCollapsed = () => setCollapsed((value) => {
    const next = !value;
    try { localStorage.setItem(SIDEBAR_COLLAPSED_KEY, next ? '1' : '0'); } catch { /* ignore */ }
    return next;
  });
  useEffect(() => { const key = (event: KeyboardEvent) => { const target = event.target as HTMLElement | null; const typing = !!target && (target.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].includes(target.tagName)); if (((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') || (event.key === '/' && !typing)) { event.preventDefault(); setSearchOpen(true); } }; window.addEventListener('keydown', key); return () => window.removeEventListener('keydown', key); }, []);
  return <><a href="#main" className="skip">Skip to content</a><Sidebar isCollapsed={collapsed} onToggleCollapse={toggleCollapsed} onOpenSearch={() => setSearchOpen(true)}/><div className={`min-h-screen flex flex-col transition-all duration-200 ${collapsed ? 'lg:pl-[76px]' : 'lg:pl-[260px]'}`}><TopNavbar onOpenSearch={() => setSearchOpen(true)}/><div className="demo-strip">{DATA_MODE === 'live' ? <><span className="demo-pill">LIVE</span><span>Monad Testnet · chain 10143 · test assets.</span></> : <><span className="demo-pill">DEMO</span><span>Illustrative data — no real funds.</span></>}<Link href="/docs">How it works <ArrowUpRight size={12}/></Link></div><main id="main" className="main">{children}</main><footer className="footer"><div><span className="footer-brand">RetroPick</span><span>{DATA_MODE === 'live' ? 'Monad Testnet · live contract data' : 'Demo snapshot · Sep 17, 2026'}</span></div><div><Link href="/docs">Docs</Link><a href="https://github.com/RetroPick/retropick-protocol" target="_blank" rel="noreferrer">GitHub <ArrowUpRight size={12}/></a></div></footer></div><MobileNav/><CommandPalette open={searchOpen} onOpenChange={setSearchOpen}/></>;
}

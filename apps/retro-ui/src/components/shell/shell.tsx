'use client';

import Link from '@/components/product/safe-link';
import { useDemo } from '@/components/product/provider';
import { useWallet } from '@/wallet/provider';
import { DATA_MODE } from '@/lib/live/env';
import { CommandPalette } from './command-palette';
import { RetroLogo } from '@/components/Icons';
import { Sidebar } from '@/components/shell/sidebar';
import { MobileNav } from '@/components/shell/mobile-nav';
import { ArrowUpRight, Search, Wallet } from 'lucide-react';
import { useEffect, useState, type ReactNode } from 'react';


const SIDEBAR_COLLAPSED_KEY = 'retropick-sidebar-collapsed';

// Shell = sidebar (>=768px, carries brand/search/nav/Launch/network/wallet/theme
// + the LIVE/DEMO indicator) + content column + mobile bar (<768px: brand,
// search, wallet, mode pill) + bottom nav (<768px). No top navbar.
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
  const live = DATA_MODE === 'live';
  return <><a href="#main" className="skip">Skip to content</a><Sidebar isCollapsed={collapsed} onToggleCollapse={toggleCollapsed} onOpenSearch={() => setSearchOpen(true)}/><div className={`min-h-screen flex flex-col transition-all duration-200 ${collapsed ? 'md:pl-[76px]' : 'md:pl-[260px]'}`}>
    <header className="mobilebar">
      <Link href="/launchpad" aria-label="RetroPick Launchpad home"><RetroLogo className="w-7 h-7"/></Link>
      <span className={`mobilebar-mode ${live ? 'is-live' : 'is-demo'}`}>{live ? 'LIVE' : 'DEMO'}</span>
      <span className="spacer"/>
      <button className="icon-btn" onClick={() => setSearchOpen(true)} aria-label="Search tokens and markets"><Search size={18}/></button>
      <MobileWalletButton/>
    </header>
    <main id="main" className="main">{children}</main>
    <footer className="footer"><div><span className="footer-brand">RetroPick</span><span>{live ? 'Monad Testnet · live contract data' : 'Demo snapshot · Sep 17, 2026'}</span></div><div><Link href="/docs">Docs</Link><a href="https://github.com/RetroPick/retropick-protocol" target="_blank" rel="noreferrer">GitHub <ArrowUpRight size={12}/></a></div></footer>
  </div><MobileNav/><CommandPalette open={searchOpen} onOpenChange={setSearchOpen}/></>;
}

/** Mobile bar wallet: real wallet in live mode, demo toggle in mock mode. */
function MobileWalletButton() {
  const demo = useDemo();
  const wallet = useWallet(); // provider is always mounted; mock mode ignores it
  if (DATA_MODE !== 'live') return <button className="icon-btn" onClick={() => demo.setConnected(!demo.connected)} aria-label={demo.connected ? 'Demo wallet' : 'Connect wallet'}><Wallet size={18}/></button>;
  return <button className="icon-btn" onClick={() => (wallet.status === 'disconnected' ? void wallet.connect() : wallet.status === 'wrong-chain' ? void wallet.switchChain() : wallet.disconnect())} aria-label={wallet.status === 'connected' ? `Wallet ${wallet.account}` : 'Connect wallet'} data-wallet-status={wallet.status}><Wallet size={18}/></button>;
}

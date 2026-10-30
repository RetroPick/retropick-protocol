'use client';

import {
  Home,
  Coins,
  ChevronsLeft,
  ChevronsRight,
  Plus,
  Search,
  Droplets,
  FlaskConical,
  Sun,
  Moon,
  Wallet,
  ArrowUpRight,
} from 'lucide-react';
import Link from '@/components/product/safe-link';
import { usePathname } from '@/lib/next-compat';
import { useDemo } from '@/components/product/provider';
import { useWallet } from '@/wallet/provider';
import { DATA_MODE } from '@/lib/live/env';
import { toggleTheme, useTheme } from '@/lib/theme';

interface SidebarProps {
  isCollapsed: boolean;
  onToggleCollapse: () => void;
  onOpenSearch: () => void;
}

// Primary navigation rail (>=768px). Carries everything the removed top
// navbar held: search, chain-state pill (derived from wallet status — never
// decorative), wallet, theme, and the LIVE/DEMO indicator with chain copy and
// the docs ("How it works") link. Research modules have no live financial
// data, so they appear in mock mode only.
export function Sidebar({ isCollapsed, onToggleCollapse, onOpenSearch }: SidebarProps) {
  const pathname = usePathname();
  const theme = useTheme();
  const live = DATA_MODE === 'live';
  const isActive = (id: 'home' | 'earn' | 'liquidity') => {
    if (id === 'liquidity') return pathname.startsWith('/liquidity');
    if (id === 'earn') return pathname.startsWith('/earn') || pathname.startsWith('/portfolio');
    return pathname.startsWith('/launchpad') || pathname.startsWith('/prism') || pathname.startsWith('/creator') || pathname === '/docs';
  };

  const navItems = [
    { id: 'home' as const, label: 'Home', icon: Home, href: '/launchpad' },
    { id: 'liquidity' as const, label: 'Liquidity', icon: Droplets, href: '/liquidity' },
    { id: 'earn' as const, label: 'Earn', icon: Coins, href: '/earn' },
  ];
  const research = live ? [] : [
    { label: 'Prediction', href: '/markets' },
    { label: 'PRISM', href: '/prism' },
  ];

  return (
    <aside className={`sidebar${isCollapsed ? ' collapsed' : ''}`}>
      <div className="side-top">
        <div className="side-brand">
          <Link href="/launchpad" className="side-brand-link" aria-label="RetroPick Launchpad home">
            <img src="/brand/retropick.png" alt="" className="w-8 h-8 object-contain"/>
            {!isCollapsed && <span className="side-brand-name">Retro</span>}
          </Link>
          <button onClick={onToggleCollapse} className="side-collapse" aria-label={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}>
            {isCollapsed ? <ChevronsRight className="w-4 h-4"/> : <ChevronsLeft className="w-4 h-4"/>}
          </button>
        </div>

        <button className="side-search" onClick={onOpenSearch} aria-label="Search tokens and markets" title="Search (⌘K)">
          <Search size={15}/>
          {!isCollapsed && <><span>Search</span><kbd>⌘K</kbd></>}
        </button>

        <nav className="side-nav" aria-label="Primary navigation">
          {navItems.map((item) => {
            const IconComponent = item.icon;
            const active = isActive(item.id);
            return (
              <Link
                key={item.id}
                href={item.href}
                aria-current={active ? 'page' : undefined}
                className={`side-link${active ? ' active' : ''}`}
                title={isCollapsed ? item.label : undefined}
              >
                <IconComponent className="w-5 h-5"/>
                {!isCollapsed && <span>{item.label}</span>}
              </Link>
            );
          })}
        </nav>

        <Link href="/launchpad/create" className="launch-btn" title="Launch a token">
          <Plus className="w-4 h-4 stroke-[3]"/>
          {!isCollapsed && <span>Launch</span>}
        </Link>

        {research.length > 0 && <>
          {!isCollapsed && <div className="side-group-label" aria-hidden="true">Research · demo</div>}
          <div className="side-nav side-nav-sub">
            {research.map((item) => (
              <Link key={item.label} href={item.href} className="side-link side-link-sub" title={isCollapsed ? `${item.label} (demo)` : undefined}>
                <FlaskConical className="w-4.5 h-4.5"/>
                {!isCollapsed && <span className="side-label">{item.label}</span>}
              </Link>
            ))}
          </div>
        </>}
      </div>

      <div className="side-bottom">
        <NetworkPill isCollapsed={isCollapsed}/>
        <WalletButton isCollapsed={isCollapsed}/>
        <button className="side-action" onClick={toggleTheme} aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`} title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}>
          {theme === 'dark' ? <Sun className="w-5 h-5"/> : <Moon className="w-5 h-5"/>}
          {!isCollapsed && <span className="side-label">{theme === 'dark' ? 'Light theme' : 'Dark theme'}</span>}
        </button>
        <div className="side-mode" data-mode={live ? 'live' : 'demo'}>
          {live
            ? <>{!isCollapsed && <><span className="side-mode-pill">LIVE</span><span className="side-mode-copy">Monad Testnet · chain 10143 · test assets.</span><Link className="side-mode-link" href="/docs">How it works <ArrowUpRight size={10} aria-hidden/></Link></>}</>
            : <>{!isCollapsed && <><span className="side-mode-pill">DEMO</span><span className="side-mode-copy">Illustrative data — no real funds.</span><Link className="side-mode-link" href="/docs">How it works <ArrowUpRight size={10} aria-hidden/></Link></>}</>}
        </div>
      </div>
    </aside>
  );
}

/** Chain state is derived from the wallet context — the pill never fakes a connection. */
function NetworkPill({ isCollapsed }: { isCollapsed: boolean }) {
  const live = DATA_MODE === 'live';
  const wallet = useWallet();
  if (!live) return null;
  const state = wallet.status === 'connected' ? 'is-live'
    : wallet.status === 'wrong-chain' ? 'is-warn'
    : wallet.status === 'connecting' ? 'is-off' : 'is-off';
  const label = wallet.status === 'connected' ? 'Monad Testnet'
    : wallet.status === 'wrong-chain' ? 'Wrong chain'
    : wallet.status === 'connecting' ? 'Connecting…' : 'Testnet 10143';
  const title = wallet.status === 'connected' ? 'Connected · Monad Testnet · chain 10143'
    : wallet.status === 'wrong-chain' ? 'Wallet is on the wrong network — click to switch to Monad Testnet (10143)'
    : wallet.status === 'connecting' ? 'Connecting wallet…' : 'Monad Testnet · chain 10143 · wallet not connected';
  return <button
    className={`side-net ${state}`}
    onClick={wallet.status === 'wrong-chain' ? () => void wallet.switchChain() : undefined}
    aria-label={title}
    title={title}
  >
    <span className="side-net-dot" aria-hidden="true"/>
    {!isCollapsed && <span className="side-label">{label}</span>}
  </button>;
}

/** Live mode connects a real EIP-1193 wallet; mock mode keeps the demo wallet. */
function WalletButton({ isCollapsed }: { isCollapsed: boolean }) {
  const demo = useDemo();
  const live = DATA_MODE === 'live';
  const wallet = useWallet();
  if (!live) {
    return <button className="side-action side-wallet" onClick={() => demo.setConnected(!demo.connected)} aria-label={demo.connected ? 'Demo wallet' : 'Connect wallet'} title={demo.connected ? 'Demo wallet' : 'Connect wallet'}>
      <Wallet className="w-5 h-5"/>
      {!isCollapsed && <span className="side-label">{demo.connected ? 'Demo wallet' : 'Connect wallet'}</span>}
    </button>;
  }
  const label = wallet.status === 'connected' ? `${wallet.account?.slice(0, 6)}…${wallet.account?.slice(-4)}`
    : wallet.status === 'wrong-chain' ? 'Wrong chain'
    : wallet.status === 'connecting' ? 'Connecting…'
    : 'Connect wallet';
  return <button className="side-action side-wallet" onClick={() => (wallet.status === 'disconnected' ? void wallet.connect() : wallet.status === 'wrong-chain' ? void wallet.switchChain() : wallet.disconnect())} aria-label={label} title={wallet.walletName ? `${wallet.walletName} · ${label}` : label} data-wallet-status={wallet.status}>
    <Wallet className="w-5 h-5"/>
    {!isCollapsed && <span className="side-label">{label}</span>}
  </button>;
}

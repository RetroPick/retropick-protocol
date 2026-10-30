'use client';

import Link from '@/components/product/safe-link';
import { usePathname } from '@/lib/next-compat';
import { useDemo } from '@/components/product/provider';
import { useWallet } from '@/wallet/provider';
import { DATA_MODE } from '@/lib/live/env';
import { toggleTheme, useTheme } from '@/lib/theme';
import { ChevronRight, Plus, Search, Sun, Moon, Wallet } from 'lucide-react';

interface TopNavbarProps {
  onOpenSearch: () => void;
}

const PAGE_TITLES: Array<[prefix: boolean, match: string, title: string]> = [
  [true, '/launchpad/create', 'Create launch'],
  [true, '/launchpad/prediction', 'Prediction (research)'],
  [true, '/launchpad/token', 'Token terminal'],
  [true, '/launchpad', 'Launchpad'],
  [true, '/liquidity/market-making', 'Market making'],
  [true, '/liquidity', 'Liquidity'],
  [true, '/earn', 'Earn'],
  [true, '/prism', 'PRISM (research)'],
  [true, '/portfolio', 'Portfolio'],
  [true, '/activity', 'Activity (research)'],
  [true, '/creator', 'Creator (research)'],
  [true, '/docs', 'Docs'],
];

function pageTitle(pathname: string): string {
  for (const [prefix, match, title] of PAGE_TITLES) {
    if (prefix ? pathname.startsWith(match) : pathname === match) return title;
  }
  return 'Launchpad';
}

// Universal chrome above the content column: brand (below the sidebar's
// 1024px breakpoint), breadcrumb context on desktop, search entry below 1024,
// chain-state pill, Launch CTA, wallet and theme. The sidebar remains primary
// navigation at >=1024px; this navbar also carries compact primary links across
// the 768–1023px tablet band so no breakpoint is left without navigation.
export function TopNavbar({ onOpenSearch }: TopNavbarProps) {
  const pathname = usePathname();
  const theme = useTheme();
  const demo = useDemo();
  const wallet = useWallet();
  const live = DATA_MODE === 'live';

  const links = [
    { id: 'home' as const, label: 'Home', href: '/launchpad' },
    { id: 'liquidity' as const, label: 'Liquidity', href: '/liquidity' },
    { id: 'earn' as const, label: 'Earn', href: '/earn' },
  ];
  const isActive = (id: 'home' | 'earn' | 'liquidity') => {
    if (id === 'liquidity') return pathname.startsWith('/liquidity');
    if (id === 'earn') return pathname.startsWith('/earn') || pathname.startsWith('/portfolio');
    return pathname.startsWith('/launchpad') || pathname.startsWith('/prism') || pathname.startsWith('/creator') || pathname === '/docs';
  };

  // Chain state is derived, never decorative: the pill reports what the wallet
  // context actually knows. Demo mode says DEMO — it never fakes a connection.
  const net = !live
    ? { state: 'is-demo', dot: false, label: 'DEMO', title: 'Demo mode — illustrative data, no real funds' }
    : wallet.status === 'connected'
      ? { state: 'is-live', dot: true, label: 'Monad Testnet', title: 'Connected · Monad Testnet · chain 10143' }
      : wallet.status === 'wrong-chain'
        ? { state: 'is-warn', dot: true, label: 'Wrong chain', title: 'Wallet is on the wrong network — click to switch to Monad Testnet (10143)' }
        : wallet.status === 'connecting'
          ? { state: 'is-off', dot: true, label: 'Connecting', title: 'Connecting wallet…' }
          : { state: 'is-off', dot: true, label: 'Testnet 10143', title: 'Monad Testnet · chain 10143 · wallet not connected' };

  const walletLabel = !live
    ? (demo.connected ? 'Demo wallet' : 'Connect wallet')
    : wallet.status === 'connected'
      ? `${wallet.account?.slice(0, 6)}…${wallet.account?.slice(-4)}`
      : wallet.status === 'wrong-chain' ? 'Wrong chain'
      : wallet.status === 'connecting' ? 'Connecting…'
      : 'Connect wallet';
  const handleWalletClick = () => {
    if (!live) { demo.setConnected(!demo.connected); return; }
    if (wallet.status === 'disconnected') void wallet.connect();
    else if (wallet.status === 'wrong-chain') void wallet.switchChain();
    else wallet.disconnect();
  };

  return (
    <header className="navbar">
      <div className="navbar-inner">
        <div className="navbar-left">
          <Link href="/launchpad" className="navbar-brand" aria-label="RetroPick Launchpad home">
            <img src="/brand/retropick.png" alt="" className="w-7 h-7 object-contain"/>
            <span className="navbar-brand-name">RetroPick</span>
          </Link>
          {/* Tablet band (768–1023): sidebar is hidden, so primary nav lives here. */}
          <nav className="navbar-links" aria-label="Primary navigation">
            {links.map((item) => (
              <Link key={item.id} href={item.href} aria-current={isActive(item.id) ? 'page' : undefined} className={`navbar-link${isActive(item.id) ? ' active' : ''}`}>
                {item.label}
              </Link>
            ))}
          </nav>
          <p className="navbar-crumb" aria-hidden="true">
            <span>RetroPick</span>
            <ChevronRight size={12}/>
            <span className="navbar-crumb-page">{pageTitle(pathname)}</span>
          </p>
        </div>

        <button className="navbar-search" onClick={onOpenSearch} aria-label="Search tokens and markets" title="Search (⌘K)">
          <Search size={16}/>
        </button>

        <div className="navbar-right">
          <button
            className={`navbar-net ${net.state}`}
            onClick={live && wallet.status === 'wrong-chain' ? () => void wallet.switchChain() : undefined}
            title={net.title}
            aria-label={net.title}
            {...(live && wallet.status === 'wrong-chain' ? {} : { 'aria-hidden': true, tabIndex: -1 })}
          >
            {net.dot && <span className="navbar-net-dot" aria-hidden="true"/>}
            <span>{net.label}</span>
          </button>
          <Link href="/launchpad/create" className="navbar-launch">
            <Plus className="w-3.5 h-3.5 stroke-[3]" aria-hidden="true"/>
            <span>Launch</span>
          </Link>
          <button className="navbar-wallet" onClick={handleWalletClick} aria-label={walletLabel} title={wallet.walletName ? `${wallet.walletName} · ${walletLabel}` : walletLabel} data-wallet-status={live ? wallet.status : demo.connected ? 'demo-connected' : 'demo-disconnected'}>
            <Wallet className="w-4 h-4" aria-hidden="true"/>
            <span className="navbar-wallet-label">{walletLabel}</span>
          </button>
          <button className="navbar-icon" onClick={toggleTheme} aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`} title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}>
            {theme === 'dark' ? <Sun className="w-4 h-4"/> : <Moon className="w-4 h-4"/>}
          </button>
        </div>
      </div>
    </header>
  );
}

'use client';

import {
  Home,
  Coins,
  FileText,
  ChevronsLeft,
  ChevronsRight,
  Plus,
  Search,
  Layers,
  Droplets,
  FlaskConical,
  BarChart3,
} from 'lucide-react';
import Link from '@/components/product/safe-link';
import { usePathname } from '@/lib/next-compat';
import { DATA_MODE } from '@/lib/live/env';

interface SidebarProps {
  isCollapsed: boolean;
  onToggleCollapse: () => void;
  onOpenSearch: () => void;
}

// Primary navigation for >=1024px. Wallet, network and theme moved to the top
// navbar; this rail owns navigation and Launch. Research modules (Prediction,
// PRISM) have no live financial data, so they appear here in mock mode only —
// never as live product destinations.
export function Sidebar({ isCollapsed, onToggleCollapse, onOpenSearch }: SidebarProps) {
  const pathname = usePathname();
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
  const shortcuts = [
    { label: 'My positions', icon: Layers, href: '/liquidity?tab=positions' },
    { label: 'Market making', icon: BarChart3, href: '/liquidity/market-making' },
    { label: 'Docs', icon: FileText, href: '/docs' },
  ];
  const research = DATA_MODE === 'live' ? [] : [
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

        {!isCollapsed && <div className="side-group-label" aria-hidden="true">Shortcuts</div>}
        <div className="side-nav side-nav-sub">
          {shortcuts.map((item) => {
            const IconComponent = item.icon;
            return (
              <Link key={item.label} href={item.href} className="side-link side-link-sub" title={isCollapsed ? item.label : undefined}>
                <IconComponent className="w-4.5 h-4.5"/>
                {!isCollapsed && <span>{item.label}</span>}
              </Link>
            );
          })}
        </div>

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
        <p className="side-foot" aria-hidden="true">{DATA_MODE === 'live' ? 'Monad Testnet · 10143' : 'Demo mode'}</p>
      </div>
    </aside>
  );
}

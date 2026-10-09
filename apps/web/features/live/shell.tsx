'use client';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { WalletProvider, useWallet } from '@/lib/live/wallet';
import { release, short } from '@/lib/live/client';
function Frame({ children }: { children: React.ReactNode }) {
  const wallet = useWallet(); const path = usePathname();
  const supported = path === '/launchpad' || path === '/launchpad/create' || path === '/launchpad/demo' || path.startsWith('/launchpad/token/');
  return <><a href="#main" className="skip">Skip to content</a><header className="header"><Link href="/launchpad" className="brand"><Image src="/brand/retropick.png" width={34} height={34} alt=""/><span>RetroPick</span><span className="launchpad-label">LAUNCHPAD</span></Link><nav className="main-nav" aria-label="Primary navigation"><Link href="/launchpad">Markets</Link><Link href="/launchpad/create">Create token</Link><Link href="/launchpad/demo">Demo</Link><Link href={`/launchpad/token/${release.demo.token}`}>Live proof</Link></nav><div className="header-actions"><span className="network">◈ Monad Testnet</span><button className="btn wallet" onClick={wallet.account ? wallet.disconnect : wallet.connect}>{wallet.account ? `${short(wallet.account)} · Disconnect` : 'Connect wallet'}</button></div></header><div className="demo-strip"><span className="demo-pill">TESTNET</span><span>Live onchain markets · MON → Kuru · Test assets only</span></div><main id="main" className="main">{supported ? children : <section className="live-panel"><h1>Launchpad V2 demo</h1><p>This route is outside the live Metropolis demo.</p><Link href="/launchpad">Explore live markets</Link></section>}</main><footer className="footer"><div><span className="footer-brand">RetroPick</span><span>The market creation layer for Monad.</span></div><a href="https://github.com/RetroPick/retropick-protocol">Source & evidence ↗</a></footer></>;
}
export default function LiveShell({ children }: { children: React.ReactNode }) { return <WalletProvider><Frame>{children}</Frame></WalletProvider>; }

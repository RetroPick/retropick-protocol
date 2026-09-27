import Link from '@/components/product/safe-link';
export default function NotFound(){return <div className="error-page"><h1>This page is off the board.</h1><p>The requested route does not exist.</p><Link href="/launchpad" className="btn primary">Explore Launchpad</Link></div>}

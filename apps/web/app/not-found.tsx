import Link from 'next/link';
export default function NotFound(){return <div className="error-page"><h1>This page is off the board.</h1><p>The requested route does not exist.</p><Link href="/markets" className="btn primary">Explore markets</Link></div>}

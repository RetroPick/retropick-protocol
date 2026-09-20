'use client';
export default function ErrorPage({reset}:{reset:()=>void}){return <div className="error-page"><h1>We couldn’t load this view.</h1><p>Your wallet has not been charged. Try loading the page again.</p><button className="btn primary" onClick={reset}>Try again</button></div>}

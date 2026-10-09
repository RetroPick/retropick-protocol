import type { Metadata } from 'next';
import './globals.css';
import {WalletProvider} from '@/lib/live/wallet';
import WebMCP from '@/components/product/webmcp';
import {DemoProvider} from '@/components/product/provider';
import {Shell} from '@/components/product/shell';
import {Toaster} from '@/components/ui/sonner';
import {chooseDataMode} from '@/lib/liquidity/registry';
export const metadata:Metadata={title:'RetroPick | The market creation layer for Monad',description:'Launch through onchain price discovery and graduate into protected Kuru orderbook liquidity on Monad Testnet.',icons:{icon:'/brand/retropick.png'}};
export default function RootLayout({children}:{children:React.ReactNode}){const mode=chooseDataMode(process.env.NEXT_PUBLIC_DATA_MODE);return <html lang="en" className="dark"><body>{mode==='live' ? <WalletProvider><Shell>{children}</Shell></WalletProvider> : <DemoProvider><WebMCP/><Shell>{children}</Shell></DemoProvider>}<Toaster theme="dark"/></body></html>}

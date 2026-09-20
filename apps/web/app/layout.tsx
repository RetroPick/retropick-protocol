import type { Metadata } from 'next';
import './globals.css';
import WebMCP from '@/components/product/webmcp';
import {DemoProvider} from '@/components/product/provider';
import {Shell} from '@/components/product/shell';
import {Toaster} from '@/components/ui/sonner';
import {chooseDataMode} from '@/lib/liquidity/registry';
export const metadata:Metadata={title:'RetroPick | Event markets, real positions',description:'Explore and create collateralized prediction markets and PRISM structured outcome assets on Monad. Interactive frontend demo.',icons:{icon:'/brand/retropick.png'}};
export default function RootLayout({children}:{children:React.ReactNode}){chooseDataMode(process.env.NEXT_PUBLIC_DATA_MODE);return <html lang="en" className="dark"><body><DemoProvider><WebMCP/><Shell>{children}</Shell><Toaster theme="dark"/></DemoProvider></body></html>}

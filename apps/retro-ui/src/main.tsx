import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { DemoProvider } from '@/components/product/provider';
import WebMCP from '@/components/product/webmcp';
import { Shell } from '@/components/shell/shell';
import { Toaster } from '@/components/ui/sonner';
import { Routes } from '@/routes';
import { chooseDataMode } from '@/lib/liquidity/registry';
import { useTheme } from '@/lib/theme';
import { WalletProvider } from '@/wallet/provider';
import './index.css';

// Fail-closed data-mode guard, identical contract to apps/web's root layout:
// 'live' additionally requires an indexer URL; anything else throws instead of
// rendering live-looking data.
const dataMode = chooseDataMode(import.meta.env.VITE_DATA_MODE, import.meta.env.VITE_INDEXER_URL);

// E2E-only session wallet bridge (Gate 5): never active unless explicitly
// configured in a local, gitignored environment file.
if (dataMode === 'live' && import.meta.env.VITE_WALLET_BRIDGE_URL) {
  const { installSessionBridge } = await import('@/wallet/session-bridge');
  installSessionBridge(import.meta.env.VITE_WALLET_BRIDGE_URL as string);
}

// Applying the stored theme happens at theme-module init (before this
// render), so the first paint already matches the user's preference.
function ThemedToaster() {
  const theme = useTheme();
  return <Toaster theme={theme}/>;
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <DemoProvider>
      <WalletProvider>
        <WebMCP/>
        <Shell><Routes/></Shell>
        <ThemedToaster/>
      </WalletProvider>
    </DemoProvider>
  </StrictMode>
);

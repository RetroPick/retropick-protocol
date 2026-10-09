import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { DemoProvider } from '@/components/product/provider';
import WebMCP from '@/components/product/webmcp';
import { Shell } from '@/components/shell/shell';
import { Toaster } from '@/components/ui/sonner';
import { Routes } from '@/routes';
import { chooseDataMode } from '@/lib/liquidity/registry';
import { useTheme } from '@/lib/theme';
import './index.css';

// Fail-closed data-mode guard, identical contract to apps/web's root layout:
// any mode other than mock throws instead of rendering live-looking data.
chooseDataMode(import.meta.env.VITE_DATA_MODE);

// Applying the stored theme happens at theme-module init (before this
// render), so the first paint already matches the user's preference.
function ThemedToaster() {
  const theme = useTheme();
  return <Toaster theme={theme}/>;
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <DemoProvider>
      <WebMCP/>
      <Shell><Routes/></Shell>
      <ThemedToaster/>
    </DemoProvider>
  </StrictMode>
);

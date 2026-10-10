'use client';

import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import type { Address } from 'viem';
import {
  activeChainId,
  requestAccounts,
  createEvmWallet,
  discoverEip6963,
  ensureMonadTestnet,
  injectedProvider,
  type Eip1193Provider,
  type Eip6963Announcement,
  type EvmWallet,
} from '@retropick/launchpad-sdk/wallet';

export type WalletStatus = 'disconnected' | 'connecting' | 'connected' | 'wrong-chain';

export interface WalletState {
  status: WalletStatus;
  account: Address | null;
  chainId: number | null;
  announcements: Eip6963Announcement[];
  provider: Eip1193Provider | null;
  error: string | null;
  connect: (announcement?: Eip6963Announcement) => Promise<void>;
  disconnect: () => void;
  switchChain: () => Promise<void>;
  wallet: EvmWallet | null;
}

const WalletContext = createContext<WalletState | null>(null);

export const MONAD_TESTNET = 10143;

/**
 * Real EIP-1193 wallet for LIVE mode. The demo wallet (DemoProvider) remains
 * the wallet of demo modules and can never authorize a live economic action:
 * this provider is the only path the transaction pipeline will sign through.
 */
export function WalletProvider({ children }: { children: ReactNode }) {
  const [announcements, setAnnouncements] = useState<Eip6963Announcement[]>([]);
  const [provider, setProvider] = useState<Eip1193Provider | null>(null);
  const [account, setAccount] = useState<Address | null>(null);
  const [chainId, setChainId] = useState<number | null>(null);
  const [status, setStatus] = useState<WalletStatus>('disconnected');
  const [error, setError] = useState<string | null>(null);
  const providerRef = useRef<Eip1193Provider | null>(null);

  useEffect(() => {
    void discoverEip6963().then(setAnnouncements);
  }, []);

  const watch = useCallback((connected: Eip1193Provider) => {
    connected.on?.('accountsChanged', ((accounts: string[]) => {
      const next = accounts[0] as Address | undefined;
      if (!next) {
        setAccount(null);
        setStatus('disconnected');
      } else {
        setAccount(next);
      }
    }) as never);
    connected.on?.('chainChanged', ((chain: string) => {
      const id = Number(chain);
      setChainId(id);
      setStatus((prev) => (prev === 'disconnected' ? prev : id === MONAD_TESTNET ? 'connected' : 'wrong-chain'));
    }) as never);
  }, []);

  const connect = useCallback(async (announcement?: Eip6963Announcement) => {
    setStatus('connecting');
    setError(null);
    try {
      const selected = announcement?.provider ?? announcements[0]?.provider ?? injectedProvider();
      if (!selected) throw Error('No wallet found. Install MetaMask or another EIP-1193 wallet.');
      const accounts = await requestAccounts(selected);
      if (!accounts.length) throw Error('Wallet returned no accounts.');
      const id = await ensureMonadTestnet(selected);
      const current = await activeChainId(selected);
      providerRef.current = selected;
      setProvider(selected);
      setAccount(accounts[0]);
      setChainId(current);
      setStatus(current === MONAD_TESTNET ? 'connected' : 'wrong-chain');
      watch(selected);
    } catch (cause) {
      setStatus('disconnected');
      setError(cause instanceof Error ? cause.message : 'Wallet connection failed.');
      throw cause;
    }
  }, [announcements, watch]);

  const disconnect = useCallback(() => {
    providerRef.current = null;
    setProvider(null);
    setAccount(null);
    setChainId(null);
    setStatus('disconnected');
    setError(null);
  }, []);

  const switchChain = useCallback(async () => {
    const selected = providerRef.current;
    if (!selected) return;
    try {
      await ensureMonadTestnet(selected);
      const id = await activeChainId(selected);
      setChainId(id);
      setStatus(id === MONAD_TESTNET ? 'connected' : 'wrong-chain');
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Chain switch failed.');
    }
  }, []);

  const wallet = useMemo(() => (provider && account && chainId === MONAD_TESTNET ? createEvmWallet(provider, account) : null), [provider, account, chainId]);

  const value = useMemo<WalletState>(() => ({
    status, account, chainId, announcements, provider, error, connect, disconnect, switchChain, wallet,
  }), [status, account, chainId, announcements, provider, error, connect, disconnect, switchChain, wallet]);

  return <WalletContext.Provider value={value}>{children}</WalletContext.Provider>;
}

export function useWallet(): WalletState {
  const context = useContext(WalletContext);
  if (!context) throw Error('useWallet requires WalletProvider');
  return context;
}

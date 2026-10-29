// Theme store: external store over localStorage, same pattern as the
// watchlist. Applies data-theme on <html> at module init so the first
// React render already matches the stored preference (no flash).
import { useSyncExternalStore } from 'react';

export type Theme = 'dark' | 'light';
const KEY = 'retropick-theme';

function readStored(): Theme {
  try {
    const value = localStorage.getItem(KEY);
    if (value === 'light' || value === 'dark') return value;
  } catch { /* ignore */ }
  return 'dark';
}

let current: Theme = typeof window === 'undefined' ? 'dark' : readStored();
const listeners = new Set<() => void>();

function apply(): void {
  if (typeof document === 'undefined') return;
  document.documentElement.dataset.theme = current;
}

function notify(): void {
  apply();
  for (const listener of listeners) listener();
}

if (typeof window !== 'undefined') {
  window.addEventListener('storage', (event) => {
    if (event.key !== KEY || (event.newValue !== 'light' && event.newValue !== 'dark')) return;
    current = event.newValue;
    notify();
  });
}
apply();

export function getTheme(): Theme {
  return current;
}

export function setTheme(theme: Theme): void {
  current = theme;
  try { localStorage.setItem(KEY, theme); } catch { /* ignore */ }
  notify();
}

export function toggleTheme(): void {
  setTheme(current === 'dark' ? 'light' : 'dark');
}

export function subscribeTheme(listener: () => void): () => void {
  listeners.add(listener);
  return () => { listeners.delete(listener); };
}

export function useTheme(): Theme {
  return useSyncExternalStore(subscribeTheme, getTheme, () => 'dark');
}

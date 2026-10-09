// Minimal navigation compatibility layer for the ported apps/web feature code.
// apps/web runs on the Next App Router; this SPA reproduces exactly the three
// hooks its features use (usePathname, useSearchParams, useRouter) over the
// History API. Anchor navigation keeps using SafeLink full page loads, so the
// URL stays the single source of truth, matching apps/web behavior.
import { useMemo, useSyncExternalStore } from 'react';

const LOCATION_EVENT = 'retropick:location';

const listeners = new Set<() => void>();
function subscribe(callback: () => void): () => void {
  listeners.add(callback);
  return () => { listeners.delete(callback); };
}
function notify(): void {
  for (const listener of listeners) listener();
}
if (typeof window !== 'undefined') {
  window.addEventListener('popstate', notify);
  window.addEventListener(LOCATION_EVENT, notify);
}

function applyHistory(method: 'pushState' | 'replaceState', url: string): void {
  window.history[method]({}, '', url);
  window.dispatchEvent(new Event(LOCATION_EVENT));
}

export function usePathname(): string {
  return useSyncExternalStore(subscribe, () => window.location.pathname, () => '/');
}

export function useSearchParams(): URLSearchParams {
  const search = useSyncExternalStore(subscribe, () => window.location.search, () => '');
  return useMemo(() => new URLSearchParams(search), [search]);
}

interface CompatibleRouter {
  push(url: string): void;
  replace(url: string, options?: { scroll?: boolean }): void;
}

export function useRouter(): CompatibleRouter {
  return useMemo(() => ({
    push(url: string): void {
      applyHistory('pushState', url);
      window.scrollTo({ top: 0 });
    },
    replace(url: string, options?: { scroll?: boolean }): void {
      applyHistory('replaceState', url);
      if (options?.scroll !== false) window.scrollTo({ top: 0 });
    },
  }), []);
}

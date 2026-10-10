import { useMemo, useSyncExternalStore } from 'react';
import { markStage } from '@/lib/live/performance';

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
  const destination = new URL(url, window.location.href);
  if (destination.origin !== window.location.origin) { window.location.assign(destination.href); return; }
  markStage('route:navigation');
  window.history[method]({}, '', url);
  window.dispatchEvent(new Event(LOCATION_EVENT));
}

export function navigate(url: string, replace = false): void {
  applyHistory(replace ? 'replaceState' : 'pushState', url);
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

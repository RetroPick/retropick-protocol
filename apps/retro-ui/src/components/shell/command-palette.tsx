// Command-palette search (Section 13): ⌘K / Ctrl+K / "/" to open, arrow keys to move, Enter to open.
// LIVE: indexer /v1/search (name, symbol, token address, creator address) — never demo markets.
// DEMO: deterministic fixtures + demo Prediction/PRISM modules, each labelled DEMO.
import { useEffect, useId, useMemo, useRef, useState, type KeyboardEvent } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Search } from 'lucide-react';
import { Dialog, DialogContent, DialogDescription, DialogTitle } from '@/components/ui/dialog';
import { navigate } from '@/lib/next-compat';
import { DATA_MODE, INDEXER_URL } from '@/lib/live/env';
import { fetchSearch } from '@/lib/live/indexer-client';
import { launchKeys, prefetchLaunch } from '@/lib/live/queries';
import { launchInstruments } from '@/lib/domain/launchpad-repository';
import { getInstrumentRoute } from '@/lib/domain/launchpad-adapters';
import { liveRow, searchDemoRows } from '@/lib/view-models/discovery';
import { lifecycleLabel, shortHex } from '@/lib/view-models/token-terminal';
import { DemoBadge, TokenIdentity } from '@/components/trading/primitives';
import '@/features/launchpad/launch-table.css';

interface Option { id: string; href: string; group: string; name: string; symbol: string; icon: { glyph: string; color: string }; logo: string | null; detail: string; demo: boolean }

export function CommandPalette({ open, onOpenChange }: { open: boolean; onOpenChange: (v: boolean) => void }) {
  const [q, setQ] = useState('');
  const [term, setTerm] = useState('');
  const [active, setActive] = useState(0);
  const listId = useId();
  const listRef = useRef<HTMLUListElement>(null);
  useEffect(() => { const t = setTimeout(() => setTerm(q.trim()), DATA_MODE === 'live' ? 250 : 0); return () => clearTimeout(t); }, [q]);
  useEffect(() => { if (!open) { setQ(''); setTerm(''); } }, [open]);
  const live = useQuery({ queryKey: [...launchKeys.all, 'search', term], queryFn: ({ signal }) => fetchSearch(INDEXER_URL!, term, signal), enabled: DATA_MODE === 'live' && !!term, staleTime: 5000 });
  const options = useMemo<Option[]>(() => {
    if (!term) return [];
    if (DATA_MODE === 'live') return (live.data?.data ?? []).map(liveRow).map((r) => ({ id: r.id, href: r.href, group: 'Tokens', name: r.name, symbol: r.symbol, icon: r.icon, logo: r.logo, detail: `${r.symbol}/${r.quote.symbol} · ${lifecycleLabel[r.lifecycle]} · ${shortHex(r.id)}`, demo: false }));
    const tokens: Option[] = searchDemoRows(term).map((r) => ({ id: r.id, href: r.href, group: 'Tokens', name: r.name, symbol: r.symbol, icon: r.icon, logo: null, detail: `${r.symbol}/${r.quote.symbol} · ${lifecycleLabel[r.lifecycle]}`, demo: true }));
    const t = term.toLowerCase();
    const modules: Option[] = launchInstruments.filter((i) => i.kind !== 'token' && `${i.name} ${i.symbol} ${i.creator}`.toLowerCase().includes(t))
      .map((i) => ({ id: i.id, href: getInstrumentRoute(i), group: i.kind === 'prism' ? 'PRISM' : 'Prediction', name: i.name, symbol: i.symbol ?? '', icon: { glyph: i.icon ?? '◇', color: i.color ?? '#b09cfa' }, logo: null, detail: `${i.kind === 'prism' ? 'PRISM basket' : 'Prediction market'} · ${i.symbol}`, demo: true }));
    return [...tokens, ...modules].slice(0, 20);
  }, [term, live.data]);
  useEffect(() => setActive(0), [options.length, term]);
  useEffect(() => { listRef.current?.querySelector<HTMLElement>(`[data-index="${active}"]`)?.scrollIntoView({ block: 'nearest' }); }, [active]);
  const choose = (o: Option | undefined) => { if (!o) return; onOpenChange(false); navigate(o.href); };
  const onKey = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'ArrowDown') { e.preventDefault(); setActive((a) => Math.min(options.length - 1, a + 1)); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setActive((a) => Math.max(0, a - 1)); }
    else if (e.key === 'Enter') { e.preventDefault(); choose(options[active]); }
  };
  useEffect(() => { const o = options[active]; if (o && !o.demo) void prefetchLaunch(o.id); }, [active, options]);
  let groupSeen = '';
  return <Dialog open={open} onOpenChange={onOpenChange}>
    <DialogContent className="product-dialog rp-palette" showCloseButton={false}>
      <DialogTitle className="rp-sr">Search RetroPick</DialogTitle>
      <DialogDescription className="rp-sr">{DATA_MODE === 'live' ? 'Search indexed launches by name, symbol, token or creator address.' : 'Search demo tokens, prediction markets and PRISM baskets.'}</DialogDescription>
      <div className="rp-palette-input"><Search size={17} aria-hidden/>
        <input autoFocus role="combobox" aria-expanded={options.length > 0} aria-controls={listId} aria-activedescendant={options[active] ? `${listId}-${active}` : undefined}
          aria-label="Search Launchpad and PRISM" placeholder={DATA_MODE === 'live' ? 'Name, symbol, token or creator address…' : 'Token, market or symbol…'} value={q} onChange={(e) => setQ(e.target.value)} onKeyDown={onKey}/>
        {DATA_MODE !== 'live' && <DemoBadge/>}
      </div>
      {options.length > 0 && <ul id={listId} role="listbox" aria-label="Search results" className="rp-palette-list" ref={listRef}>
        {options.map((o, i) => {
          const header = o.group !== groupSeen ? (groupSeen = o.group) : null;
          return <li key={`${o.group}:${o.id}`} role="presentation">{header && <div className="rp-palette-group" aria-hidden>{header}</div>}
            <div id={`${listId}-${i}`} role="option" aria-selected={i === active} data-index={i} className="rp-palette-opt" onMouseEnter={() => setActive(i)} onMouseDown={(e) => { e.preventDefault(); choose(o); }}>
              <TokenIdentity name={o.name} symbol={o.symbol} icon={o.icon} logo={o.logo} size="sm"><small>{o.detail}</small></TokenIdentity>{o.demo && <DemoBadge/>}
            </div></li>;
        })}
      </ul>}
      {!term ? <p className="rp-palette-note">{DATA_MODE === 'live' ? 'Search name, symbol, token address or creator address.' : 'Search demo tokens, prediction markets and PRISM.'}</p>
        : DATA_MODE === 'live' && live.isFetching && !options.length ? <p className="rp-palette-note" role="status">Searching indexed launches…</p>
        : DATA_MODE === 'live' && live.error ? <p className="rp-palette-note" role="alert">Search is unavailable. Try again.</p>
        : !options.length ? <p className="rp-palette-note" role="status">No launches match “{term}”.</p> : null}
      {DATA_MODE === 'live' && (live.data?.data.length ?? 0) >= 20 && <p className="rp-palette-note">Showing the first 20 matches. Refine your search for more.</p>}
      <div className="rp-palette-foot" aria-hidden><span>↑↓ move</span><span>↵ open</span><span>esc close</span></div>
    </DialogContent>
  </Dialog>;
}

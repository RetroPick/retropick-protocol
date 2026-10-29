# RetroPick Terminal — Design System

**Scope:** `apps/retro-ui` canonical frontend · **Goal:** `RETROPICK-RETRO-UI-EXAMPLE-INTEGRATION-V1` · **Status:** authoritative for this renovation; supersedes ad-hoc styling conventions, not the data-authority rules in `docs/`.

North star: *the precision of a professional trading desk, the speed of a token launchpad, the clarity of a trustworthy onchain protocol.*

## 1. Color

Color is information, not decoration. Two neutral surfaces carry the workspace;
one brand accent marks action; three semantic hues mark market meaning.

### Tokens (dark, default — "Midnight Terminal")

| Role | Token | Value | Usage rule |
|---|---|---|---|
| Canvas | `--bg` | `#0a0a13` | page background |
| Raised | `--bg-raise` | `#101019` | sidebar, navbar, sticky bars |
| Panel | `--panel` | `#14141f` | cards, tables, ticket |
| Panel-2 | `--panel-2` | `#191926` | nested insets, table headers |
| Inset | `--inset` | `#0d0d16` | wells, code, chart gutters |
| Border | `--border` | `rgba(255,255,255,.08)` | hairlines |
| Border-soft | `--border-soft` | `rgba(255,255,255,.05)` | internal dividers |
| Text | `--text` | `#f1f0f7` | primary |
| Text-2 | `--text-2` | `#c3c1d1` | secondary |
| Text-3 | `--text-3` | `#918da4` | labels, captions |
| Text-dim | `--text-dim` | `#67617f` | placeholders, timestamps |
| **Accent** | `--accent`/`--accent-fill` | `#836ef9` | **scarce**: primary CTA, active nav, focus ring, links. Never for large fills or decoration |
| Positive | `--pos` | `#5feddf` | up deltas, buy side, healthy status (+ `--pos-bg/-border` alpha tints) |
| Negative | `--neg` | `#ff8fa3` | down deltas, sell side, failure (+ tints) |
| Warn | `--warn-text` | `#fbbf24` | stale data, risk, halted (+ tints) |
| Grid | `--grid-line` | `rgba(255,255,255,.05)` | table/chart rules |

Light mode keeps the established off-white/purple-tinted canvas (`--bg #f7f6fd`, accent text `#6a4fd0`, fills stay `#836ef9`, mint `#0a7d73`, coral `#c22747`) — unchanged semantics, mirrored roles.

**Anti-rules:** no gradient flooding, no glass/blur over financial text, no neon button rows, no glow except the single launch CTA's restrained shadow, purple never competes with mint/coral on the same metric. The hero wash (`--grad-a #150f33 → --grad-b #0c0b17`) appears at most once per page.

### Financial-number colors
`--pos`/`--neg` are reserved for signed change and side (buy/sell). A price is
not "positive" — neutral text unless it carries a delta. Zero ≠ unavailable:
unavailable renders `—` in `--text-dim`; zero renders `0`.

## 2. Typography

Plus Jakarta Sans (UI) + JetBrains Mono (numerals, addresses, code) — unchanged.
- Body 14px/1.5; terminal tables 12.5–13px; captions 10.5–11px uppercase tracked.
- All financial numerals: `font-variant-numeric: tabular-nums`, right-aligned
  columns, decimal-aligned pairs, sign always explicit on deltas.
- H1 36px/-1.2px only on marketing-grade heroes (Earn); terminal headers are
  compact 16–19px.

## 3. Space, radius, elevation

- Spacing scale (px): 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40. Terminal density uses
  the lower half; creation/education forms the upper half.
- Radius: `--radius: 0.75rem` base (buttons/cards), 999px pills, 6–9px micro
  controls. One radius family, no mixed squircles.
- Elevation: one soft shadow token (`--shadow-soft`) for overlays; panels sit on
  borders, not shadows. Sticky bars use `--bg-raise` + hairline, not shadow stacks.

## 4. Layout & breakpoints

| Range | Navigation | Content behavior |
|---|---|---|
| ≥1024px | sidebar (260px / collapsed 76px) + top navbar (56px) | terminal grid: chart-dominant 3-col |
| 768–1023px | top navbar with compact primary links (sidebar hidden) | 2-col → stacked panels |
| <768px | top bar (brand/wallet) + bottom nav + safe-area | single column, sticky trade CTA, sheet ticket |

No horizontal page overflow at any breakpoint. Stable row heights — tables must
not jump when values stream in. Gutters 20–24px desktop, 16px tablet, 12–14px mobile.

## 5. Motion

120–200ms ease-out for nav/feedback; 250ms `cubic-bezier(.4,0,.2,1)` for sidebar
width. Transform/opacity only. `prefers-reduced-motion` kills all non-essential
movement. Prices never animate; the only count-up is the Earn claimable hero,
which lands within 400ms and respects reduced-motion.

## 6. Iconography

`lucide-react` only (16/18/20px, 1.75 stroke). One library, consistent weight —
no `react-icons`/radix-icons mixing (donor dependency not adopted).

## 7. Interaction & accessibility

WCAG 2.2 AA floor. Visible focus (2px accent outline, 3px offset) on every
interactive element. Touch targets ≥44px mobile primary actions (≥24px AA
minimum elsewhere). Buy/sell never color-only (BUY/SELL text + icons). Modals
trap focus, `aria-current` on nav, skeleton → empty → error states designed per
surface. Financial CTAs: enabled = source-backed action; disabled = explicit
reason; DEMO interactions are `DemoBadge`-labeled and mock-mode-only.

## 8. Data-honesty rendering (binding for every surface)

- Amounts: `formatRawCompact`/`formatPriceX18` + quote symbol (`MON`, `USDC`…), bigint-exact.
- No `$` anywhere without a verified USD oracle (none exists on testnet).
- Stale indexer → `--warn` freshness chip, never silent; unreachable ≠ empty.
- `toast.success` only after a real receipt; simulated flows never claim success.

## 9. Anti-slop critique (removed in this renovation)

Removed/forbidden: purple-tinted panels fighting accent legibility; decorative
gradients behind tables; sidebar carrying wallet+theme+search (moved to navbar);
inconsistent radii (10/12/16px mixes); em-dash vs 0 confusion; USD-prefixed
fabricated fallbacks (donor); static "connected" pills (donor); mixed icon
libraries (donor). Every metric states its unit next to its value.

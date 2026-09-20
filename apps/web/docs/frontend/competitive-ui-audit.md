# Competitive UI audit
Date: 2026-09-17. Scope: public, disconnected-wallet UI. No financial action performed.

## Evidence and limitations
User screenshots provide historical visual evidence. Live web pages were retrieved; an interactive Chrome session opened each primary reference. This is a bounded audit, not a claim that every route, viewport or animation was tested. Browser API does not expose viewport resizing; responsive competitor behavior is not comprehensively verified. o1 button computed styles measured 150ms cubic-bezier(.4,0,.2,1) for color/background/border transitions. Other exact timings remain NOT_MEASURED.

## o1 — https://launch.o1.exchange/
Observed discovery, launch form and navigation in live DOM. Clicked Launch a token, entered Research preview, and expanded Include Dev Buy; the preview updated and amount/slippage controls appeared. Discovery exposes volume/liquidity sorting and asset selection. Creation separates identity and launch options, has a live preview, wallet-gated submit, and explanatory locked-pool copy. User screenshots additionally show chart, swap ticket, transactions and creator console. Transfer dense discovery, persistent trading rail and live preview. Do not transfer fixed-supply token economics or token vanity mechanics.

## Pons — https://www.ponsfamily.com/launchpad
Live discovery exposes independent sort and age tablists, search, Create, footer and a backend degradation notice. Data initially remained loading. Clicked Create and observed name/ticker/description/socials/paired ETH/developer buy/Advanced plus fee preview. Screenshot evidence also shows a restrained split form/preview. Transfer focused field grouping and explicit fee/transaction boundary. Preserve errors rather than showing fabricated live metrics. Deep token detail is limited by unloaded records.

## Flap — https://flap.sh/create?lang=en
Expanded Links (Optional) and verified social fields. Observed live create form, payment tokens, network control and collapsed creator-purchase, anti-farmer and links groups. Screenshots show a deliberately dense industrial interface. Transfer progressive disclosure and clear section boundaries. Do not import tax, anti-farmer duration or creator tokenomics into prediction creation.

## Prediction-market synthesis
Use event questions, independent YES/NO prices, resolution criteria, settlement status and event exposure as core concepts. These decisions are grounded in RetroPick's canonical specification. Polymarket live browser redirected to its Indonesian discovery page and showed grouped event outcomes and category navigation. Kalshi was retrieved through web research only; no interactive trading flow was tested on either. No financial transactions or wallet connections were performed.

| Pattern | o1 | Pons | Flap | RetroPick decision |
|---|---|---|---|---|
| Discovery | Dense table, sorting | Minimal sort/age controls | Category-heavy table | Searchable event table plus featured cards |
| Creation | Identity + options + preview | Split form and preview | Modular collapsible sections | Six-stage event and ResolutionSpec wizard |
| Trading | Chart + ticket | Simple trade controls in screenshots | Not explored | Independent outcome books; explicit demo review |
| Risk/context | Disclosures | Degradation and wallet boundary | Parameter helpers | Resolution summary before trade; visible fixture mode |
| Motion | 150ms button transitions measured | NOT_MEASURED | NOT_MEASURED | 150ms feedback; respect reduced motion |

## Visual thesis
A precise dark financial workspace with RetroPick blue, restrained violet PRISM accents, teal YES and rose NO. Working discovery opens immediately; typography and charts carry the page. Supplied brand icon is reused, not recreated.

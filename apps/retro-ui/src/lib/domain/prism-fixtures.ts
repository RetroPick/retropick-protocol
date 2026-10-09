/** The same illustrative series used by the existing PRISM detail screen. */
export const prismSeries = [{
  id: 'pfedbtc',
  symbol: 'pFEDBTC',
  title: 'pFEDBTC',
  price: 0.62,
  status: 'ACTIVE' as const,
  quoteAsset: 'USDC',
  collateralAsset: 'USDC',
  components: [{ symbol: 'FED_YES', unitsPerShare: 0.6 }, { symbol: 'BTC_NO', unitsPerShare: 0.4 }],
  provenance: 'DEMO' as const,
}];

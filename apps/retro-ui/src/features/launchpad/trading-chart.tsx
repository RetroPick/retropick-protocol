import { useEffect, useRef, useState } from 'react';
import { createChart, AreaSeries, CandlestickSeries, HistogramSeries, LineType, ColorType, CrosshairMode, LineStyle, createSeriesMarkers, type IChartApi, type ISeriesApi, type Time, type UTCTimestamp, type MouseEventParams } from 'lightweight-charts';
import type { IndexedCandle } from '@retropick/launchpad-sdk/read-model';
import { useTheme } from '@/lib/theme';
import { chartData } from './chart-data';

interface Palette { text: string; grid: string; border: string; up: string; down: string; upVol: string; downVol: string; line: string; areaTop: string; areaBottom: string; cross: string; violet: string }

/** Chart colours come from the active theme's CSS variables (no inverted dark palette in light mode). */
function palette(): Palette {
  const s = getComputedStyle(document.documentElement);
  const v = (name: string, fallback: string) => s.getPropertyValue(name).trim() || fallback;
  const up = v('--chart-up', '#5feddf'), down = v('--chart-down', '#ff6b81');
  return { text: v('--text-3', '#8b84a3'), grid: v('--chart-grid', '#ffffff0a'), border: v('--border-soft', '#1b1732'), up, down, upVol: v('--chart-up-vol', '#5feddf55'), downVol: v('--chart-down-vol', '#ff6b8155'), line: v('--chart-line', up), areaTop: v('--chart-area-top', '#836ef938'), areaBottom: v('--chart-area-bottom', '#836ef900'), cross: v('--text-dim', '#615a78'), violet: v('--violet', '#b09cfa') };
}

export interface TradingChartProps {
  candles: IndexedCandle[];
  quoteDecimals: number;
  quoteSymbol: string;
  mode: 'Line' | 'Candles';
  graduationTimestamp?: number | null;
  /** Shown in the empty overlay; describes the real range (never invents data). */
  emptyText?: string;
}

/**
 * Lightweight Charts terminal chart. Data = authoritative OHLCV buckets only: line uses real bucket closes,
 * candles use real OHLC, volume uses real quote volume. Gaps stay gaps (no interpolation).
 */
export default function TradingChart({ candles, quoteDecimals, quoteSymbol, mode, graduationTimestamp, emptyText }: TradingChartProps) {
  const container = useRef<HTMLDivElement>(null), chart = useRef<IChartApi | null>(null);
  const price = useRef<ISeriesApi<'Area'> | ISeriesApi<'Candlestick'> | null>(null), volume = useRef<ISeriesApi<'Histogram'> | null>(null);
  const markersRef = useRef<ReturnType<typeof createSeriesMarkers<Time>> | null>(null);
  const theme = useTheme();
  const [hover, setHover] = useState<{ time: number; o?: number; h?: number; l?: number; c: number; v?: number } | null>(null);

  useEffect(() => {
    const element = container.current;
    if (!element) return;
    const p = palette();
    const api = createChart(element, {
      autoSize: false, width: element.clientWidth || 640, height: element.clientHeight || 380,
      layout: { background: { type: ColorType.Solid, color: 'transparent' }, textColor: p.text, fontFamily: "'JetBrains Mono', ui-monospace, monospace", fontSize: 11, attributionLogo: true },
      grid: { vertLines: { color: p.grid }, horzLines: { color: p.grid } },
      crosshair: { mode: CrosshairMode.Normal, vertLine: { color: p.cross, style: LineStyle.Dashed, labelBackgroundColor: p.border }, horzLine: { color: p.cross, style: LineStyle.Dashed, labelBackgroundColor: p.border } },
      timeScale: { timeVisible: true, secondsVisible: false, borderColor: p.border },
      rightPriceScale: { borderColor: p.border, scaleMargins: { top: 0.1, bottom: 0.24 } },
      localization: { priceFormatter: (n: number) => formatAxis(n) },
    });
    const priceFormat = { type: 'custom' as const, formatter: formatAxis, minMove: 1e-12 };
    const series = mode === 'Line'
      ? api.addSeries(AreaSeries, { lineColor: p.line, topColor: p.areaTop, bottomColor: p.areaBottom, lineWidth: 2, lineType: LineType.Simple, priceLineVisible: true, priceLineStyle: LineStyle.Dotted, lastValueVisible: true, crosshairMarkerRadius: 4, priceFormat })
      : api.addSeries(CandlestickSeries, { upColor: p.up, downColor: p.down, borderVisible: false, wickUpColor: p.up, wickDownColor: p.down, priceLineVisible: true, priceLineStyle: LineStyle.Dotted, priceFormat });
    const histogram = api.addSeries(HistogramSeries, { priceScaleId: 'volume', priceFormat: { type: 'volume' }, lastValueVisible: false, priceLineVisible: false });
    histogram.priceScale().applyOptions({ scaleMargins: { top: 0.82, bottom: 0 } });
    let active = true;
    const onMove = (param: MouseEventParams<Time>) => {
      if (!active) return;
      const point = param.seriesData.get(series) as { value?: number; open?: number; high?: number; low?: number; close?: number } | undefined;
      const vol = param.seriesData.get(histogram) as { value?: number } | undefined;
      if (!point || param.time === undefined) { setHover(null); return; }
      setHover({ time: Number(param.time), o: point.open, h: point.high, l: point.low, c: point.close ?? point.value ?? 0, v: vol?.value });
    };
    api.subscribeCrosshairMove(onMove);
    const resize = new ResizeObserver((entries) => {
      const entry = entries.at(-1);
      if (!entry) return;
      try { api.applyOptions({ width: Math.max(280, Math.floor(entry.contentRect.width)), height: Math.max(220, Math.floor(entry.contentRect.height)) }); } catch { /* resize after dispose */ }
    });
    resize.observe(element);
    chart.current = api; price.current = series; volume.current = histogram;
    return () => { active = false; api.unsubscribeCrosshairMove(onMove); resize.disconnect(); try { markersRef.current?.detach(); } catch { /* already detached */ } markersRef.current = null; api.remove(); chart.current = null; price.current = null; volume.current = null; };
  }, [mode, theme]);

  useEffect(() => {
    if (!chart.current || !price.current || !volume.current) return;
    const p = palette();
    const data = chartData(candles, quoteDecimals);
    if (mode === 'Line') (price.current as ISeriesApi<'Area'>).setData(data.line);
    else (price.current as ISeriesApi<'Candlestick'>).setData(data.candles);
    volume.current.setData(data.volume.map((row, i) => ({ ...row, color: data.candles[i].close >= data.candles[i].open ? p.upVol : p.downVol })));
    const markerTime = graduationTimestamp ? data.line.find((pt) => Number(pt.time) >= graduationTimestamp)?.time : undefined;
    const list = markerTime ? [{ time: markerTime as UTCTimestamp, position: 'aboveBar' as const, color: p.violet, shape: 'arrowDown' as const, text: 'Graduated to Kuru' }] : [];
    // Markers are owned by the chart instance and detached before chart.remove() (avoids "Object is disposed").
    if (markersRef.current) markersRef.current.setMarkers(list);
    else markersRef.current = createSeriesMarkers(price.current as ISeriesApi<'Area', Time>, list);
    chart.current.timeScale().fitContent();
  }, [candles, quoteDecimals, mode, graduationTimestamp, theme]);

  const legend = hover ? (hover.o !== undefined
    ? `O ${formatAxis(hover.o)}  H ${formatAxis(hover.h ?? 0)}  L ${formatAxis(hover.l ?? 0)}  C ${formatAxis(hover.c)}`
    : `${formatAxis(hover.c)} ${quoteSymbol}`) : null;
  return <div className="rp-chart">
    <div ref={container} className="rp-chart-canvas" role="img" aria-label={`${mode} chart of executed trades in ${quoteSymbol}`} data-chart-mode={mode} data-candle-count={candles.length}/>
    <div className="rp-chart-legend" aria-hidden={!legend}>{legend && <><span>{new Date(hover!.time * 1000).toISOString().slice(0, 16).replace('T', ' ')} UTC</span><span>{legend}</span>{hover!.v !== undefined && <span>Vol {formatAxis(hover!.v)} {quoteSymbol}</span>}</>}</div>
    {!candles.length && <div className="rp-chart-empty" role="status">{emptyText ?? 'No confirmed trades in this range.'}</div>}
    <a href="https://www.tradingview.com/" target="_blank" rel="noreferrer" className="rp-chart-attr">Charts by TradingView</a>
  </div>;
}

/** Axis/tooltip formatting only (display boundary). Signed amounts never use these floats. */
function formatAxis(n: number): string {
  if (!Number.isFinite(n)) return '—';
  const a = Math.abs(n);
  if (a === 0) return '0';
  if (a >= 1000) return n.toLocaleString('en-US', { maximumFractionDigits: 2 });
  if (a >= 1) return n.toFixed(4);
  return n.toPrecision(4);
}

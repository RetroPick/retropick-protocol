import type { IndexedCandle } from '@retropick/launchpad-sdk/read-model';
import type { UTCTimestamp } from 'lightweight-charts';
export function chartData(candles: IndexedCandle[], quoteDecimals: number) {
  const ordered=[...new Map(candles.map(c=>[c.timestamp,c])).values()].sort((a,b)=>a.timestamp-b.timestamp);
  const rows=ordered.map(c=>({time:c.timestamp as UTCTimestamp,open:Number(c.open)/1e18,high:Number(c.high)/1e18,low:Number(c.low)/1e18,close:Number(c.close)/1e18,volume:Number(c.quoteVolumeRaw)/10**quoteDecimals})).filter(c=>Number.isInteger(c.time)&&[c.open,c.high,c.low,c.close,c.volume].every(Number.isFinite)&&c.low<=Math.min(c.open,c.close)&&c.high>=Math.max(c.open,c.close)&&c.volume>=0);
  return {candles:rows.map(({volume,...c})=>c),line:rows.map(c=>({time:c.time,value:c.close})),volume:rows.map(c=>({time:c.time,value:c.volume,color:c.close>=c.open?'#5feddf66':'#ff6b8166'}))};
}

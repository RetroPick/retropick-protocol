import type {IndexedLaunch,IndexedTrade,IndexedCandle} from '@retropick/launchpad-sdk/read-model';
import type {JournalEvent} from './store.ts';
export type LaunchSeed={launch:Omit<IndexedLaunch,'volume24hRaw'|'lifetimeVolumeRaw'|'trades24h'|'holderCount'|'change24hBps'|'candles'>};
const amount=(v:unknown)=>BigInt(String(v??0));
export function project(events:JournalEvent[],seeds:LaunchSeed[],now:number){
 const ordered=[...events].sort((a,b)=>a.block-b.block||a.transactionIndex-b.transactionIndex||a.logIndex-b.logIndex);
 const unique=[...new Map(ordered.map(e=>[e.id,e])).values()];
 const launches=seeds.map(seed=>({...seed.launch,candles:[] as IndexedCandle[],volume24hRaw:'0',lifetimeVolumeRaw:'0',trades24h:0,holderCount:0,change24hBps:null as string|null}));
 const byAddress=new Map<string,typeof launches[number]>();for(const launch of launches)for(const address of [launch.token,launch.curve,launch.market])if(address)byAddress.set(address.toLowerCase(),launch);
 const trades:IndexedTrade[]=[];const balances=new Map<string,Map<string,bigint>>();const activity:JournalEvent[]=[];
 for(const e of unique){const launch=byAddress.get(e.address.toLowerCase());if(!launch)continue;const a=e.args;
  if(e.name==='Transfer'&&e.address.toLowerCase()===launch.token.toLowerCase()){let holders=balances.get(launch.token);if(!holders){holders=new Map();balances.set(launch.token,holders);}for(const [key,sign] of [['from',-1n],['to',1n]] as const){const account=String(a[key]).toLowerCase();if(account==='0x0000000000000000000000000000000000000000')continue;holders.set(account,(holders.get(account)||0n)+sign*amount(a.value));}continue;}
  activity.push(e);
  if(e.name!=='CurveBuy'&&e.name!=='CurveSell'&&e.name!=='Trade')continue;
  const kuru=e.name==='Trade';const buy=kuru?Boolean(a.isBuy):e.name==='CurveBuy';const tokens=kuru?amount(a.filledSize)*10n**10n:amount(buy?a.tokensOut:a.tokensIn);
  const price=kuru?amount(a.price)*10n**BigInt(launch.quoteDecimals)/10n**18n:tokens>0n?amount(buy?a.quoteIn:a.quoteOut)*10n**18n/tokens:0n;
  const quote=kuru?tokens*price/10n**18n:amount(buy?a.quoteIn:a.quoteOut);
  trades.push({id:e.id,token:launch.token,venue:kuru?'KURU':'CURVE',side:buy?'buy':'sell',actor:String(kuru?a.takerAddress:buy?a.buyer:a.seller),...(kuru?{maker:String(a.makerAddress)}:{}),quoteRaw:quote.toString(),tokensRaw:tokens.toString(),priceRaw:price.toString(),feeRaw:kuru?null:(amount(a.fee)+amount(a.tax)).toString(),block:e.block,timestamp:e.timestamp,transactionHash:e.transactionHash,logIndex:e.logIndex});
 }
 for(const launch of launches){const history=trades.filter(t=>t.token===launch.token);launch.lifetimeVolumeRaw=history.reduce((s,t)=>s+amount(t.quoteRaw),0n).toString();const recent=history.filter(t=>t.timestamp>=now-86400);launch.volume24hRaw=recent.reduce((s,t)=>s+amount(t.quoteRaw),0n).toString();launch.trades24h=recent.length;launch.holderCount=[...(balances.get(launch.token)?.values()||[])].filter(v=>v>0n).length;
  const candles=new Map<number,IndexedCandle>();for(const trade of history){const time=Math.floor(trade.timestamp/60)*60;const p=amount(trade.priceRaw);let candle=candles.get(time);if(!candle){candle={timestamp:time,open:p.toString(),high:p.toString(),low:p.toString(),close:p.toString(),quoteVolumeRaw:'0',tradeCount:0};candles.set(time,candle);}candle.high=(p>amount(candle.high)?p:amount(candle.high)).toString();candle.low=(p<amount(candle.low)?p:amount(candle.low)).toString();candle.close=p.toString();candle.quoteVolumeRaw=(amount(candle.quoteVolumeRaw)+amount(trade.quoteRaw)).toString();candle.tradeCount++;}launch.candles=[...candles.values()];const first=recent[0],last=history.at(-1);if(first&&last&&amount(first.priceRaw)>0n)launch.change24hBps=((amount(last.priceRaw)-amount(first.priceRaw))*10000n/amount(first.priceRaw)).toString();
 }
 const holders=Object.fromEntries([...balances].map(([token,map])=>[token,[...map].filter(([,balance])=>balance>0n).map(([address,balance])=>({address,balanceRaw:balance.toString()})).sort((a,b)=>amount(a.balanceRaw)>amount(b.balanceRaw)?-1:1)]));
 return {launches,trades,activity,holders};
}

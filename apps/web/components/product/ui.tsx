'use client';
import type {EventMarket} from '@/lib/domain/types';
import {stateLabel} from '@/lib/domain/fixtures';
import {Tabs,TabsList,TabsTrigger} from '@/components/ui/tabs';
import {SearchX} from 'lucide-react';
export function Segments({values,value,onChange,label}:{values:string[];value:string;onChange:(v:string)=>void;label:string}){return <Tabs value={value} onValueChange={onChange}><TabsList aria-label={label} className="segments">{values.map(v=><TabsTrigger value={v} key={v}>{v}</TabsTrigger>)}</TabsList></Tabs>}
export function TokenIcon({market,small=false}:{market:EventMarket;small?:boolean}){return <span className={`token-icon ${small?'small':''}`} style={{color:market.color,background:market.color+'15'}} aria-hidden="true">{market.icon}</span>}
export function Status({state}:{state:string}){return <span className={'status '+state.toLowerCase()}>{stateLabel(state)}</span>}
export function Empty({title='No markets found',text='Try another search or clear your filters.'}:{title?:string;text?:string}){return <div className="empty"><SearchX size={28}/><h3>{title}</h3><p>{text}</p></div>}
export function Stat({label,value,note}:{label:string;value:string;note?:string}){return <div className="stat"><span>{label}</span><strong>{value}</strong>{note&&<small>{note}</small>}</div>}
export function Spark({seed=1,negative=false,large=false}:{seed?:number;negative?:boolean;large?:boolean}){const points=Array.from({length:32},(_,i)=>`${i*4},${42-i*.8+Math.sin(i*1.7+seed)*6+Math.cos(i*.7+seed)*7}`).join(' ');return <svg className={large?'spark large':'spark'} viewBox="0 0 124 55" preserveAspectRatio="none" aria-label="Illustrative price history" role="img"><polyline points={points} fill="none" stroke={negative?'#ed899c':'#64d8b0'} strokeWidth="1.8" vectorEffect="non-scaling-stroke"/></svg>}

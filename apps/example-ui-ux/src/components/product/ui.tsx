'use client';
import type {EventMarket} from '@/lib/domain/types';
import {stateLabel} from '@/lib/domain/fixtures';
import {Tabs,TabsList,TabsTrigger} from '@/components/ui/tabs';
import {SearchX} from 'lucide-react';
export function Segments({values,value,onChange,label,labels}:{values:string[];value:string;onChange:(v:string)=>void;label:string;labels?:Record<string,string>}){return <Tabs value={value} onValueChange={onChange}><TabsList aria-label={label} className="segments">{values.map(v=><TabsTrigger value={v} key={v}>{labels?.[v]??v}</TabsTrigger>)}</TabsList></Tabs>}
export function TokenIcon({market,small=false}:{market:Pick<EventMarket,'icon'|'color'>;small?:boolean}){return <span className={`token-icon ${small?'small':''}`} style={{color:market.color,background:market.color+'15'}} aria-hidden="true">{market.icon}</span>}
export function Status({state}:{state:string}){return <span className={'status '+state.toLowerCase()}>{stateLabel(state)}</span>}
export function Empty({title='No markets found',text='Try another search or clear your filters.'}:{title?:string;text?:string}){return <div className="empty"><SearchX size={28}/><h3>{title}</h3><p>{text}</p></div>}
export function Stat({label,value,note}:{label:string;value:string;note?:string}){return <div className="stat"><span>{label}</span><strong>{value}</strong>{note&&<small>{note}</small>}</div>}

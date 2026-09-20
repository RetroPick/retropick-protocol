import {PrismDetail} from '@/features/prism/prism';
export default async function Page({params}:{params:Promise<{seriesId:string}>}){const {seriesId}=await params;return <PrismDetail id={seriesId}/>}

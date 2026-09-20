import {Skeleton} from '@/components/ui/skeleton';
export default function Loading(){return <div aria-label="Loading RetroPick"><Skeleton className="h-12 w-2/3 mb-6"/><Skeleton className="h-24 w-full mb-6"/><div className="two-col"><Skeleton className="h-72 w-full"/><Skeleton className="h-72 w-full"/></div></div>}

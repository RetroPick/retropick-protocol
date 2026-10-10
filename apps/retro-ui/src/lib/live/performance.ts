/** Dev measurements contain timings/counters, never bodies or signatures. */
export interface Measurement { stage: string; at: number; duration?: number; bytes?: number; count?: number }
declare global { interface Window { __retroPerformance?: Measurement[] } }
let sequence = 0;
export function markStage(stage: string, fields: Omit<Measurement, 'stage' | 'at'> = {}): void {
  if (typeof performance === 'undefined') return;
  performance.mark(`retropick:${stage}`);
  if (typeof window !== 'undefined') {
    const records = window.__retroPerformance ??= [];
    records.push({ stage, at: performance.now(), ...fields });
    if (records.length > 500) records.splice(0, records.length - 500);
  }
}
export function measureStage(stage: string): (fields?: Omit<Measurement, 'stage' | 'at' | 'duration'>) => void {
  const start = performance.now();
  const id = `retropick:${stage}:${sequence++}`;
  performance.mark(id);
  return (fields = {}) => {
    performance.measure(`retropick:${stage}`, { start: id, end: performance.now() });
    performance.clearMarks(id);
    markStage(stage, { duration: performance.now() - start, ...fields });
  };
}

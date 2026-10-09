'use client';

import { useMemo } from 'react';
import { queryLaunchInstruments, type InstrumentFilters } from '@/lib/domain/launchpad-repository';

export function useLaunchInstruments(filters: InstrumentFilters) {
  const { type, predictionTopic, sort, watchlist } = filters;
  return useMemo(() => queryLaunchInstruments({ type, predictionTopic, sort, watchlist }), [type, predictionTopic, sort, watchlist]);
}

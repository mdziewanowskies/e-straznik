import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/power_reading.dart';
import 'date_range_providers.dart';
import 'supabase_provider.dart';

final power15MinProvider =
    FutureProvider.family<List<Power15MinReading>, String>(
  (ref, meterPointId) async {
    final range = ref.watch(powerDateRangeProvider(meterPointId));
    return ref
        .watch(meterPointsRepositoryProvider)
        .listPower15Min(meterPointId, from: range.from, to: range.to);
  },
);

final exceedancesProvider =
    FutureProvider.family<List<PowerExceedance>, String>((ref, mpId) async {
  return ref.watch(meterPointsRepositoryProvider).listExceedances(mpId);
});

final readingsProvider = FutureProvider.family<List<Reading>, String>(
  (ref, mpId) async {
    final range = ref.watch(readingsDateRangeProvider(mpId));
    return ref.watch(meterPointsRepositoryProvider).listReadings(
          mpId,
          from: range.from,
          to: range.to,
        );
  },
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/power_reading.dart';
import 'supabase_provider.dart';

final power15MinProvider = FutureProvider.family<List<Power15MinReading>, String>(
  (ref, meterPointId) async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 2));
    return ref
        .watch(meterPointsRepositoryProvider)
        .listPower15Min(meterPointId, from: from, to: now);
  },
);

final exceedancesProvider =
    FutureProvider.family<List<PowerExceedance>, String>((ref, mpId) async {
  return ref.watch(meterPointsRepositoryProvider).listExceedances(mpId);
});

final readingsProvider = FutureProvider.family<List<Reading>, String>(
  (ref, mpId) async {
    return ref.watch(meterPointsRepositoryProvider).listReadings(mpId);
  },
);

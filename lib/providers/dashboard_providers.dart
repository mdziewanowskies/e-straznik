import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/meter_point.dart';
import '../data/models/monthly_summary.dart';
import 'supabase_provider.dart';

class DashboardData {
  final List<MeterPoint> meterPoints;
  final Map<String, MonthlySummary> summariesByMpId;
  final TauronAccount? tauronAccount;

  const DashboardData({
    required this.meterPoints,
    required this.summariesByMpId,
    this.tauronAccount,
  });
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final repo = ref.watch(meterPointsRepositoryProvider);
  final meterPoints = await repo.listMeterPoints();
  final ids = meterPoints.map((m) => m.id).toList();
  final summaries = await repo.listMonthlySummaries(ids);
  final account = await repo.fetchTauronAccount();
  return DashboardData(
    meterPoints: meterPoints,
    summariesByMpId: {for (final s in summaries) s.meterPointId: s},
    tauronAccount: account,
  );
});

final meterPointProvider =
    FutureProvider.family<MeterPoint?, String>((ref, id) async {
  return ref.watch(meterPointsRepositoryProvider).fetchMeterPoint(id);
});

final meterPointSummaryProvider =
    FutureProvider.family<MonthlySummary?, String>((ref, id) async {
  return ref.watch(meterPointsRepositoryProvider).fetchSummary(id);
});

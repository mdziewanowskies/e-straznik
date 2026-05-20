import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/alert.dart';
import 'supabase_provider.dart';

class AlertsFilter {
  final String? severity;
  final String? type;
  const AlertsFilter({this.severity, this.type});

  AlertsFilter copyWith({String? severity, String? type, bool clearSeverity = false, bool clearType = false}) {
    return AlertsFilter(
      severity: clearSeverity ? null : (severity ?? this.severity),
      type: clearType ? null : (type ?? this.type),
    );
  }
}

class AlertsFilterController extends StateNotifier<AlertsFilter> {
  AlertsFilterController() : super(const AlertsFilter());

  void setSeverity(String? value) =>
      state = state.copyWith(severity: value, clearSeverity: value == null);
  void setType(String? value) =>
      state = state.copyWith(type: value, clearType: value == null);
  void clear() => state = const AlertsFilter();
}

final alertsFilterProvider =
    StateNotifierProvider<AlertsFilterController, AlertsFilter>((ref) {
  return AlertsFilterController();
});

final alertsProvider = FutureProvider<List<AppAlert>>((ref) async {
  final filter = ref.watch(alertsFilterProvider);
  return ref
      .watch(alertsRepositoryProvider)
      .list(severity: filter.severity, type: filter.type);
});

final alertDetailProvider =
    FutureProvider.family<AppAlert?, String>((ref, id) async {
  return ref.watch(alertsRepositoryProvider).fetch(id);
});

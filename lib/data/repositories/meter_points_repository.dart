import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meter_point.dart';
import '../models/monthly_summary.dart';
import '../models/power_reading.dart';

class MeterPointsRepository {
  MeterPointsRepository(this._client);
  final SupabaseClient _client;

  Future<List<MeterPoint>> listMeterPoints() async {
    final data = await _client
        .from('meter_points')
        .select(
            'id, label, ppe_number, tariff, moc_umowna_kw, tg_phi_limit, monitoring_enabled')
        .order('label');
    return (data as List)
        .map((e) => MeterPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MeterPoint?> fetchMeterPoint(String id) async {
    final data = await _client
        .from('meter_points')
        .select(
            'id, label, ppe_number, tariff, moc_umowna_kw, tg_phi_limit, monitoring_enabled')
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return MeterPoint.fromJson(data);
  }

  static const _summaryColumns =
      'meter_point_id, year, month, consumed_kwh_mtd, reactive_inductive_kvarh_mtd, reactive_capacitive_kvarh_mtd, current_tg_phi, projected_tg_phi_eom, exceedance_count, status';

  Future<List<MonthlySummary>> listMonthlySummaries(
      List<String> meterPointIds) async {
    if (meterPointIds.isEmpty) return const [];
    final data = await _client
        .from('monthly_summary')
        .select(_summaryColumns)
        .inFilter('meter_point_id', meterPointIds)
        .order('year', ascending: false)
        .order('month', ascending: false);
    final rows = (data as List).cast<Map<String, dynamic>>();
    final latestByMp = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final mpId = row['meter_point_id'] as String;
      latestByMp.putIfAbsent(mpId, () => row);
    }
    return latestByMp.values.map(MonthlySummary.fromJson).toList();
  }

  Future<MonthlySummary?> fetchSummary(String meterPointId) async {
    final data = await _client
        .from('monthly_summary')
        .select(_summaryColumns)
        .eq('meter_point_id', meterPointId)
        .order('year', ascending: false)
        .order('month', ascending: false)
        .limit(1)
        .maybeSingle();
    if (data == null) return null;
    return MonthlySummary.fromJson(data);
  }

  Future<TauronAccount?> fetchTauronAccount() async {
    final data = await _client
        .from('tauron_accounts')
        .select('id, last_sync_at, last_sync_status, last_sync_error')
        .order('last_sync_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (data == null) return null;
    return TauronAccount.fromJson(data);
  }

  Future<List<Power15MinReading>> listPower15Min(
    String meterPointId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _client
        .from('power_15min_readings')
        .select('timestamp_15min, power_kw, pum_kw, exceedance_kw')
        .eq('meter_point_id', meterPointId)
        .gte('timestamp_15min', from.toUtc().toIso8601String())
        .lte('timestamp_15min', to.toUtc().toIso8601String())
        .order('timestamp_15min');
    return (data as List)
        .map((e) => Power15MinReading.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PowerExceedance>> listExceedances(String meterPointId,
      {int limit = 50}) async {
    final data = await _client
        .from('power_exceedances')
        .select(
            'id, meter_point_id, timestamp_15min, exceedance_kw, power_kw, pum_kw')
        .eq('meter_point_id', meterPointId)
        .order('timestamp_15min', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => PowerExceedance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Reading>> listReadings(String meterPointId,
      {int limit = 60}) async {
    final data = await _client
        .from('readings')
        .select(
            'id, date_from, date_to, profile, active_consumed_kwh_total, active_consumed_kwh_t1, active_consumed_kwh_t2, active_produced_kwh_total, reactive_inductive_kvarh_total, reactive_capacitive_kvarh_total')
        .eq('meter_point_id', meterPointId)
        .order('date_from', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => Reading.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

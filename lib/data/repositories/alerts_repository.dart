import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alert.dart';

class AlertsRepository {
  AlertsRepository(this._client);
  final SupabaseClient _client;

  Future<List<AppAlert>> list({
    String? severity,
    String? type,
    int limit = 100,
  }) async {
    var q = _client
        .from('alerts')
        .select(
            'id, type, severity, title, message, payload, created_at, acknowledged_at, notified_at, meter_point_id');
    if (severity != null) q = q.eq('severity', severity);
    if (type != null) q = q.eq('type', type);
    final data = await q.order('created_at', ascending: false).limit(limit);
    return (data as List)
        .map((e) => AppAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppAlert?> fetch(String id) async {
    final data = await _client
        .from('alerts')
        .select(
            'id, type, severity, title, message, payload, created_at, acknowledged_at, notified_at, meter_point_id')
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return AppAlert.fromJson(data);
  }

  // Jedyny dozwolony zapis (oprócz device_tokens): oznaczenie alertu jako przeczytany.
  Future<void> markAcknowledged(String id) async {
    await _client
        .from('alerts')
        .update({'acknowledged_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }
}

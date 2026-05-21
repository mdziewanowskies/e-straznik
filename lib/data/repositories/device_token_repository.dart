import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/api_config.dart';

class DeviceRegisterResult {
  final bool ok;
  final int? statusCode;
  final String? body;
  final String? error;
  const DeviceRegisterResult({
    required this.ok,
    this.statusCode,
    this.body,
    this.error,
  });
}

/// Rejestruje/wyrejestrowuje FCM tokeny przez REST API backendu
/// (NIE bezpośrednio do tabeli device_tokens — backend robi to sam
/// po stronie serwera i dodatkowo czyści nieważne tokeny po FCM).
class DeviceTokenRepository {
  DeviceTokenRepository(this._client, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final SupabaseClient _client;
  final http.Client _http;

  static const String _appVersion = '1.0.0';

  Future<DeviceRegisterResult> upsertToken(String token) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      return const DeviceRegisterResult(ok: false, error: 'no_session');
    }
    final platform = Platform.isIOS ? 'ios' : 'android';
    final url =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerDeviceEndpoint}');
    try {
      final res = await _http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'token': token,
          'platform': platform,
          'app_version': _appVersion,
        }),
      );
      debugPrint(
          '[push] POST $url → ${res.statusCode} ${_truncate(res.body)}');
      return DeviceRegisterResult(
        ok: res.statusCode == 200,
        statusCode: res.statusCode,
        body: _truncate(res.body),
      );
    } catch (e) {
      debugPrint('[push] register error: $e');
      return DeviceRegisterResult(ok: false, error: e.toString());
    }
  }

  Future<void> unregisterToken(String token) async {
    final session = _client.auth.currentSession;
    if (session == null) return;
    try {
      await _http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.unregisterDeviceEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (e) {
      debugPrint('[push] unregister error: $e');
    }
  }

  String _truncate(String s) => s.length > 500 ? '${s.substring(0, 500)}…' : s;
}

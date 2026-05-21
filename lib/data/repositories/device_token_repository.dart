import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/api_config.dart';

/// Rejestruje/wyrejestrowuje FCM tokeny przez REST API backendu
/// (NIE bezpośrednio do tabeli device_tokens — backend robi to sam
/// po stronie serwera i dodatkowo czyści nieważne tokeny po FCM).
class DeviceTokenRepository {
  DeviceTokenRepository(this._client, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final SupabaseClient _client;
  final http.Client _http;

  static const String _appVersion = '1.0.0';

  Future<void> upsertToken(String token) async {
    final session = _client.auth.currentSession;
    if (session == null) return;
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      final res = await _http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerDeviceEndpoint}'),
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
      if (res.statusCode != 200) {
        debugPrint(
            '[push] register failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('[push] register error: $e');
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
}

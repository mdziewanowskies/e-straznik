import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceRegisterResult {
  final bool ok;
  final String? error;
  final String? errorCode;
  const DeviceRegisterResult({
    required this.ok,
    this.error,
    this.errorCode,
  });
}

/// Rejestruje/wyrejestrowuje FCM tokeny **bezpośrednio** w tabeli `device_tokens`
/// przez Supabase SDK. RLS dopuszcza insert/update/delete tylko dla
/// `user_id = auth.uid()`, więc nie potrzebujemy osobnego REST API.
///
/// Patrz `docs/mobile_push_integration.md` (instrukcja od backendu).
class DeviceTokenRepository {
  DeviceTokenRepository(this._client);
  final SupabaseClient _client;

  static const String _appVersion = '1.0.0';

  Future<DeviceRegisterResult> upsertToken(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const DeviceRegisterResult(ok: false, errorCode: 'no_session');
    }

    // RLS przy insercie wymaga organization_id = current_org_id(),
    // więc musimy go pobrać z profiles.
    final String orgId;
    try {
      final profile = await _client
          .from('profiles')
          .select('organization_id')
          .eq('id', user.id)
          .maybeSingle();
      if (profile == null) {
        return const DeviceRegisterResult(
            ok: false, errorCode: 'no_profile');
      }
      final value = profile['organization_id'] as String?;
      if (value == null) {
        return const DeviceRegisterResult(
            ok: false, errorCode: 'no_organization');
      }
      orgId = value;
    } catch (e) {
      debugPrint('[push] fetch profile failed: $e');
      return DeviceRegisterResult(
          ok: false, errorCode: 'profile_fetch_failed', error: e.toString());
    }

    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await _client.from('device_tokens').upsert(
        {
          'user_id': user.id,
          'organization_id': orgId,
          'token': token,
          'platform': platform,
          'app_version': _appVersion,
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'token',
      );
      debugPrint('[push] upsert device_tokens OK');
      return const DeviceRegisterResult(ok: true);
    } catch (e) {
      debugPrint('[push] upsert device_tokens failed: $e');
      return DeviceRegisterResult(
          ok: false, errorCode: 'upsert_failed', error: e.toString());
    }
  }

  Future<void> deleteToken(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client
          .from('device_tokens')
          .delete()
          .eq('token', token)
          .eq('user_id', user.id);
      debugPrint('[push] delete device_tokens OK');
    } catch (e) {
      debugPrint('[push] delete device_tokens failed: $e');
    }
  }
}

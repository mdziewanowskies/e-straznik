import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceTokenRepository {
  DeviceTokenRepository(this._client);
  final SupabaseClient _client;

  Future<void> upsertToken(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final platform = Platform.isIOS ? 'ios' : 'android';
    await _client.from('device_tokens').upsert({
      'user_id': user.id,
      'token': token,
      'platform': platform,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'token');
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/alerts_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/device_token_repository.dart';
import '../data/repositories/meter_points_repository.dart';
import '../services/push_notification_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final meterPointsRepositoryProvider = Provider<MeterPointsRepository>((ref) {
  return MeterPointsRepository(ref.watch(supabaseClientProvider));
});

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(ref.watch(supabaseClientProvider));
});

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return DeviceTokenRepository(ref.watch(supabaseClientProvider));
});

/// Singleton trzymający aktywną instancję `PushNotificationService`.
/// Inicjalizowany w `_ESAppState._initPush` po zalogowaniu, ustawiany przez
/// `pushNotificationServiceController` żeby settings_screen mógł wywołać
/// unregister przed signOut.
final pushNotificationServiceProvider =
    StateProvider<PushNotificationService?>((_) => null);

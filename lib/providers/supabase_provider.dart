import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/alerts_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/device_token_repository.dart';
import '../data/repositories/meter_points_repository.dart';

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

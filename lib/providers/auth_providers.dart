import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/profile.dart';
import 'supabase_provider.dart';

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

final sessionProvider = Provider<Session?>((ref) {
  // Re-evaluates on auth changes.
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentSession;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider) != null;
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return null;
  return ref.watch(authRepositoryProvider).fetchProfile();
});

final organizationProvider = FutureProvider<Organization?>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return null;
  return ref.watch(authRepositoryProvider).fetchOrganization(profile.organizationId);
});

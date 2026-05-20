import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../models/profile.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.oauthRedirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<Profile?> fetchProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final data = await _client
        .from('profiles')
        .select('id, organization_id, email, full_name, notification_prefs')
        .eq('id', uid)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<Organization?> fetchOrganization(String organizationId) async {
    final data = await _client
        .from('organizations')
        .select('id, name, subscription_status')
        .eq('id', organizationId)
        .maybeSingle();
    if (data == null) return null;
    return Organization.fromJson(data);
  }
}

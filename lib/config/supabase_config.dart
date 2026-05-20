class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://zstmnabxmvauyefwnsfv.supabase.co';

  // anon (publishable) key — RLS ogranicza dostęp do organization_id usera.
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpzdG1uYWJ4bXZhdXllZnduc2Z2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxMTUzNjQsImV4cCI6MjA5NDY5MTM2NH0.WkBsMXtggXhBrPjyq263wljvMhKyS-J7hfkXLsj7RvA';

  static const String oauthRedirect = 'io.estraznik.app://login-callback';

  static const String alertDeepLinkScheme = 'estraznik';
}

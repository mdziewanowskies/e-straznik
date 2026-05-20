import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_providers.dart';
import '../screens/alerts_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/ppe_details_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier();
  ref.listen<AsyncValue<AuthState>>(
    authStateChangesProvider,
    (_, __) => notifier.notify(),
  );
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final isLoggedIn = session != null;
      final atLogin = state.matchedLocation == '/login';
      final atSplash = state.matchedLocation == '/';

      if (!isLoggedIn) {
        if (atLogin || atSplash) return null;
        return '/login';
      }
      if (atLogin || atSplash) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/ppe/:id',
        builder: (_, state) =>
            PpeDetailsScreen(meterPointId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/alerts', builder: (_, __) => const AlertsScreen()),
      GoRoute(
        path: '/alerts/:id',
        builder: (_, state) =>
            AlertDetailScreen(alertId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});

class _AuthNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

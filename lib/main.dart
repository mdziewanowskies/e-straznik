import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/auth_providers.dart';
import 'providers/supabase_provider.dart';
import 'router/app_router.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not yet initialized (background isolate).
  await Firebase.initializeApp();
}

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Trzymaj natywny splash do czasu zakończenia inicjalizacji.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await initializeDateFormatting('pl_PL');

  // Best-effort Firebase init (the app still runs read-only without push).
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: ESApp()));
  // Zdejmij natywny splash dopiero gdy pierwsza klatka Fluttera jest gotowa.
  FlutterNativeSplash.remove();
}

class ESApp extends ConsumerStatefulWidget {
  const ESApp({super.key});

  @override
  ConsumerState<ESApp> createState() => _ESAppState();
}

class _ESAppState extends ConsumerState<ESApp> {
  PushNotificationService? _push;

  @override
  void initState() {
    super.initState();
    // Initialize push once user is logged in.
    ref.listenManual<bool>(isAuthenticatedProvider, (prev, next) {
      if (next && _push == null) {
        _initPush();
      }
    }, fireImmediately: true);
  }

  Future<void> _initPush() async {
    try {
      _push = PushNotificationService(
        ref.read(deviceTokenRepositoryProvider),
      );
      ref.read(pushNotificationServiceProvider.notifier).state = _push;
      await _push!.initialize();
      _push!.deepLinks.listen((link) {
        final router = ref.read(routerProvider);
        final uri = Uri.tryParse(link);
        if (uri == null) return;
        if (uri.host == 'alerts' && uri.pathSegments.isNotEmpty) {
          router.push('/alerts/${uri.pathSegments.first}');
        }
      });
    } catch (e) {
      debugPrint('Push init failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'e-Strażnik',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Dark theme jest jeszcze niegotowy (AppColors są na sztywno
      // dopasowane do light). Wymuszamy light żeby nie sypał się kontrast
      // na urządzeniach z włączonym trybem ciemnym systemu.
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: const Locale('pl', 'PL'),
      supportedLocales: const [Locale('pl', 'PL')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/repositories/device_token_repository.dart';
import 'push_diagnostics.dart';

class PushNotificationService {
  PushNotificationService(this._tokenRepo, this._diagnostics);

  final DeviceTokenRepository _tokenRepo;
  final PushDiagnosticsNotifier _diagnostics;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<String> _deepLinkController =
      StreamController<String>.broadcast();

  Stream<String> get deepLinks => _deepLinkController.stream;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'estraznik_alerts',
    'Alerty e-Strażnik',
    description: 'Powiadomienia o przekroczeniach, tg φ i innych alertach.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    _diagnostics.update(stage: PushStage.requestingPermission);
    debugPrint('[push] requestPermission()');
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[push] permission: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _diagnostics.update(
        stage: PushStage.permissionDenied,
        message:
            'Brak zgody na push. Włącz w Ustawieniach iOS → e-Strażnik → Powiadomienia.',
      );
      return;
    }
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      _diagnostics.update(
        stage: PushStage.permissionNotDetermined,
        message: 'Nie udało się zapytać o zgodę.',
      );
      return;
    }

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _deepLinkController.add(payload);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _registerToken();

    messaging.onTokenRefresh.listen((token) {
      debugPrint('[push] FCM token refresh');
      _tokenRepo.upsertToken(token);
    });

    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleTap(initial);
    }
  }

  /// Pełna ścieżka rejestracji tokenu — używana też przez "Spróbuj ponownie"
  /// w diagnostyce.
  Future<void> _registerToken() async {
    final messaging = FirebaseMessaging.instance;
    try {
      if (Platform.isIOS) {
        _diagnostics.update(stage: PushStage.waitingApns);
        final apns = await _waitForApnsToken();
        if (apns == null) {
          _diagnostics.update(
            stage: PushStage.apnsTimeout,
            message:
                'APNS token nie przyszedł w 10s. Przyczyny: symulator iOS, '
                'brak Push Notifications capability w Xcode, brak APNs Auth '
                'Key w Firebase Console, albo zła konfiguracja podpisu.',
          );
          debugPrint('[push] APNS token niedostępny');
          return;
        }
        _diagnostics.update(
          stage: PushStage.apnsOk,
          apnsTokenPrefix: apns.substring(0, apns.length.clamp(0, 12)),
        );
        debugPrint('[push] APNS token gotowy (${apns.substring(0, 8)}…)');
      }

      _diagnostics.update(stage: PushStage.fetchingFcm);
      final token = await messaging.getToken();
      if (token == null) {
        _diagnostics.update(
          stage: PushStage.fcmNull,
          message:
              'FCM zwrócił null. Najczęściej: brak APNs Auth Key w Firebase '
              'Console, albo niezgodność Bundle ID Xcode vs Firebase.',
        );
        debugPrint('[push] FCM token null');
        return;
      }
      debugPrint('[push] FCM token: ${token.substring(0, 12)}…');

      _diagnostics.update(
        stage: PushStage.registering,
        fcmTokenPrefix: token.substring(0, token.length.clamp(0, 16)),
      );
      final result = await _tokenRepo.upsertToken(token);
      if (result.ok) {
        _diagnostics.update(
          stage: PushStage.registered,
          message: 'Wpis w tabeli device_tokens utworzony/zaktualizowany.',
        );
      } else {
        _diagnostics.update(
          stage: PushStage.registerFailed,
          message: _explainError(result.errorCode, result.error),
        );
      }
    } catch (e, st) {
      debugPrint('[push] _registerToken error: $e\n$st');
      _diagnostics.update(stage: PushStage.error, message: e.toString());
    }
  }

  String _explainError(String? code, String? raw) {
    switch (code) {
      case 'no_session':
        return 'Brak aktywnej sesji Supabase (zaloguj się ponownie).';
      case 'no_profile':
        return 'Twój wpis w tabeli profiles nie istnieje. Skontaktuj się z administratorem.';
      case 'no_organization':
        return 'Twój profil nie ma przypisanej organizacji (profiles.organization_id = null).';
      case 'profile_fetch_failed':
        return 'Nie udało się pobrać profilu z Supabase: ${raw ?? "(brak szczegółów)"}.';
      case 'upsert_failed':
        return 'Insert do device_tokens odrzucony przez Supabase (najpewniej RLS): ${raw ?? "(brak szczegółów)"}.';
      default:
        return raw ?? 'Nieznany błąd';
    }
  }

  /// Wymuszone uruchomienie pełnej diagnostyki — wywoływane z UI
  /// "Diagnostyka push → Spróbuj ponownie".
  Future<void> runDiagnostics() async {
    _diagnostics.reset();
    await _registerToken();
  }

  void _handleForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final alertId = message.data['alert_id'] as String?;
    final deepLink = alertId != null
        ? 'estraznik://alerts/$alertId'
        : null;
    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: deepLink,
    );
  }

  /// Czeka aż iOS zgłosi APNS token (max ~10s).
  Future<String?> _waitForApnsToken() async {
    final messaging = FirebaseMessaging.instance;
    for (var i = 0; i < 10; i++) {
      final token = await messaging.getAPNSToken();
      if (token != null) return token;
      await Future.delayed(const Duration(seconds: 1));
    }
    return null;
  }

  void _handleTap(RemoteMessage message) {
    final alertId = message.data['alert_id'] as String?;
    if (alertId != null) {
      _deepLinkController.add('estraznik://alerts/$alertId');
    }
  }

  Future<void> unregister() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _tokenRepo.deleteToken(token);
      }
      await FirebaseMessaging.instance.deleteToken();
      _diagnostics.reset();
    } catch (e) {
      debugPrint('[push] unregister flow error: $e');
    }
  }

  void dispose() {
    _deepLinkController.close();
  }
}

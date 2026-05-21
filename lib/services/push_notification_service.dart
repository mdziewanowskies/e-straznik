import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/repositories/device_token_repository.dart';

class PushNotificationService {
  PushNotificationService(this._tokenRepo);

  final DeviceTokenRepository _tokenRepo;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<String> _deepLinkController =
      StreamController<String>.broadcast();

  /// Emits deep-link strings like `estraznik://alerts/<id>` when a notification
  /// is tapped (foreground/background/terminated).
  Stream<String> get deepLinks => _deepLinkController.stream;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'estraznik_alerts',
    'Alerty e-Strażnik',
    description: 'Powiadomienia o przekroczeniach, tg φ i innych alertach.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
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

    // Token registration
    try {
      // iOS: musimy poczekać aż APNS zarejestruje token z Apple — dopiero
      // wtedy FirebaseMessaging.getToken() zwróci FCM token. Bez tego dostajemy
      // "APNS token has not been set yet".
      if (Platform.isIOS) {
        final apns = await _waitForApnsToken();
        if (apns == null) {
          debugPrint(
              '[push] APNS token niedostępny — pomijam rejestrację FCM '
              '(symulator iOS bez APNS, brak entitlement, lub odmowa zgody).');
          return;
        }
        debugPrint('[push] APNS token gotowy (${apns.substring(0, 8)}…)');
      }

      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('[push] FCM token: ${token.substring(0, 12)}…');
        await _tokenRepo.upsertToken(token);
      } else {
        debugPrint('[push] FCM token null — rejestracja pominięta.');
      }
    } catch (e) {
      debugPrint('[push] FCM token error: $e');
    }

    messaging.onTokenRefresh.listen((token) {
      debugPrint('[push] FCM token refresh');
      _tokenRepo.upsertToken(token);
    });

    // Foreground
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Tapped from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Terminated state
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleTap(initial);
    }
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

  /// Czeka aż iOS zgłosi APNS token (max ~10s). Zwraca null jeśli się nie udało
  /// (najczęściej: symulator bez konfiguracji Apple Push, brak APNs Auth Key
  /// w Firebase Console, brak entitlement `aps-environment`, lub odmowa zgody).
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

  /// Wywołać PRZED `auth.signOut()` (póki jeszcze mamy JWT) — backend
  /// czyści wpis w device_tokens, a FCM dostaje nowy token przy następnym
  /// logowaniu.
  Future<void> unregister() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _tokenRepo.unregisterToken(token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('[push] unregister flow error: $e');
    }
  }

  void dispose() {
    _deepLinkController.close();
  }
}

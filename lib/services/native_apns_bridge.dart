import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeApnsState {
  final String event; // 'idle' | 'registered' | 'failed'
  final String value; // token prefix lub błąd
  const NativeApnsState({required this.event, required this.value});
}

class NativeApnsBridge {
  static const _channel = MethodChannel('estraznik/apns');

  /// Czyta z AppDelegate.swift co naprawdę zrobił APNS callback.
  /// Tylko iOS — Android nie używa APNS.
  static Future<NativeApnsState?> getState() async {
    if (!Platform.isIOS) return null;
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getState');
      if (result == null) return null;
      return NativeApnsState(
        event: (result['event'] as String?) ?? 'idle',
        value: (result['value'] as String?) ?? '',
      );
    } catch (e) {
      debugPrint('[apns-bridge] getState error: $e');
      return null;
    }
  }

  /// Wymusza UIApplication.registerForRemoteNotifications() — wołane po
  /// requestPermission, bo Firebase auto-proxy nie zawsze to robi samo.
  static Future<void> registerForRemoteNotifications() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('registerForRemoteNotifications');
    } catch (e) {
      debugPrint('[apns-bridge] registerForRemoteNotifications error: $e');
    }
  }
}

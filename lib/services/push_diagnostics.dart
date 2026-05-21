import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PushStage {
  idle,
  requestingPermission,
  permissionDenied,
  permissionNotDetermined,
  waitingApns,
  apnsTimeout,
  apnsOk,
  fetchingFcm,
  fcmNull,
  registering,
  registerFailed,
  registered,
  error,
}

class PushStatus {
  final PushStage stage;
  final String? message;
  final String? apnsTokenPrefix;
  final String? fcmTokenPrefix;
  final int? lastResponseCode;
  final String? lastResponseBody;
  final DateTime updatedAt;

  const PushStatus({
    required this.stage,
    this.message,
    this.apnsTokenPrefix,
    this.fcmTokenPrefix,
    this.lastResponseCode,
    this.lastResponseBody,
    required this.updatedAt,
  });

  PushStatus copyWith({
    PushStage? stage,
    String? message,
    String? apnsTokenPrefix,
    String? fcmTokenPrefix,
    int? lastResponseCode,
    String? lastResponseBody,
  }) {
    return PushStatus(
      stage: stage ?? this.stage,
      message: message ?? this.message,
      apnsTokenPrefix: apnsTokenPrefix ?? this.apnsTokenPrefix,
      fcmTokenPrefix: fcmTokenPrefix ?? this.fcmTokenPrefix,
      lastResponseCode: lastResponseCode ?? this.lastResponseCode,
      lastResponseBody: lastResponseBody ?? this.lastResponseBody,
      updatedAt: DateTime.now(),
    );
  }

  String get humanStage {
    switch (stage) {
      case PushStage.idle:
        return 'Nie zainicjalizowano';
      case PushStage.requestingPermission:
        return 'Pytam o zgodę…';
      case PushStage.permissionDenied:
        return 'Użytkownik odmówił zgody';
      case PushStage.permissionNotDetermined:
        return 'Zgoda nieokreślona';
      case PushStage.waitingApns:
        return 'Czekam na APNS token…';
      case PushStage.apnsTimeout:
        return 'Timeout APNS (10s)';
      case PushStage.apnsOk:
        return 'APNS OK';
      case PushStage.fetchingFcm:
        return 'Pobieram FCM token…';
      case PushStage.fcmNull:
        return 'FCM token = null';
      case PushStage.registering:
        return 'Rejestruję na backendzie…';
      case PushStage.registerFailed:
        return 'Rejestracja nieudana';
      case PushStage.registered:
        return 'Zarejestrowano ✓';
      case PushStage.error:
        return 'Błąd';
    }
  }
}

class PushDiagnosticsNotifier extends StateNotifier<PushStatus> {
  PushDiagnosticsNotifier()
      : super(PushStatus(stage: PushStage.idle, updatedAt: DateTime.now()));

  void update({
    PushStage? stage,
    String? message,
    String? apnsTokenPrefix,
    String? fcmTokenPrefix,
    int? lastResponseCode,
    String? lastResponseBody,
  }) {
    state = state.copyWith(
      stage: stage,
      message: message,
      apnsTokenPrefix: apnsTokenPrefix,
      fcmTokenPrefix: fcmTokenPrefix,
      lastResponseCode: lastResponseCode,
      lastResponseBody: lastResponseBody,
    );
  }

  void reset() {
    state = PushStatus(stage: PushStage.idle, updatedAt: DateTime.now());
  }
}

final pushDiagnosticsProvider =
    StateNotifierProvider<PushDiagnosticsNotifier, PushStatus>(
        (_) => PushDiagnosticsNotifier());

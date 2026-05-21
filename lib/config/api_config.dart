class ApiConfig {
  ApiConfig._();

  /// Backend e-Strażnik (REST API do rejestracji push tokenów).
  static const String baseUrl = 'https://e-straznik.com';

  static const String registerDeviceEndpoint = '/api/public/devices/register';
  static const String unregisterDeviceEndpoint =
      '/api/public/devices/unregister';
}

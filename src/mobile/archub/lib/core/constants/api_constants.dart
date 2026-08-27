class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.archub.local/api/v1';
  static const String clockInEndpoint = '/clock-in';
  static const String syncEndpoint = '/sync';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);
}

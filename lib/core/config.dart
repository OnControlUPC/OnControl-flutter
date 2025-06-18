// lib/core/config.dart

class Config {
  /// URL base de tu API (sin slash final)
  static const String BASE_URL =
      'https://3ce0-38-187-27-247.ngrok-free.app/api/v1';

  /// Rutas relativas a BASE_URL
  static const String LOGIN_URL = '/authentication/sign-in';
  static const String SIGNUP_URL = '/authentication/sign-up';
}
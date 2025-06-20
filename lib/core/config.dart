// lib/core/config.dart

class Config {
  /// URL base de tu API (sin slash final)
  static const String BASE_URL =
      'https://oncontrolbackend-gtbdhpc9fgd2epdx.westus3-01.azurewebsites.net/api/v1';

  /// Rutas relativas a BASE_URL
  static const String LOGIN_URL = '/authentication/sign-in';
  static const String SIGNUP_URL = '/authentication/sign-up';
  static const String CREATE_PROFILE_URL = '/patients';
}
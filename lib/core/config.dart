// lib/core/config.dart

class Config {
  /// URL base de tu API (sin slash final)
  static const String BASE_URL =
      'https://oncontrolbackend-gtbdhpc9fgd2epdx.westus3-01.azurewebsites.net';

  /// Rutas relativas a BASE_URL
  static const String LOGIN_URL = '/api/v1/authentication/sign-in';
  static const String SIGNUP_URL = '/api/v1/authentication/sign-up';
  static const String CREATE_PROFILE_URL = '/api/v1/patients';
    /// Nueva constante para obtener todos los usuarios
  static const String GET_USERS_URL = '/api/v1/users';

  static const String PATIENT_UUID_URL      = '/api/v1/patients/me/uuid';
  static const String PENDING_LINKS_URL     = '/api/v1/doctor-patient-links/patient';
  static const String ACCEPT_LINK_URL       = '/api/v1/doctor-patient-links';
  static const String ACTIVE_LINKS_URL      = '/api/v1/doctor-patient-links/patient';

  static const String TREATMENTS_URL = '/api/v1/treatments/patient';
  static const String SYMPTOMS_URL = '/api/v1/treatments';

    static const String UPLOAD_PHOTO_URL = '/api/v1/uploads/profile-photo';


}
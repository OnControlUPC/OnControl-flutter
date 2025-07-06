/// lib/features/patients/domain/repositories/patient_repository.dart
import 'dart:io';
import '../entities/patient_profile.dart';

/// Interfaz que define la creación/actualización de un perfil de paciente.
abstract class PatientRepository {
  /// Crea o actualiza el perfil en el backend.
  /// Lanza excepción si la operación falla.
  Future<void> createProfile(
    PatientProfile profile
  );

    /// Sube la foto de perfil y devuelve la URL
  Future<String> uploadProfilePhoto(
    File file,
    String token,
  );
}

/// lib/features/patients/domain/entities/patient_profile.dart

/// Entidad inmutable que representa el perfil de paciente.
class PatientProfile {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String birthDate; // Formato YYYY-MM-DD
  final String gender; // 'MALE' o 'FEMALE'
  final String photoUrl;

  const PatientProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.birthDate,
    required this.gender,
    required this.photoUrl,
  });

  /// Crea una copia modificando solo los campos indicados.
  PatientProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? birthDate,
    String? gender,
    String? photoUrl,
  }) {
    return PatientProfile(
      userId: userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

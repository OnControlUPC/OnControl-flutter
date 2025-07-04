// lib/features/treatments/domain/entities/symptom.dart

/// Enum con los niveles de severidad permitidos.
enum SymptomSeverity { MILD, MODERATE, SEVERE, CRITICAL }

/// Entidad que representa un síntoma reportado por el paciente.
class Symptom {
  final String patientProfileUuid;
  final String symptomType;
  final SymptomSeverity severity;
  final String notes;
  final DateTime loggedAt;

  Symptom({
    required this.patientProfileUuid,
    required this.symptomType,
    required this.severity,
    required this.notes,
    required this.loggedAt,
  });

  /// Convierte la entidad a JSON listo para enviarlo al backend.
  Map<String, dynamic> toJson() => {
        'patientProfileUuid': patientProfileUuid,
        'symptomType': symptomType,
        'severity': severity.name.toUpperCase(),
        'notes': notes,
        'loggedAt': loggedAt.toUtc().toIso8601String(),
      };

  /// Crea una instancia desde el JSON recibido del backend.
  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      patientProfileUuid: json['patientProfileUuid'] as String,
      symptomType: json['symptomType'] as String,
      severity: SymptomSeverity.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['severity'] as String),
      ),
      notes: json['notes'] as String,
      loggedAt: DateTime.parse(json['loggedAt'] as String).toLocal(),
    );
  }
}

import 'symptom.dart';

/// Registro histórico de un síntoma asociado a un tratamiento.
class SymptomLog {
  final String id;
  final DateTime loggedAt;
  final String symptomType;
  final SymptomSeverity severity;
  final String notes;
  final String treatmentId;
  final DateTime createdAt;

  SymptomLog({
    required this.id,
    required this.loggedAt,
    required this.symptomType,
    required this.severity,
    required this.notes,
    required this.treatmentId,
    required this.createdAt,
  });

  factory SymptomLog.fromJson(Map<String, dynamic> json) {
    return SymptomLog(
      id: json['id'].toString(),
      loggedAt: DateTime.parse(json['loggedAt'] as String).toLocal(),
      symptomType: json['symptomType'] as String,
      severity: SymptomSeverity.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['severity'] as String),
      ),
      notes: json['notes'] as String,
      treatmentId: json['treatmentId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}
